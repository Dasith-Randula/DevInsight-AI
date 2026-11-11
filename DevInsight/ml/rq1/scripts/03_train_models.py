#!/usr/bin/env python3
"""Fit the fixed Random Forest and XGBoost models on JEdit train only."""

from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import json
import math
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from xgboost import XGBClassifier


ROOT = Path(__file__).resolve().parents[3]
DEFAULT_CONFIG = ROOT / "ml" / "rq1" / "config" / "training_config.json"
SCRIPT_PATH = Path(__file__).resolve()
REQUIRED_PACKAGES = ("numpy", "pandas", "scikit-learn", "xgboost", "joblib")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _resolve(relative_path: str) -> Path:
    return ROOT / Path(relative_path)


def load_config(path: Path) -> dict[str, Any]:
    config = json.loads(path.read_text(encoding="utf-8"))
    if config["feature_names"] != [
        "CBO",
        "DCC",
        "ExportCoupling",
        "ImportCoupling",
        "NOM",
        "WMC",
    ]:
        raise ValueError("Configured feature order differs from the Step 2 schema.")
    if config["target_name"] != "Defect":
        raise ValueError("Configured target must be Defect.")
    return config


def _verify_environment(config: dict[str, Any]) -> dict[str, str]:
    actual: dict[str, str] = {}
    for package in REQUIRED_PACKAGES:
        try:
            actual[package] = importlib.metadata.version(package)
        except importlib.metadata.PackageNotFoundError as error:
            raise RuntimeError(f"Required package is not installed: {package}") from error
    expected = config["dependency_versions"]
    mismatches = {
        package: (expected.get(package), version)
        for package, version in actual.items()
        if expected.get(package) != version
    }
    if mismatches:
        raise RuntimeError(f"Dependency versions differ from fixed config: {mismatches}")
    return actual


def verify_fixed_inputs(config: dict[str, Any]) -> dict[str, str]:
    inputs = config["inputs"]
    hashes = {
        "train_csv": sha256_file(_resolve(inputs["train_csv"])),
        "validation_csv": sha256_file(_resolve(inputs["validation_csv"])),
        "test_csv": sha256_file(_resolve(inputs["test_csv"])),
        "source_workbook": sha256_file(_resolve(inputs["source_workbook"])),
    }
    expected = {
        "train_csv": inputs["train_sha256"],
        "validation_csv": inputs["validation_sha256"],
        "test_csv": inputs["test_sha256"],
        "source_workbook": inputs["source_workbook_sha256"],
    }
    if hashes != expected:
        raise ValueError(f"Fixed Step 1/2 input hash mismatch: {hashes}")
    split_manifest = json.loads(
        _resolve(inputs["step02_manifest"]).read_text(encoding="utf-8")
    )
    assignments = {
        item["split"]: item["release_sheet"]
        for item in split_manifest["split_assignments"]
    }
    expected_assignments = {
        "train": config["releases"]["training"],
        "validation": config["releases"]["validation"],
        "test": config["releases"]["test"],
    }
    if assignments != expected_assignments:
        raise ValueError(f"Step 2 release assignments changed: {assignments}")
    if any(
        split_manifest["outputs"][split]["sha256"] != hashes[f"{split}_csv"]
        for split in ("train", "validation", "test")
    ):
        raise ValueError("Step 2 manifest and fixed split checksums disagree.")
    return hashes


def load_training_data(config: dict[str, Any]) -> tuple[pd.DataFrame, pd.Series]:
    train_path = _resolve(config["inputs"]["train_csv"])
    if not train_path.is_file():
        raise FileNotFoundError(f"Training CSV not found: {train_path}")
    actual_hash = sha256_file(train_path)
    expected_hash = config["inputs"]["train_sha256"]
    if actual_hash != expected_hash:
        raise ValueError(
            f"Training CSV SHA-256 mismatch: expected {expected_hash}, got {actual_hash}"
        )

    frame = pd.read_csv(train_path)
    expected_columns = [*config["feature_names"], config["target_name"]]
    if frame.columns.tolist() != expected_columns:
        raise ValueError(
            f"Training CSV columns must be exactly {expected_columns}; "
            f"found {frame.columns.tolist()}"
        )
    if len(frame) != 197:
        raise ValueError(f"Expected 197 training rows, found {len(frame)}.")
    if frame[config["target_name"]].isna().any():
        raise ValueError("Training target contains missing values.")
    if set(frame[config["target_name"]].unique()) != {0, 1}:
        raise ValueError("Training target must contain exactly binary labels 0 and 1.")

    features = frame.loc[:, config["feature_names"]].copy()
    if features.isna().any().any():
        raise ValueError("Training features contain missing values.")
    values = features.to_numpy(dtype=np.float64)
    if not np.isfinite(values).all():
        raise ValueError("Training features contain non-finite numeric values.")
    target = frame[config["target_name"]].astype(np.int64)
    if features.columns.tolist() != config["feature_names"]:
        raise ValueError("Target leakage or feature-order mismatch detected.")
    return features, target


def _construct_models(config: dict[str, Any], target: pd.Series) -> dict[str, Any]:
    negative_count = int((target == 0).sum())
    positive_count = int((target == 1).sum())
    if (negative_count, positive_count) != (122, 75):
        raise ValueError(
            "Training class distribution differs from the verified release: "
            f"0={negative_count}, 1={positive_count}"
        )
    computed_weight = negative_count / positive_count
    configured_weight = config["models"]["xgboost"]["hyperparameters"][
        "scale_pos_weight"
    ]
    if not math.isclose(computed_weight, configured_weight, rel_tol=0, abs_tol=1e-15):
        raise ValueError(
            f"Configured XGBoost scale_pos_weight {configured_weight} does not match "
            f"training-only ratio {computed_weight}"
        )

    rf_parameters = config["models"]["random_forest"]["hyperparameters"]
    xgb_parameters = config["models"]["xgboost"]["hyperparameters"]
    return {
        "random_forest": RandomForestClassifier(**rf_parameters),
        "xgboost": XGBClassifier(**xgb_parameters),
    }


def train(config_path: Path) -> dict[str, Any]:
    config = load_config(config_path)
    dependency_versions = _verify_environment(config)
    fixed_input_hashes = verify_fixed_inputs(config)
    features, target = load_training_data(config)
    models = _construct_models(config, target)
    manifest_path = _resolve(config["outputs"]["training_manifest"])
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    model_records: dict[str, dict[str, Any]] = {}
    for model_name, model in models.items():
        model.fit(features, target)
        model_path = _resolve(config["models"][model_name]["output"])
        model_path.parent.mkdir(parents=True, exist_ok=True)
        joblib.dump(model, model_path)
        model_records[model_name] = {
            "model_name": model_name,
            "algorithm": config["models"][model_name]["algorithm"],
            "artifact_path": config["models"][model_name]["output"],
            "artifact_sha256": sha256_file(model_path),
            "training_release": config["releases"]["training"],
            "training_rows": len(features),
            "training_class_counts": {
                "0": int((target == 0).sum()),
                "1": int((target == 1).sum()),
            },
            "feature_order": config["feature_names"],
            "target_name": config["target_name"],
            "target_definition": config["target_definition"],
            "hyperparameters": config["models"][model_name]["hyperparameters"],
            "random_seed": config["random_seed"],
            "class_imbalance": (
                config["class_imbalance"]["random_forest"]
                if model_name == "random_forest"
                else {
                    **config["class_imbalance"]["xgboost"],
                    "computed_from_training_counts": {
                        "negative": int((target == 0).sum()),
                        "positive": int((target == 1).sum()),
                    },
                }
            ),
        }

    manifest = {
        "manifest_version": 1,
        "training_timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "dataset": config["dataset"],
        "dataset_source": config["dataset_source"],
        "prediction_unit": config["prediction_unit"],
        "split_type": config["releases"]["split_type"],
        "training_release": config["releases"]["training"],
        "validation_release": config["releases"]["validation"],
        "test_release": config["releases"]["test"],
        "training_input_path": config["inputs"]["train_csv"],
        "training_input_sha256": fixed_input_hashes["train_csv"],
        "fixed_split_and_source_sha256": fixed_input_hashes,
        "source_workbook_sha256": config["inputs"]["source_workbook_sha256"],
        "feature_order": config["feature_names"],
        "target_name": config["target_name"],
        "target_definition": config["target_definition"],
        "training_rows": len(features),
        "training_class_counts": {
            "0": int((target == 0).sum()),
            "1": int((target == 1).sum()),
        },
        "dependency_versions": dependency_versions,
        "script_path": str(SCRIPT_PATH.relative_to(ROOT)).replace("\\", "/"),
        "script_sha256": sha256_file(SCRIPT_PATH),
        "config_path": str(config_path.resolve().relative_to(ROOT)).replace(
            "\\", "/"
        ),
        "config_sha256": sha256_file(config_path),
        "models": model_records,
        "validation_data_used_for_training_or_selection": False,
        "test_data_used_for_training_or_selection": False,
        "test_performance_metrics_generated": False,
        "held_out_predictions_generated": False,
    }
    manifest_path.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    arguments = parser.parse_args()
    manifest = train(arguments.config)
    print(
        json.dumps(
            {
                "status": "TRAINED",
                "training_release": manifest["training_release"],
                "training_rows": manifest["training_rows"],
                "training_class_counts": manifest["training_class_counts"],
                "feature_order": manifest["feature_order"],
                "dependency_versions": manifest["dependency_versions"],
                "models": manifest["models"],
                "validation_data_used_for_training_or_selection": False,
                "test_data_used_for_training_or_selection": False,
                "test_performance_metrics_generated": False,
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

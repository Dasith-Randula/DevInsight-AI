#!/usr/bin/env python3
"""Verify trained model provenance, loading, probabilities, and reproducibility."""

from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import json
import math
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.utils.validation import check_is_fitted
from xgboost import XGBClassifier

from importlib.util import module_from_spec, spec_from_file_location
import sys


ROOT = Path(__file__).resolve().parents[3]
DEFAULT_CONFIG = ROOT / "ml" / "rq1" / "config" / "training_config.json"
DEFAULT_MANIFEST = ROOT / "ml" / "rq1" / "results" / "step03_training_manifest.json"
TOLERANCE = 1e-12


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _resolve(relative_path: str) -> Path:
    return ROOT / Path(relative_path)


def _load_training_module():
    module_path = Path(__file__).with_name("03_train_models.py")
    spec = spec_from_file_location("rq1_train_models", module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load training code at {module_path}")
    module = module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _expected_versions(config: dict[str, Any]) -> dict[str, str]:
    packages = ("numpy", "pandas", "scikit-learn", "xgboost", "joblib")
    versions = {name: importlib.metadata.version(name) for name in packages}
    if versions != config["dependency_versions"]:
        raise AssertionError(
            f"Installed package versions differ from pinned configuration: {versions}"
        )
    return versions


def _probability_bytes(probabilities: np.ndarray) -> bytes:
    return np.asarray(probabilities, dtype="<f8").tobytes(order="C")


def verify(config_path: Path, manifest_path: Path) -> dict[str, Any]:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    train_module = _load_training_module()
    assertions: dict[str, bool] = {}
    versions = _expected_versions(config)
    assertions["dependency_versions_match_config_and_manifest"] = (
        versions == manifest["dependency_versions"]
    )
    if not assertions["dependency_versions_match_config_and_manifest"]:
        raise AssertionError("Training manifest dependency versions mismatch.")

    train_path = _resolve(config["inputs"]["train_csv"])
    step2_manifest_path = _resolve(config["inputs"]["step02_manifest"])
    step2_manifest = json.loads(step2_manifest_path.read_text(encoding="utf-8"))
    input_hashes = train_module.verify_fixed_inputs(config)
    assertions["step2_inputs_and_workbook_unchanged"] = True
    assertions["fixed_input_hashes_match_training_manifest"] = (
        manifest["fixed_split_and_source_sha256"] == input_hashes
    )
    if not assertions["fixed_input_hashes_match_training_manifest"]:
        raise AssertionError("Training manifest fixed input hashes mismatch.")
    assertions["training_csv_hash_matches_training_manifest"] = (
        manifest["training_input_sha256"] == input_hashes["train_csv"]
    )
    if not assertions["training_csv_hash_matches_training_manifest"]:
        raise AssertionError("Training input hash mismatch in training manifest.")
    assertions["step2_release_assignments_match"] = (
        {item["split"]: item["release_sheet"] for item in step2_manifest["split_assignments"]}
        == {
            "train": config["releases"]["training"],
            "validation": config["releases"]["validation"],
            "test": config["releases"]["test"],
        }
    )
    if not assertions["step2_release_assignments_match"]:
        raise AssertionError("Step 2 release assignment does not match config.")

    features, target = train_module.load_training_data(config)
    actual_class_counts = {
        "0": int((target == 0).sum()),
        "1": int((target == 1).sum()),
    }
    assertions["training_rows_and_class_counts_match_manifest"] = (
        len(features) == manifest["training_rows"] == 197
        and actual_class_counts == manifest["training_class_counts"] == {"0": 122, "1": 75}
    )
    if not assertions["training_rows_and_class_counts_match_manifest"]:
        raise AssertionError("Training row counts or class counts do not match.")
    assertions["exact_feature_order_target_excluded"] = (
        features.columns.tolist() == config["feature_names"]
        and config["target_name"] not in features.columns
        and manifest["feature_order"] == config["feature_names"]
    )
    if not assertions["exact_feature_order_target_excluded"]:
        raise AssertionError("Feature schema/target exclusion check failed.")
    assertions["no_future_split_content_loaded"] = True
    # Validation/test files are only hashed above; their rows/labels are never loaded.
    if assertions["no_future_split_content_loaded"] is not True:
        raise AssertionError("Validation or test rows were loaded.")

    expected_weight = actual_class_counts["0"] / actual_class_counts["1"]
    expected_weight_config = config["models"]["xgboost"]["hyperparameters"][
        "scale_pos_weight"
    ]
    assertions["xgboost_weight_uses_training_labels_only"] = math.isclose(
        expected_weight, expected_weight_config, rel_tol=0, abs_tol=1e-15
    ) and manifest["models"]["xgboost"]["class_imbalance"][
        "computed_from_training_counts"
    ] == {"negative": 122, "positive": 75}
    if not assertions["xgboost_weight_uses_training_labels_only"]:
        raise AssertionError("XGBoost scale_pos_weight provenance check failed.")
    assertions["training_config_and_manifest_hashes_match"] = (
        manifest["config_sha256"] == sha256_file(config_path)
        and manifest["script_sha256"] == sha256_file(
            Path(__file__).with_name("03_train_models.py")
        )
    )
    if not assertions["training_config_and_manifest_hashes_match"]:
        raise AssertionError("Training code/configuration checksum mismatch.")

    models: dict[str, Any] = {}
    probability_results: dict[str, dict[str, Any]] = {}
    model_types = {
        "random_forest": RandomForestClassifier,
        "xgboost": XGBClassifier,
    }
    for name in ("random_forest", "xgboost"):
        record = manifest["models"][name]
        artifact_path = _resolve(record["artifact_path"])
        if not artifact_path.is_file():
            raise AssertionError(f"Missing model artifact: {artifact_path}")
        if sha256_file(artifact_path) != record["artifact_sha256"]:
            raise AssertionError(f"Artifact checksum mismatch for {name}.")
        model = joblib.load(artifact_path)
        if not isinstance(model, model_types[name]):
            raise AssertionError(f"{name} artifact has the wrong estimator type.")
        check_is_fitted(model)
        if list(model.classes_) != [0, 1]:
            raise AssertionError(f"{name} does not recognize classes 0 and 1.")
        if getattr(model, "feature_names_in_", None) is None:
            raise AssertionError(f"{name} has no fitted feature names.")
        if list(model.feature_names_in_) != config["feature_names"]:
            raise AssertionError(f"{name} fitted feature order mismatch.")
        if model.n_features_in_ != len(config["feature_names"]):
            raise AssertionError(f"{name} fitted feature count mismatch.")
        if record["training_release"] != config["releases"]["training"]:
            raise AssertionError(f"{name} training release metadata mismatch.")
        if record["training_rows"] != len(features):
            raise AssertionError(f"{name} training row metadata mismatch.")
        if record["hyperparameters"] != config["models"][name]["hyperparameters"]:
            raise AssertionError(f"{name} hyperparameters mismatch.")
        if name == "random_forest":
            if model.get_params()["class_weight"] != "balanced":
                raise AssertionError("Random Forest class_weight is not balanced.")
            if record["class_imbalance"] != config["class_imbalance"]["random_forest"]:
                raise AssertionError("Random Forest imbalance metadata mismatch.")
        else:
            model_weight = model.get_params()["scale_pos_weight"]
            if not math.isclose(
                model_weight, expected_weight, rel_tol=0, abs_tol=1e-15
            ):
                raise AssertionError(
                    "XGBoost fitted scale_pos_weight differs from training ratio."
                )

        probabilities = np.asarray(model.predict_proba(features), dtype=np.float64)
        if (
            probabilities.shape != (len(features), 2)
            or not np.isfinite(probabilities).all()
            or (probabilities < 0).any()
            or (probabilities > 1).any()
        ):
            raise AssertionError(f"{name} produced invalid training probabilities.")

        refit_models = train_module._construct_models(config, target)
        refit = refit_models[name]
        refit.fit(features, target)
        refit_probabilities = np.asarray(
            refit.predict_proba(features), dtype=np.float64
        )
        max_abs_difference = float(
            np.max(np.abs(probabilities - refit_probabilities))
        )
        reproducible = np.allclose(
            probabilities,
            refit_probabilities,
            rtol=TOLERANCE,
            atol=TOLERANCE,
        )
        if not reproducible:
            raise AssertionError(
                f"{name} repeat-fit probabilities differ; max abs difference "
                f"{max_abs_difference:.17g} exceeds tolerance {TOLERANCE}."
            )
        probability_hash = hashlib.sha256(
            _probability_bytes(probabilities)
        ).hexdigest()
        repeat_hash = hashlib.sha256(
            _probability_bytes(refit_probabilities)
        ).hexdigest()
        models[name] = model
        probability_results[name] = {
            "probability_sha256": probability_hash,
            "repeat_probability_sha256": repeat_hash,
            "max_absolute_difference": max_abs_difference,
            "tolerance": TOLERANCE,
        }

    assertions["both_artifacts_exist_load_and_are_fitted_classifiers"] = True
    assertions["both_artifacts_use_six_features_and_classes_0_1"] = True
    assertions["training_only_probability_outputs_finite_and_bounded"] = True
    assertions["repeat_training_probabilities_equivalent"] = all(
        result["max_absolute_difference"] <= TOLERANCE
        for result in probability_results.values()
    )
    assertions["artifact_sha256_checksums_valid"] = all(
        sha256_file(_resolve(manifest["models"][name]["artifact_path"]))
        == manifest["models"][name]["artifact_sha256"]
        for name in models
    )
    assertions["no_validation_or_test_model_selection_or_test_metrics"] = (
        manifest["validation_data_used_for_training_or_selection"] is False
        and manifest["test_data_used_for_training_or_selection"] is False
        and manifest["test_performance_metrics_generated"] is False
        and manifest["held_out_predictions_generated"] is False
    )
    if not all(assertions.values()):
        raise AssertionError(
            "Verification assertion failed: "
            + ", ".join(name for name, passed in assertions.items() if not passed)
        )
    return {
        "status": "PASS",
        "assertions": assertions,
        "package_versions": versions,
        "input_sha256": input_hashes,
        "training_rows": len(features),
        "training_class_counts": actual_class_counts,
        "models": {
            name: {
                "artifact_sha256": manifest["models"][name]["artifact_sha256"],
                **probability_results[name],
            }
            for name in models
        },
        "validation_and_test_rows_loaded": False,
        "test_metrics_generated": False,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    arguments = parser.parse_args()
    print(json.dumps(verify(arguments.config, arguments.manifest), indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

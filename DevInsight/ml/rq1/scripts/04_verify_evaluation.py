#!/usr/bin/env python3
"""Independently verify Step 4 metrics, provenance, and repeatability."""

from __future__ import annotations

import argparse
import ast
import csv
import hashlib
import importlib.util
import json
import math
import subprocess
import sys
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
import joblib
from sklearn.metrics import (
    accuracy_score,
    auc,
    average_precision_score,
    balanced_accuracy_score,
    confusion_matrix,
    f1_score,
    precision_recall_curve,
    precision_score,
    recall_score,
    roc_auc_score,
)


ROOT = Path(__file__).resolve().parents[3]
DEFAULT_CONFIG = ROOT / "ml" / "rq1" / "config" / "evaluation_config.json"
DEFAULT_RESULTS = ROOT / "ml" / "rq1" / "results" / "step04_evaluation_metrics.json"
TOLERANCE = 1e-12
MODEL_NAMES = ("random_forest", "xgboost", "majority_class_baseline")
COHORTS = ("validation", "test", "test_novel_feature_vectors_diagnostic")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def resolve(relative_path: str) -> Path:
    return ROOT / Path(relative_path)


def load_evaluator():
    path = Path(__file__).with_name("04_evaluate_models.py")
    spec = importlib.util.spec_from_file_location("rq1_evaluation", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to load evaluation module from {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def wilson(successes: int, total: int) -> list[float] | None:
    if not total:
        return None
    z = 1.959963984540054
    p = successes / total
    denominator = 1 + z * z / total
    center = (p + z * z / (2 * total)) / denominator
    margin = z * math.sqrt(p * (1 - p) / total + z * z / (4 * total**2)) / denominator
    return [max(0.0, center - margin), min(1.0, center + margin)]


def independently_calculate(
    y_true: np.ndarray, probabilities: np.ndarray, threshold: float, zero_division: int
) -> dict[str, Any]:
    predicted = (probabilities >= threshold).astype(np.int64)
    tn, fp, fn, tp = (
        int(value)
        for value in confusion_matrix(y_true, predicted, labels=[0, 1]).ravel()
    )
    if len(np.unique(y_true)) == 2:
        precision_curve, recall_curve, _ = precision_recall_curve(
            y_true, probabilities, pos_label=1
        )
        roc_auc: float | None = float(roc_auc_score(y_true, probabilities))
        ap: float | None = float(
            average_precision_score(y_true, probabilities, pos_label=1)
        )
        trapezoidal: float | None = float(auc(recall_curve, precision_curve))
    else:
        roc_auc = ap = trapezoidal = None
    return {
        "sample_count": len(y_true),
        "class_counts": {
            "0": int(np.sum(y_true == 0)),
            "1": int(np.sum(y_true == 1)),
        },
        "class_proportions": {
            "0": float(np.mean(y_true == 0)),
            "1": float(np.mean(y_true == 1)),
        },
        "threshold": threshold,
        "zero_division_policy": zero_division,
        "confusion_matrix_order": [["TN", "FP"], ["FN", "TP"]],
        "confusion_matrix": [[tn, fp], [fn, tp]],
        "true_negatives": tn,
        "false_positives": fp,
        "false_negatives": fn,
        "true_positives": tp,
        "predicted_positive_count": int(np.sum(predicted == 1)),
        "accuracy": float(accuracy_score(y_true, predicted)),
        "precision_positive": float(
            precision_score(
                y_true, predicted, pos_label=1, zero_division=zero_division
            )
        ),
        "recall_positive": float(
            recall_score(y_true, predicted, pos_label=1, zero_division=zero_division)
        ),
        "f1_positive": float(
            f1_score(y_true, predicted, pos_label=1, zero_division=zero_division)
        ),
        "specificity": tn / (tn + fp) if tn + fp else None,
        "balanced_accuracy": float(balanced_accuracy_score(y_true, predicted)),
        "roc_auc": roc_auc,
        "average_precision": ap,
        "trapezoidal_pr_auc": trapezoidal,
        "positive_recall_wilson_95_percent_interval": wilson(tp, tp + fn),
    }


def _assert_nested_close(actual: Any, expected: Any, path: str = "metric") -> None:
    if isinstance(expected, dict):
        if not isinstance(actual, dict) or set(actual) != set(expected):
            raise AssertionError(f"{path}: JSON object keys differ.")
        for key in expected:
            _assert_nested_close(actual[key], expected[key], f"{path}.{key}")
    elif isinstance(expected, list):
        if not isinstance(actual, list) or len(actual) != len(expected):
            raise AssertionError(f"{path}: array length differs.")
        for index, (left, right) in enumerate(zip(actual, expected, strict=True)):
            _assert_nested_close(left, right, f"{path}[{index}]")
    elif isinstance(expected, (int, float)) and not isinstance(expected, bool):
        if not isinstance(actual, (int, float)) or not math.isclose(
            float(actual), float(expected), rel_tol=TOLERANCE, abs_tol=TOLERANCE
        ):
            raise AssertionError(f"{path}: {actual!r} != {expected!r}")
    elif actual != expected:
        raise AssertionError(f"{path}: {actual!r} != {expected!r}")


def verify(config_path: Path, results_path: Path) -> dict[str, Any]:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    results = json.loads(results_path.read_text(encoding="utf-8"))
    evaluator = load_evaluator()
    assertions: dict[str, bool] = {}

    input_hashes = results["input_sha256"]
    for split in ("training", "validation", "test"):
        config_key = f"{split}_csv"
        result_key = "train_csv" if split == "training" else config_key
        path = resolve(config["inputs"][config_key]["path"])
        observed = sha256_file(path)
        if (
            observed != config["inputs"][config_key]["sha256"]
            or observed != input_hashes[result_key]
        ):
            raise AssertionError(f"{config_key} checksum mismatch.")
    workbook_cfg = config["inputs"]["source_workbook"]
    workbook_hash = sha256_file(resolve(workbook_cfg["path"]))
    if workbook_hash != workbook_cfg["sha256"] or workbook_hash != input_hashes["source_workbook"]:
        raise AssertionError("Raw workbook checksum mismatch.")
    training_manifest = json.loads(
        resolve(config["inputs"]["training_manifest"]).read_text(encoding="utf-8")
    )
    model_hashes: dict[str, str] = {}
    loaded_models: dict[str, Any] = {}
    for model_name, model_cfg in config["inputs"]["model_artifacts"].items():
        model_hash = sha256_file(resolve(model_cfg["path"]))
        if (
            model_hash != model_cfg["sha256"]
            or model_hash != training_manifest["models"][model_name]["artifact_sha256"]
            or model_hash != results["model_sha256"][model_name]
        ):
            raise AssertionError(f"{model_name} checksum differs from provenance.")
        model_hashes[model_name] = model_hash
        model = joblib.load(resolve(model_cfg["path"]))
        if list(model.classes_) != [0, 1]:
            raise AssertionError(f"{model_name} class order is not [0, 1].")
        if list(model.feature_names_in_) != config["feature_names"]:
            raise AssertionError(f"{model_name} fitted feature order mismatch.")
        loaded_models[model_name] = model
    assertions["model_checksums_match_training_manifest"] = True
    assertions["models_load_with_expected_class_and_feature_order"] = True
    assertions["dataset_and_training_input_hashes_unchanged"] = True

    split_manifest = json.loads(
        resolve(config["inputs"]["split_manifest"]).read_text(encoding="utf-8")
    )
    assignments = {
        entry["split"]: entry["release_sheet"]
        for entry in split_manifest["split_assignments"]
    }
    expected_assignments = {
        "train": config["releases"]["training"],
        "validation": config["releases"]["validation"],
        "test": config["releases"]["test"],
    }
    if assignments != expected_assignments:
        raise AssertionError("Validation/test release assignments changed.")
    assertions["validation_and_test_releases_correctly_assigned"] = True

    if (
        config["primary_threshold"] != 0.5
        or results["protocol"]["primary_threshold"] != 0.5
        or results["protocol"]["config_sha256"] != sha256_file(config_path)
        or results["protocol"]["frozen_before_evaluation"] is not True
    ):
        raise AssertionError("Frozen 0.50 threshold/protocol verification failed.")
    assertions["threshold_frozen_at_0_50"] = True
    if results["feature_names"] != config["feature_names"] or len(config["feature_names"]) != 6:
        raise AssertionError("Evaluation feature list is not the approved six.")
    assertions["exactly_six_approved_features_used"] = True
    evaluation_source = Path(__file__).with_name("04_evaluate_models.py")
    tree = ast.parse(evaluation_source.read_text(encoding="utf-8"))
    fitting_calls = [
        node
        for node in ast.walk(tree)
        if isinstance(node, ast.Call)
        and isinstance(node.func, ast.Attribute)
        and node.func.attr in {"fit", "fit_transform", "partial_fit"}
    ]
    if fitting_calls or results["models_refitted"] is not False:
        raise AssertionError("Evaluation contains a model fit/refit call.")
    assertions["no_model_refitted"] = True

    frame_by_cohort = {
        "validation": pd.read_csv(resolve(config["inputs"]["validation_csv"]["path"])),
        "test": pd.read_csv(resolve(config["inputs"]["test_csv"]["path"])),
    }
    train_frame = pd.read_csv(resolve(config["inputs"]["training_csv"]["path"]))
    train_vectors = set(evaluator._feature_keys(train_frame, config["feature_names"]))
    validation_vectors = set(
        evaluator._feature_keys(frame_by_cohort["validation"], config["feature_names"])
    )
    prior_vectors = train_vectors | validation_vectors
    test_frame = frame_by_cohort["test"]
    novel_mask = np.array(
        [
            vector not in prior_vectors
            for vector in evaluator._feature_keys(test_frame, config["feature_names"])
        ],
        dtype=bool,
    )
    diagnostic_frame = test_frame.loc[novel_mask].reset_index(drop=True)
    diagnostic_counts = diagnostic_frame["Defect"].value_counts().to_dict()
    expected_diag = config["expected_sample_counts"]["test_novel_feature_vectors_diagnostic"]
    if (
        len(diagnostic_frame) != expected_diag["rows"]
        or {
            "0": int(diagnostic_counts.get(0, 0)),
            "1": int(diagnostic_counts.get(1, 0)),
        }
        != expected_diag["class_counts"]
        or split_manifest["diagnostic_test_subset"]["rows"] != len(diagnostic_frame)
        or split_manifest["diagnostic_test_subset"]["class_counts"]
        != expected_diag["class_counts"]
    ):
        raise AssertionError("Diagnostic novel-vector subset differs from frozen definition.")
    assertions["diagnostic_subset_definition_and_counts_correct"] = True

    predictions_path = resolve(config["outputs"]["predictions_csv"])
    with predictions_path.open("r", encoding="utf-8", newline="") as source:
        reader = csv.DictReader(source)
        prediction_rows = list(reader)
        prediction_columns = reader.fieldnames
    expected_prediction_columns = [
        "cohort",
        "release",
        "split_row_index",
        "model",
        "actual_defect",
        "positive_probability",
        "predicted_defect",
        "threshold",
    ]
    if prediction_columns != expected_prediction_columns:
        raise AssertionError("Prediction CSV schema mismatch.")
    if sha256_file(predictions_path) != results["prediction_rows_csv"]["sha256"]:
        raise AssertionError("Prediction CSV hash mismatch.")
    assertions["evaluation_json_and_prediction_csv_parse"] = True

    frames_for_cohorts = {
        "validation": frame_by_cohort["validation"],
        "test": test_frame,
        "test_novel_feature_vectors_diagnostic": diagnostic_frame,
    }
    cohort_by_name = {cohort["cohort"]: cohort for cohort in results["cohorts"]}
    if set(cohort_by_name) != set(COHORTS):
        raise AssertionError("Missing or unexpected evaluation cohorts.")
    flattened_metrics: dict[str, Any] = {}
    for cohort_name in COHORTS:
        frame = frames_for_cohorts[cohort_name]
        expected_indices = (
            (np.flatnonzero(novel_mask) + 1).tolist()
            if cohort_name == "test_novel_feature_vectors_diagnostic"
            else list(range(1, len(frame) + 1))
        )
        cohort_result = cohort_by_name[cohort_name]
        if (
            cohort_result["sample_count"] != len(frame)
            or cohort_result["release"] != (
                config["releases"]["diagnostic"]
                if cohort_name == "test_novel_feature_vectors_diagnostic"
                else config["releases"][cohort_name]
            )
        ):
            raise AssertionError(f"{cohort_name} row count/release metadata mismatch.")
        flattened_metrics[cohort_name] = {}
        true_lookup = dict(
            zip(expected_indices, frame["Defect"].astype(int).tolist(), strict=True)
        )
        for model_name in MODEL_NAMES:
            rows = [
                row
                for row in prediction_rows
                if row["cohort"] == cohort_name and row["model"] == model_name
            ]
            row_indices = [int(row["split_row_index"]) for row in rows]
            if len(rows) != len(frame) or row_indices != expected_indices:
                raise AssertionError(
                    f"{cohort_name}/{model_name} does not have one ordered prediction per row."
                )
            y_true = np.array([int(row["actual_defect"]) for row in rows])
            probabilities = np.array(
                [float(row["positive_probability"]) for row in rows], dtype=float
            )
            predicted = np.array(
                [int(row["predicted_defect"]) for row in rows], dtype=np.int64
            )
            if any(y != true_lookup[index] for index, y in zip(row_indices, y_true, strict=True)):
                raise AssertionError(f"{cohort_name}/{model_name} actual labels mismatch.")
            if (
                not np.isfinite(probabilities).all()
                or (probabilities < 0).any()
                or (probabilities > 1).any()
            ):
                raise AssertionError(f"{cohort_name}/{model_name} invalid scores.")
            if not np.array_equal(
                predicted, (probabilities >= config["primary_threshold"]).astype(int)
            ):
                raise AssertionError(f"{cohort_name}/{model_name} threshold mismatch.")
            if any(float(row["threshold"]) != 0.5 for row in rows):
                raise AssertionError(f"{cohort_name}/{model_name} row threshold changed.")
            if model_name == "majority_class_baseline" and (
                np.any(predicted != 0) or np.any(probabilities != 0)
            ):
                raise AssertionError("Baseline is not deterministic all-negative.")

            expected_metrics = independently_calculate(
                y_true,
                probabilities,
                config["primary_threshold"],
                config["metric_policy"]["zero_division"],
            )
            saved_metrics = cohort_result["metrics_by_model"][model_name]
            _assert_nested_close(saved_metrics, expected_metrics, cohort_name + "." + model_name)
            if sum(sum(line) for line in saved_metrics["confusion_matrix"]) != len(frame):
                raise AssertionError("Confusion matrix does not sum to sample count.")
            flattened_metrics[cohort_name][model_name] = expected_metrics
    expected_rows = sum(len(frame) for frame in frames_for_cohorts.values()) * len(MODEL_NAMES)
    if len(prediction_rows) != expected_rows:
        raise AssertionError("Prediction CSV contains unexpected or missing rows.")
    assertions["one_prediction_per_sample_model_and_cohort"] = True
    assertions["probability_outputs_finite_and_between_zero_and_one"] = True
    assertions["confusion_matrices_sum_to_samples"] = True
    assertions["accuracy_precision_recall_f1_recomputed"] = True
    assertions["balanced_accuracy_specificity_recomputed"] = True
    assertions["positive_class_is_defect_one"] = (
        results["protocol"]["positive_class"] == 1
        and results["protocol"]["confusion_matrix_order"] == [["TN", "FP"], ["FN", "TP"]]
    )
    assertions["majority_baseline_predicts_zero_for_every_row"] = True
    assertions["full_test_has_470_rows_and_11_positives"] = (
        len(test_frame) == 470 and int((test_frame["Defect"] == 1).sum()) == 11
    )
    assertions["diagnostic_subset_verified"] = True
    comparison_path = resolve(config["outputs"]["comparison_csv"])
    with comparison_path.open("r", encoding="utf-8", newline="") as source:
        comparison_rows = list(csv.DictReader(source))
    if len(comparison_rows) != len(COHORTS) * len(MODEL_NAMES):
        raise AssertionError("Comparison CSV is missing metric rows.")
    if {
        (row["cohort"], row["model"]) for row in comparison_rows
    } != {
        (cohort_name, model_name)
        for cohort_name in COHORTS
        for model_name in MODEL_NAMES
    }:
        raise AssertionError("Comparison CSV cohort/model coverage is incorrect.")
    for row in comparison_rows:
        metrics = cohort_by_name[row["cohort"]]["metrics_by_model"][row["model"]]
        comparable_fields = {
            "sample_count": "sample_count",
            "positive_count": "class_counts.1",
            "predicted_positive_count": "predicted_positive_count",
            "accuracy": "accuracy",
            "precision_positive": "precision_positive",
            "recall_positive": "recall_positive",
            "f1_positive": "f1_positive",
            "specificity": "specificity",
            "balanced_accuracy": "balanced_accuracy",
            "roc_auc": "roc_auc",
            "average_precision": "average_precision",
            "trapezoidal_pr_auc": "trapezoidal_pr_auc",
            "true_negatives": "true_negatives",
            "false_positives": "false_positives",
            "false_negatives": "false_negatives",
            "true_positives": "true_positives",
        }
        for csv_field, metric_path in comparable_fields.items():
            expected_value: Any = metrics
            for component in metric_path.split("."):
                expected_value = expected_value[component]
            actual_value = row[csv_field]
            if expected_value is None:
                if actual_value != "":
                    raise AssertionError(f"CSV {csv_field} should be empty.")
            elif isinstance(expected_value, (int, float)):
                if not math.isclose(
                    float(actual_value),
                    float(expected_value),
                    rel_tol=TOLERANCE,
                    abs_tol=TOLERANCE,
                ):
                    raise AssertionError(f"CSV {csv_field} differs from JSON.")
            elif actual_value != str(expected_value):
                raise AssertionError(f"CSV {csv_field} differs from JSON.")
    if sha256_file(comparison_path) != results["result_file_sha256"]["comparison_csv"]:
        raise AssertionError("Comparison CSV checksum mismatch.")
    assertions["evaluation_files_valid_json_and_csv"] = True
    required_figure_keys = {
        "confusion_validation",
        "confusion_test",
        "precision_recall_validation",
        "precision_recall_test",
        "roc_validation",
        "roc_test",
        "test_model_comparison",
    }
    if not required_figure_keys.issubset(results["figures"]):
        raise AssertionError("One or more required charts are missing.")
    if any(not Path(results["figures"][key]).is_file() for key in required_figure_keys):
        raise AssertionError("A generated figure is missing.")
    assertions["required_visualizations_exist"] = True

    if results["models_refitted"] is not False or results["test_threshold_or_hyperparameter_tuned"] is not False:
        raise AssertionError("Metadata indicates refit or test-based tuning.")
    if training_manifest["training_input_sha256"] != input_hashes["train_csv"]:
        raise AssertionError("Step 3 training input hash changed.")
    assertions["training_input_hash_unchanged"] = True
    assertions["no_refit_test_tuning_or_selection"] = True

    # Repeat the frozen evaluation, without fitting, and compare the actual metrics.
    before_model_hashes = {
        name: sha256_file(resolve(config["inputs"]["model_artifacts"][name]["path"]))
        for name in ("random_forest", "xgboost")
    }
    repeated = evaluator.evaluate(config_path)
    for cohort_name in COHORTS:
        _assert_nested_close(
            cohort_by_name[cohort_name],
            next(item for item in repeated["cohorts"] if item["cohort"] == cohort_name),
            f"repeat.{cohort_name}",
        )
    after_model_hashes = {
        name: sha256_file(resolve(config["inputs"]["model_artifacts"][name]["path"]))
        for name in ("random_forest", "xgboost")
    }
    if before_model_hashes != after_model_hashes or before_model_hashes != model_hashes:
        raise AssertionError("Evaluation modified a saved model artifact.")
    if sha256_file(predictions_path) != results["prediction_rows_csv"]["sha256"]:
        raise AssertionError("Repeated evaluation changed prediction output checksum.")
    assertions["repeated_evaluation_metrics_match"] = True
    assertions["model_artifact_hashes_unchanged_after_evaluation"] = True

    status_result = subprocess.run(
        ["git", "status", "--porcelain", "--untracked-files=all"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    changed_paths = []
    for line in status_result.stdout.splitlines():
        path = line[3:].strip().replace("\\", "/")
        if path.startswith("DevInsight/"):
            path = path[len("DevInsight/") :]
        changed_paths.append(path)
    protected_fragments = (
        "apps/",
        "lib/",
        "fastapi",
        "supabase",
        "database/",
        "migrations/",
    )
    if any(
        any(fragment in path.casefold() for fragment in protected_fragments)
        for path in changed_paths
    ):
        raise AssertionError("Application or database paths appear in Git status.")
    assertions["no_application_or_database_files_modified"] = True

    if not all(assertions.values()):
        raise AssertionError(
            "Failed assertions: "
            + ", ".join(name for name, passed in assertions.items() if not passed)
        )
    return {
        "status": "PASS",
        "assertions": assertions,
        "assertion_count": len(assertions),
        "cohort_metrics_recomputed": flattened_metrics,
        "repeated_evaluation_metrics_match": True,
        "model_hashes_unchanged": after_model_hashes,
        "protected_application_database_paths_checked": True,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--results", type=Path, default=DEFAULT_RESULTS)
    arguments = parser.parse_args()
    report = verify(arguments.config, arguments.results)
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

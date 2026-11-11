#!/usr/bin/env python3
"""Evaluate frozen RQ1 models on fixed validation/test releases."""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.metadata
import json
import math
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import joblib
import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
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
    roc_curve,
)


ROOT = Path(__file__).resolve().parents[3]
DEFAULT_CONFIG = ROOT / "ml" / "rq1" / "config" / "evaluation_config.json"
METRIC_TOLERANCE = 1e-12


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def resolve(relative_path: str) -> Path:
    return ROOT / Path(relative_path)


def verify_environment(config: dict[str, Any]) -> dict[str, str]:
    python_version = ".".join(str(part) for part in sys.version_info[:3])
    if python_version != config["evaluation_environment"]["python"]:
        raise RuntimeError(
            f"Python version differs from frozen config: {python_version}"
        )
    versions = {
        package: importlib.metadata.version(package)
        for package in (
            "numpy",
            "pandas",
            "scikit-learn",
            "xgboost",
            "joblib",
            "matplotlib",
        )
    }
    expected = {
        key: value
        for key, value in config["evaluation_environment"].items()
        if key != "python"
    }
    if versions != expected:
        raise RuntimeError(f"Evaluation package versions differ: {versions}")
    return versions


def load_config(path: Path) -> dict[str, Any]:
    config = json.loads(path.read_text(encoding="utf-8"))
    if config["protocol_frozen_before_evaluation"] is not True:
        raise ValueError("Evaluation protocol must be frozen before scoring.")
    if config["primary_threshold"] != 0.5:
        raise ValueError("Primary threshold must remain fixed at 0.50.")
    if config["feature_names"] != [
        "CBO",
        "DCC",
        "ExportCoupling",
        "ImportCoupling",
        "NOM",
        "WMC",
    ]:
        raise ValueError("Configured feature schema differs from Step 2.")
    return config


def load_and_verify_inputs(
    config: dict[str, Any], config_path: Path
) -> tuple[dict[str, pd.DataFrame], dict[str, Any], dict[str, str]]:
    training_manifest_path = resolve(config["inputs"]["training_manifest"])
    split_manifest_path = resolve(config["inputs"]["split_manifest"])
    training_manifest = json.loads(training_manifest_path.read_text(encoding="utf-8"))
    split_manifest = json.loads(split_manifest_path.read_text(encoding="utf-8"))
    expected_releases = {
        "train": config["releases"]["training"],
        "validation": config["releases"]["validation"],
        "test": config["releases"]["test"],
    }
    assignments = {
        item["split"]: item["release_sheet"]
        for item in split_manifest["split_assignments"]
    }
    if assignments != expected_releases:
        raise ValueError(f"Unexpected Step 2 release assignments: {assignments}")
    if (
        training_manifest["training_release"] != "jedit_4_1"
        or training_manifest["validation_release"] != config["releases"]["validation"]
        or training_manifest["test_release"] != config["releases"]["test"]
    ):
        raise ValueError("Training manifest release assumptions do not match.")

    input_hashes: dict[str, str] = {}
    frames: dict[str, pd.DataFrame] = {}
    expected_columns = [*config["feature_names"], config["target_name"]]
    for split in ("train", "validation", "test"):
        input_key = "training_csv" if split == "train" else f"{split}_csv"
        input_config = config["inputs"][input_key]
        path = resolve(input_config["path"])
        actual_hash = sha256_file(path)
        if actual_hash != input_config["sha256"]:
            raise ValueError(f"{split} CSV checksum mismatch: {actual_hash}")
        if split == "train" and (
            actual_hash != training_manifest["training_input_sha256"]
        ):
            raise ValueError("Training CSV hash differs from training manifest.")
        if split == "train":
            continue
        frame = pd.read_csv(path)
        if frame.columns.tolist() != expected_columns:
            raise ValueError(
                f"{split} columns differ from the frozen feature schema: "
                f"{frame.columns.tolist()}"
            )
        if frame.empty or frame.isna().any().any():
            raise ValueError(f"{split} contains no rows or has missing values.")
        values = frame.loc[:, config["feature_names"]].to_numpy(dtype=np.float64)
        if not np.isfinite(values).all():
            raise ValueError(f"{split} contains non-finite features.")
        if set(frame[config["target_name"]].unique()) != {0, 1}:
            raise ValueError(f"{split} target is not exactly binary 0/1.")
        expected = config["expected_sample_counts"][split]
        counts = frame[config["target_name"]].value_counts().to_dict()
        if len(frame) != expected["rows"] or {
            "0": int(counts.get(0, 0)),
            "1": int(counts.get(1, 0)),
        } != expected["class_counts"]:
            raise ValueError(
                f"{split} sample/class counts differ from the frozen design."
            )
        if frame.columns.tolist()[-1] != config["target_name"]:
            raise ValueError(f"Unexpected target position in {split}.")
        frames[split] = frame
        input_hashes[f"{split}_csv"] = actual_hash
    input_hashes["train_csv"] = sha256_file(
        resolve(config["inputs"]["training_csv"]["path"])
    )

    workbook_cfg = config["inputs"]["source_workbook"]
    workbook_hash = sha256_file(resolve(workbook_cfg["path"]))
    if workbook_hash != workbook_cfg["sha256"]:
        raise ValueError("Raw workbook checksum changed.")
    if training_manifest["source_workbook_sha256"] != workbook_hash:
        raise ValueError("Training manifest source workbook checksum mismatch.")
    input_hashes["source_workbook"] = workbook_hash

    for model_name, model_cfg in config["inputs"]["model_artifacts"].items():
        model_path = resolve(model_cfg["path"])
        model_hash = sha256_file(model_path)
        if model_hash != model_cfg["sha256"]:
            raise ValueError(f"{model_name} artifact checksum mismatch.")
        if (
            training_manifest["models"][model_name]["artifact_sha256"]
            != model_hash
        ):
            raise ValueError(f"{model_name} artifact differs from training manifest.")
        input_hashes[f"{model_name}_model"] = model_hash
    if training_manifest["feature_order"] != config["feature_names"]:
        raise ValueError("Training feature order differs from evaluation config.")
    if training_manifest["training_rows"] != 197:
        raise ValueError("Training row count differs from Step 3.")
    if training_manifest["training_class_counts"] != {"0": 122, "1": 75}:
        raise ValueError("Training class counts differ from Step 3.")
    input_hashes["evaluation_config"] = sha256_file(config_path)
    return frames, training_manifest, input_hashes


def wilson_interval(successes: int, total: int, confidence: float) -> list[float] | None:
    if total == 0:
        return None
    z_values = {0.95: 1.959963984540054}
    if confidence not in z_values:
        raise ValueError(f"Unsupported Wilson confidence level: {confidence}")
    z = z_values[confidence]
    proportion = successes / total
    denominator = 1 + z * z / total
    center = (proportion + z * z / (2 * total)) / denominator
    margin = (
        z
        * math.sqrt(
            proportion * (1 - proportion) / total
            + z * z / (4 * total * total)
        )
        / denominator
    )
    return [max(0.0, center - margin), min(1.0, center + margin)]


def calculate_metrics(
    y_true: np.ndarray,
    probabilities: np.ndarray,
    threshold: float,
    zero_division: int,
    confidence: float,
) -> dict[str, Any]:
    y_pred = (probabilities >= threshold).astype(np.int64)
    matrix = confusion_matrix(y_true, y_pred, labels=[0, 1])
    tn, fp, fn, tp = (int(value) for value in matrix.ravel())
    specificity = tn / (tn + fp) if tn + fp else None
    if len(np.unique(y_true)) == 2:
        roc_auc: float | None = float(roc_auc_score(y_true, probabilities))
        precision_curve, recall_curve, _ = precision_recall_curve(
            y_true, probabilities, pos_label=1
        )
        trapezoidal_pr_auc: float | None = float(
            auc(recall_curve, precision_curve)
        )
        average_precision: float | None = float(
            average_precision_score(y_true, probabilities, pos_label=1)
        )
    else:
        roc_auc = None
        trapezoidal_pr_auc = None
        average_precision = None
    precision = float(
        precision_score(
            y_true, y_pred, pos_label=1, zero_division=zero_division
        )
    )
    recall = float(recall_score(y_true, y_pred, pos_label=1, zero_division=zero_division))
    f1 = float(f1_score(y_true, y_pred, pos_label=1, zero_division=zero_division))
    return {
        "sample_count": int(len(y_true)),
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
        "predicted_positive_count": int(np.sum(y_pred == 1)),
        "accuracy": float(accuracy_score(y_true, y_pred)),
        "precision_positive": precision,
        "recall_positive": recall,
        "f1_positive": f1,
        "specificity": specificity,
        "balanced_accuracy": float(balanced_accuracy_score(y_true, y_pred)),
        "roc_auc": roc_auc,
        "average_precision": average_precision,
        "trapezoidal_pr_auc": trapezoidal_pr_auc,
        "positive_recall_wilson_95_percent_interval": wilson_interval(
            tp, tp + fn, confidence
        ),
    }


def _feature_keys(frame: pd.DataFrame, features: list[str]) -> list[tuple[float, ...]]:
    return [
        tuple(float(value) for value in row)
        for row in frame.loc[:, features].to_numpy(dtype=np.float64)
    ]


def _load_models(
    config: dict[str, Any], training_manifest: dict[str, Any]
) -> dict[str, Any]:
    loaded: dict[str, Any] = {}
    for name in ("random_forest", "xgboost"):
        model_path = resolve(config["inputs"]["model_artifacts"][name]["path"])
        model = joblib.load(model_path)
        if list(model.classes_) != [0, 1]:
            raise ValueError(f"{name} class order must be [0, 1].")
        if list(model.feature_names_in_) != config["feature_names"]:
            raise ValueError(f"{name} feature order differs from the protocol.")
        if (
            training_manifest["models"][name]["training_release"]
            != config["releases"]["training"]
        ):
            raise ValueError(f"{name} training release metadata is unexpected.")
        loaded[name] = model
    return loaded


def _probabilities(
    models: dict[str, Any], frame: pd.DataFrame, feature_names: list[str]
) -> dict[str, np.ndarray]:
    x = frame.loc[:, feature_names]
    scores: dict[str, np.ndarray] = {}
    for name, model in models.items():
        positive_index = list(model.classes_).index(1)
        probabilities = np.asarray(model.predict_proba(x)[:, positive_index], dtype=float)
        if probabilities.shape != (len(frame),):
            raise ValueError(f"{name} returned the wrong number of probabilities.")
        if not np.isfinite(probabilities).all() or (
            (probabilities < 0).any() or (probabilities > 1).any()
        ):
            raise ValueError(f"{name} produced invalid probabilities.")
        scores[name] = probabilities
    scores["majority_class_baseline"] = np.zeros(len(frame), dtype=float)
    return scores


def _evaluate_cohort(
    cohort_name: str,
    release: str,
    frame: pd.DataFrame,
    scores: dict[str, np.ndarray],
    config: dict[str, Any],
    prediction_rows: list[dict[str, Any]],
    split_row_indices: np.ndarray,
) -> dict[str, Any]:
    y_true = frame[config["target_name"]].to_numpy(dtype=np.int64)
    results: dict[str, Any] = {}
    for model_name, probabilities in scores.items():
        metric_values = calculate_metrics(
            y_true,
            probabilities,
            config["primary_threshold"],
            config["metric_policy"]["zero_division"],
            config["metric_policy"]["recall_uncertainty"]["confidence_level"],
        )
        results[model_name] = metric_values
        predicted = (probabilities >= config["primary_threshold"]).astype(np.int64)
        prediction_rows.extend(
            {
                "cohort": cohort_name,
                "release": release,
                "split_row_index": int(row_index),
                "model": model_name,
                "actual_defect": int(actual),
                "positive_probability": float(probability),
                "predicted_defect": int(prediction),
                "threshold": config["primary_threshold"],
            }
            for row_index, actual, probability, prediction in zip(
                split_row_indices, y_true, probabilities, predicted, strict=True
            )
        )
    return {
        "cohort": cohort_name,
        "release": release,
        "sample_count": int(len(frame)),
        "class_counts": {
            "0": int(np.sum(y_true == 0)),
            "1": int(np.sum(y_true == 1)),
        },
        "class_proportions": {
            "0": float(np.mean(y_true == 0)),
            "1": float(np.mean(y_true == 1)),
        },
        "diagnostic_only": cohort_name == "test_novel_feature_vectors_diagnostic",
        "metrics_by_model": results,
    }


def _save_confusion_figure(
    cohort: dict[str, Any], figure_path: Path, threshold: float
) -> None:
    names = ["random_forest", "xgboost", "majority_class_baseline"]
    fig, axes = plt.subplots(1, len(names), figsize=(12, 4))
    matrix_values = []
    for axis, name in zip(axes, names, strict=True):
        matrix = cohort["metrics_by_model"][name]["confusion_matrix"]
        matrix_values.append(matrix)
        axis.imshow(matrix, cmap="Blues", vmin=0)
        axis.set_title(name.replace("_", " ").title())
        axis.set_xlabel("Predicted Defect")
        axis.set_ylabel("Actual Defect")
        axis.set_xticks([0, 1], labels=["0", "1"])
        axis.set_yticks([0, 1], labels=["0", "1"])
        for row in range(2):
            for column in range(2):
                axis.text(column, row, str(matrix[row][column]), ha="center", va="center")
    fig.suptitle(
        f"{cohort['cohort']} confusion matrices (threshold={threshold:.2f})"
    )
    fig.tight_layout()
    fig.savefig(figure_path, dpi=160, bbox_inches="tight")
    plt.close(fig)


def _save_curves(
    frame: pd.DataFrame,
    scores: dict[str, np.ndarray],
    config: dict[str, Any],
    cohort_name: str,
    figure_dir: Path,
) -> dict[str, str | None]:
    y_true = frame[config["target_name"]].to_numpy(dtype=np.int64)
    result: dict[str, str | None] = {}
    names = {
        "random_forest": "Random Forest",
        "xgboost": "XGBoost",
        "majority_class_baseline": "Majority baseline (always 0)",
    }

    pr_path = figure_dir / f"precision_recall_{cohort_name}.png"
    fig, axis = plt.subplots(figsize=(7, 5))
    for model_name, probabilities in scores.items():
        precision, recall, _ = precision_recall_curve(
            y_true, probabilities, pos_label=1
        )
        average_precision = average_precision_score(
            y_true, probabilities, pos_label=1
        )
        axis.plot(recall, precision, label=f"{names[model_name]} (AP={average_precision:.3f})")
    axis.set(
        xlabel="Recall (Defect=1)",
        ylabel="Precision (Defect=1)",
        title=f"Precision-recall curves — {cohort_name}",
        xlim=(0, 1),
        ylim=(0, 1.02),
    )
    axis.legend(loc="best")
    axis.grid(alpha=0.25)
    fig.tight_layout()
    fig.savefig(pr_path, dpi=160, bbox_inches="tight")
    plt.close(fig)
    result["precision_recall"] = str(pr_path.resolve())

    if len(np.unique(y_true)) == 2:
        roc_path = figure_dir / f"roc_{cohort_name}.png"
        fig, axis = plt.subplots(figsize=(7, 5))
        for model_name, probabilities in scores.items():
            false_positive_rate, true_positive_rate, _ = roc_curve(
                y_true, probabilities, pos_label=1
            )
            area = roc_auc_score(y_true, probabilities)
            axis.plot(
                false_positive_rate,
                true_positive_rate,
                label=f"{names[model_name]} (ROC-AUC={area:.3f})",
            )
        axis.plot([0, 1], [0, 1], linestyle="--", color="gray", label="Chance reference")
        axis.set(
            xlabel="False positive rate",
            ylabel="True positive rate",
            title=f"ROC curves — {cohort_name}",
            xlim=(0, 1),
            ylim=(0, 1.02),
        )
        axis.legend(loc="best")
        axis.grid(alpha=0.25)
        fig.tight_layout()
        fig.savefig(roc_path, dpi=160, bbox_inches="tight")
        plt.close(fig)
        result["roc"] = str(roc_path.resolve())
    else:
        result["roc"] = None
    return result


def _save_test_comparison(test_cohort: dict[str, Any], figure_dir: Path) -> str:
    models = ["random_forest", "xgboost", "majority_class_baseline"]
    metrics = [
        ("accuracy", "Accuracy"),
        ("precision_positive", "Precision (Defect=1)"),
        ("recall_positive", "Recall (Defect=1)"),
        ("f1_positive", "F1 (Defect=1)"),
        ("balanced_accuracy", "Balanced accuracy"),
    ]
    x = np.arange(len(metrics))
    width = 0.25
    fig, axis = plt.subplots(figsize=(11, 5))
    for index, model_name in enumerate(models):
        values = [
            test_cohort["metrics_by_model"][model_name][key] for key, _ in metrics
        ]
        axis.bar(x + (index - 1) * width, values, width, label=model_name.replace("_", " ").title())
    axis.set_xticks(x, labels=[label for _, label in metrics], rotation=15, ha="right")
    axis.set_ylim(0, 1.05)
    axis.set_ylabel("Score (0–1)")
    axis.set_title("Fixed-threshold test-set comparison (not production performance)")
    axis.legend()
    axis.grid(axis="y", alpha=0.25)
    fig.tight_layout()
    path = figure_dir / "test_model_comparison.png"
    fig.savefig(path, dpi=160, bbox_inches="tight")
    plt.close(fig)
    return str(path.resolve())


def evaluate(config_path: Path) -> dict[str, Any]:
    config = load_config(config_path)
    environment = verify_environment(config)
    frames, training_manifest, input_hashes = load_and_verify_inputs(
        config, config_path
    )
    models = _load_models(config, training_manifest)
    prediction_rows: list[dict[str, Any]] = []
    cohort_results: list[dict[str, Any]] = []
    cohort_scores: dict[str, dict[str, np.ndarray]] = {}
    cohort_frames: dict[str, pd.DataFrame] = {}

    # Score the frozen validation release first; then the untouched full test.
    for cohort_name in ("validation", "test"):
        frame = frames[cohort_name]
        scores = _probabilities(models, frame, config["feature_names"])
        cohort_scores[cohort_name] = scores
        cohort_frames[cohort_name] = frame
        cohort_results.append(
            _evaluate_cohort(
                cohort_name,
                config["releases"][cohort_name],
                frame,
                scores,
                config,
                prediction_rows,
                np.arange(1, len(frame) + 1),
            )
        )

    train_frame = pd.read_csv(resolve(config["inputs"]["training_csv"]["path"]))
    train_vectors = set(_feature_keys(train_frame, config["feature_names"]))
    validation_vectors = set(
        _feature_keys(frames["validation"], config["feature_names"])
    )
    prior_vectors = train_vectors | validation_vectors
    test_frame = frames["test"]
    novel_mask = np.array(
        [
            vector not in prior_vectors
            for vector in _feature_keys(test_frame, config["feature_names"])
        ],
        dtype=bool,
    )
    diagnostic_frame = test_frame.loc[novel_mask].reset_index(drop=True)
    expected_diagnostic = config["expected_sample_counts"][
        "test_novel_feature_vectors_diagnostic"
    ]
    observed_diagnostic_counts = diagnostic_frame["Defect"].value_counts().to_dict()
    if len(diagnostic_frame) != expected_diagnostic["rows"] or {
        "0": int(observed_diagnostic_counts.get(0, 0)),
        "1": int(observed_diagnostic_counts.get(1, 0)),
    } != expected_diagnostic["class_counts"]:
        raise ValueError("Novel-feature-vector diagnostic cohort differs from Step 2.")
    diagnostic_scores = {
        name: values[novel_mask] for name, values in cohort_scores["test"].items()
    }
    cohort_scores["test_novel_feature_vectors_diagnostic"] = diagnostic_scores
    cohort_frames["test_novel_feature_vectors_diagnostic"] = diagnostic_frame
    cohort_results.append(
        _evaluate_cohort(
            "test_novel_feature_vectors_diagnostic",
            config["releases"]["diagnostic"],
            diagnostic_frame,
            diagnostic_scores,
            config,
            prediction_rows,
            np.flatnonzero(novel_mask) + 1,
        )
    )

    result_dir = resolve("ml/rq1/results")
    figures_dir = resolve(config["outputs"]["figures_directory"])
    figures_dir.mkdir(parents=True, exist_ok=True)
    figures: dict[str, Any] = {}
    for cohort in cohort_results:
        cohort_name = cohort["cohort"]
        if cohort_name == "test_novel_feature_vectors_diagnostic":
            continue
        confusion_path = figures_dir / f"confusion_{cohort_name}.png"
        _save_confusion_figure(
            cohort, confusion_path, config["primary_threshold"]
        )
        figures[f"confusion_{cohort_name}"] = str(confusion_path.resolve())
        figures.update(
            {
                f"{key}_{cohort_name}": value
                for key, value in _save_curves(
                    cohort_frames[cohort_name],
                    cohort_scores[cohort_name],
                    config,
                    cohort_name,
                    figures_dir,
                ).items()
            }
        )
    figures["test_model_comparison"] = _save_test_comparison(
        cohort_results[1], figures_dir
    )

    prediction_path = resolve(config["outputs"]["predictions_csv"])
    prediction_path.parent.mkdir(parents=True, exist_ok=True)
    prediction_columns = [
        "cohort",
        "release",
        "split_row_index",
        "model",
        "actual_defect",
        "positive_probability",
        "predicted_defect",
        "threshold",
    ]
    with prediction_path.open("w", encoding="utf-8", newline="") as output:
        writer = csv.DictWriter(
            output, fieldnames=prediction_columns, lineterminator="\n"
        )
        writer.writeheader()
        writer.writerows(prediction_rows)

    metrics_path = resolve(config["outputs"]["metrics_json"])
    comparison_path = resolve(config["outputs"]["comparison_csv"])
    metric_document: dict[str, Any] = {
        "result_version": 1,
        "evaluation_timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "protocol": {
            "config_path": str(config_path.resolve().relative_to(ROOT)).replace("\\", "/"),
            "config_sha256": sha256_file(config_path),
            "frozen_before_evaluation": True,
            "primary_threshold": config["primary_threshold"],
            "threshold_selection": config["threshold_selection"],
            "positive_class": config["positive_class"],
            "zero_division_policy": config["metric_policy"]["zero_division"],
            "confusion_matrix_order": config["metric_policy"]["confusion_matrix_order"],
            "split_type": config["split_type"],
            "diagnostic_subset_policy": config["diagnostic_subset"],
        },
        "feature_names": config["feature_names"],
        "target_name": config["target_name"],
        "target_definition": training_manifest["target_definition"],
        "input_sha256": input_hashes,
        "model_sha256": {
            name: training_manifest["models"][name]["artifact_sha256"]
            for name in ("random_forest", "xgboost")
        },
        "training_class_distribution": training_manifest["training_class_counts"],
        "evaluation_environment": {
            "python": config["evaluation_environment"]["python"],
            "packages": environment,
        },
        "cohorts": cohort_results,
        "figures": figures,
        "prediction_rows_csv": {
            "path": str(prediction_path.resolve().relative_to(ROOT)).replace("\\", "/"),
            "sha256": sha256_file(prediction_path),
            "rows": len(prediction_rows),
        },
        "models_refitted": False,
        "test_threshold_or_hyperparameter_tuned": False,
    }
    metrics_path.parent.mkdir(parents=True, exist_ok=True)
    metrics_path.write_text(
        json.dumps(metric_document, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    with comparison_path.open("w", encoding="utf-8", newline="") as output:
        fields = [
            "cohort",
            "release",
            "model",
            "sample_count",
            "positive_count",
            "predicted_positive_count",
            "threshold",
            "accuracy",
            "precision_positive",
            "recall_positive",
            "f1_positive",
            "specificity",
            "balanced_accuracy",
            "roc_auc",
            "average_precision",
            "trapezoidal_pr_auc",
            "true_negatives",
            "false_positives",
            "false_negatives",
            "true_positives",
            "recall_wilson_95_lower",
            "recall_wilson_95_upper",
        ]
        writer = csv.DictWriter(output, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for cohort in cohort_results:
            for model_name, metrics in cohort["metrics_by_model"].items():
                interval = metrics["positive_recall_wilson_95_percent_interval"]
                writer.writerow(
                    {
                        "cohort": cohort["cohort"],
                        "release": cohort["release"],
                        "model": model_name,
                        "sample_count": metrics["sample_count"],
                        "positive_count": metrics["class_counts"]["1"],
                        "predicted_positive_count": metrics["predicted_positive_count"],
                        "threshold": metrics["threshold"],
                        "accuracy": metrics["accuracy"],
                        "precision_positive": metrics["precision_positive"],
                        "recall_positive": metrics["recall_positive"],
                        "f1_positive": metrics["f1_positive"],
                        "specificity": metrics["specificity"],
                        "balanced_accuracy": metrics["balanced_accuracy"],
                        "roc_auc": metrics["roc_auc"],
                        "average_precision": metrics["average_precision"],
                        "trapezoidal_pr_auc": metrics["trapezoidal_pr_auc"],
                        "true_negatives": metrics["true_negatives"],
                        "false_positives": metrics["false_positives"],
                        "false_negatives": metrics["false_negatives"],
                        "true_positives": metrics["true_positives"],
                        "recall_wilson_95_lower": interval[0] if interval else None,
                        "recall_wilson_95_upper": interval[1] if interval else None,
                    }
                )
    metric_document["result_file_sha256"] = {
        "comparison_csv": sha256_file(comparison_path),
        "predictions_csv": sha256_file(prediction_path),
    }
    metrics_path.write_text(
        json.dumps(metric_document, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return metric_document


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    arguments = parser.parse_args()
    result = evaluate(arguments.config)
    print(
        json.dumps(
            {
                "status": "EVALUATED",
                "threshold": result["protocol"]["primary_threshold"],
                "cohorts": result["cohorts"],
                "result_file_sha256": result["result_file_sha256"],
                "figures": result["figures"],
                "models_refitted": False,
                "test_threshold_or_hyperparameter_tuned": False,
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

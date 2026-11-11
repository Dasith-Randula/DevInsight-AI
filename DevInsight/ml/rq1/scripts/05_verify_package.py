#!/usr/bin/env python3
"""Independently verify the completed RQ1 experiment package."""

from __future__ import annotations

import hashlib
import importlib.metadata
import json
import math
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
RQ1 = ROOT / "ml" / "rq1"
FEATURES = [
    "CBO",
    "DCC",
    "ExportCoupling",
    "ImportCoupling",
    "NOM",
    "WMC",
]
RELEASES = {
    "train": ("jedit_4_1", 197, {"0": 122, "1": 75}),
    "validation": ("jedit_4_2", 225, {"0": 178, "1": 47}),
    "test": ("jedit_4_3", 470, {"0": 459, "1": 11}),
}
SPLIT_HASHES = {
    "train": "1767f58d2664adfeb2c62dee4f8b139852c8336810da7253ca617153985f7f0d",
    "validation": "9b4b765bda5a874e4ff59c7db095db2a2276fe34167c5e931d26d2c218bf70ad",
    "test": "ca4c71b7b22f3efd1a32d52781df9ac7c5410bfeddf3da94dd78068cae8469b7",
}
WORKBOOK_SHA256 = "364ab30e660ba3d78644ac717d28bb224e03648f9ad06b42a3453daee2ae0c31"
MODEL_HASHES = {
    "random_forest": "09d4d67e915b3025e1f5f52e294d22c3d74c900eec2df7635f5d2002912ec681",
    "xgboost": "c6f1ebf8b78a34562cb6e90e20e4ec4be2ea6bc5f91466873beb5da59a3a4678",
}
FIGURES = [
    "confusion_validation.png",
    "confusion_test.png",
    "precision_recall_validation.png",
    "precision_recall_test.png",
    "roc_validation.png",
    "roc_test.png",
    "test_model_comparison.png",
]
REQUIRED_METRICS = (
    "accuracy",
    "precision_positive",
    "recall_positive",
    "f1_positive",
    "specificity",
    "balanced_accuracy",
    "roc_auc",
    "average_precision",
    "trapezoidal_pr_auc",
)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def run_json(script: str, *arguments: str) -> dict[str, Any]:
    completed = subprocess.run(
        [sys.executable, "-B", str(RQ1 / "scripts" / script), *arguments],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode:
        raise RuntimeError(
            f"{script} exited {completed.returncode}.\n"
            f"stdout:\n{completed.stdout}\nstderr:\n{completed.stderr}"
        )
    try:
        result = json.loads(completed.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(
            f"{script} did not emit valid JSON.\n"
            f"stdout:\n{completed.stdout}\nstderr:\n{completed.stderr}"
        ) from error
    return result


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def close(actual: Any, expected: float) -> bool:
    return isinstance(actual, (int, float)) and math.isclose(
        float(actual), expected, rel_tol=1e-12, abs_tol=1e-12
    )


def git_names(*arguments: str) -> list[str]:
    completed = subprocess.run(
        ["git", *arguments],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return [line.strip() for line in completed.stdout.splitlines() if line.strip()]


def verify() -> dict[str, Any]:
    assertions: dict[str, bool] = {}
    workbook_path = RQ1 / "datasets" / "raw" / "promise_regenerated_candidates.xlsx"
    step1_report = RQ1 / "verification" / "step01_verification_report.md"
    step2_report = RQ1 / "verification" / "step02_verification_report.md"
    step3_report = RQ1 / "verification" / "step03_verification_report.md"
    step4_report = RQ1 / "verification" / "step04_verification_report.md"

    step1 = run_json(
        "02_validate_versioned_promise.py",
        "--workbook",
        str(workbook_path.relative_to(ROOT)),
        "--project",
        "jedit",
    )
    assertions["step1_evidence_and_validator_output_exist"] = (
        step1_report.is_file()
        and step1.get("project") == "jedit"
        and step1.get("workbook") == workbook_path.name
    )
    require(assertions["step1_evidence_and_validator_output_exist"], "Step 1 evidence is missing.")
    assertions["step1_source_hash_release_schema_and_counts_verified"] = (
        sha256_file(workbook_path) == WORKBOOK_SHA256
        and step1["release_order_by_version_identifier"]
        == ["jedit_3_2_1", "jedit_4_0", "jedit_4_1", "jedit_4_2", "jedit_4_3"]
        and step1["headers"]
        == ["ClassName", *FEATURES, "Defect"]
        and {
            release: (
                record["rows"],
                record["class_counts_raw"],
            )
            for release, record in step1["releases"].items()
        }
        == {
            "jedit_3_2_1": (163, {"0": 75, "1": 88}),
            "jedit_4_0": (192, {"0": 119, "1": 73}),
            "jedit_4_1": (197, {"0": 122, "1": 75}),
            "jedit_4_2": (225, {"0": 178, "1": 47}),
            "jedit_4_3": (470, {"0": 459, "1": 11}),
        }
    )
    require(
        assertions["step1_source_hash_release_schema_and_counts_verified"],
        "Step 1 source, schema, or observed counts differ.",
    )
    step1_assertions = step1["assertions"]
    expected_step1_warning = (
        step1_assertions.get("no_conflicting_feature_vectors_within_release") is False
        and step1["releases"]["jedit_4_0"]["conflicting_feature_vector_groups"] == 1
        and step1["releases"]["jedit_4_3"]["conflicting_feature_vector_groups"] == 1
        and "conflicting feature vectors" in step1_report.read_text(encoding="utf-8").lower()
    )
    assertions["step1_known_conflicting_vector_warning_is_preserved"] = expected_step1_warning
    require(expected_step1_warning, "Step 1's known conflicting-vector warning changed or is undocumented.")

    step2 = run_json("02_verify_splits.py")
    step3 = run_json("03_verify_training.py")
    for label, result, report in (
        ("step2", step2, step2_report),
        ("step3", step3, step3_report),
    ):
        assertions[f"{label}_independent_verifier_passes"] = (
            report.is_file()
            and result.get("status") == "PASS"
            and all(value is True for value in result["assertions"].values())
        )
        require(assertions[f"{label}_independent_verifier_passes"], f"{label} verifier failed.")
    step4_evidence = step4_report.read_text(encoding="utf-8")
    normalized_step4_evidence = step4_evidence.replace("**", "")
    assertions["step4_independent_verifier_pass_is_recorded"] = (
        "Decision: PASS" in normalized_step4_evidence
        and "all 25 assertions" in normalized_step4_evidence
        and "repeat evaluation" in normalized_step4_evidence.lower()
    )
    require(
        assertions["step4_independent_verifier_pass_is_recorded"],
        "Step 4 independent verification evidence is missing or not passing.",
    )

    training_config_path = RQ1 / "config" / "training_config.json"
    evaluation_config_path = RQ1 / "config" / "evaluation_config.json"
    split_manifest_path = RQ1 / "reports" / "step02_split_manifest.json"
    training_manifest_path = RQ1 / "results" / "step03_training_manifest.json"
    metrics_path = RQ1 / "results" / "step04_evaluation_metrics.json"
    comparison_path = RQ1 / "results" / "step04_model_comparison.csv"
    prediction_path = RQ1 / "results" / "predictions" / "step04_predictions.csv"
    figures_dir = RQ1 / "results" / "figures"
    final_report_path = RQ1 / "reports" / "step05_final_experiment_report.md"
    alignment_path = RQ1 / "reports" / "step05_rq1_proposal_alignment.md"
    readme_path = RQ1 / "README.md"
    package_manifest_path = RQ1 / "results" / "step05_experiment_manifest.json"

    training_config = read_json(training_config_path)
    evaluation_config = read_json(evaluation_config_path)
    split_manifest = read_json(split_manifest_path)
    training_manifest = read_json(training_manifest_path)
    metrics = read_json(metrics_path)
    package_manifest = read_json(package_manifest_path)
    final_report = final_report_path.read_text(encoding="utf-8")
    alignment_report = alignment_path.read_text(encoding="utf-8")
    readme = readme_path.read_text(encoding="utf-8")

    actual_split_hashes = {
        split: sha256_file(RQ1 / "datasets" / "processed" / f"{split}.csv")
        for split in RELEASES
    }
    assertions["dataset_and_split_checksums_match_all_prior_manifests"] = (
        sha256_file(workbook_path) == WORKBOOK_SHA256
        and actual_split_hashes == SPLIT_HASHES
        and training_config["inputs"]["source_workbook_sha256"] == WORKBOOK_SHA256
        and training_config["inputs"]["train_sha256"] == SPLIT_HASHES["train"]
        and training_config["inputs"]["validation_sha256"] == SPLIT_HASHES["validation"]
        and training_config["inputs"]["test_sha256"] == SPLIT_HASHES["test"]
    )
    require(assertions["dataset_and_split_checksums_match_all_prior_manifests"], "Dataset checksum mismatch.")

    actual_model_hashes = {
        name: sha256_file(RQ1 / "models" / f"{name}.joblib")
        for name in MODEL_HASHES
    }
    assertions["model_checksums_match_training_and_evaluation_provenance"] = (
        actual_model_hashes == MODEL_HASHES
        and all(
            training_manifest["models"][name]["artifact_sha256"] == MODEL_HASHES[name]
            and evaluation_config["inputs"]["model_artifacts"][name]["sha256"]
            == MODEL_HASHES[name]
            for name in MODEL_HASHES
        )
    )
    require(assertions["model_checksums_match_training_and_evaluation_provenance"], "Model checksum mismatch.")

    assignments = {
        entry["split"]: entry["release_sheet"]
        for entry in split_manifest["split_assignments"]
    }
    expected_assignments = {split: values[0] for split, values in RELEASES.items()}
    target_definition = {
        "0": "non-defective; zero recorded defects",
        "1": "defective; at least one recorded defect",
    }
    assertions["feature_order_labels_and_release_assignments_unchanged"] = (
        training_config["feature_names"] == FEATURES
        and evaluation_config["feature_names"] == FEATURES
        and training_manifest["feature_order"] == FEATURES
        and training_config["target_name"] == evaluation_config["target_name"] == "Defect"
        and training_config["target_definition"] == target_definition
        and training_manifest["target_definition"] == target_definition
        and assignments == expected_assignments
    )
    require(assertions["feature_order_labels_and_release_assignments_unchanged"], "Feature, label, or release configuration changed.")

    manifest_assignments = package_manifest["release_assignments"]
    assertions["experiment_manifest_valid_and_consistent"] = (
        package_manifest["manifest_version"] == 1
        and package_manifest["experiment_id"] == "devinsight-rq1-jedit-release-order-v1"
        and package_manifest["feature_order"] == FEATURES
        and package_manifest["target"] == {"name": "Defect", "definition": target_definition}
        and all(
            manifest_assignments[split]["release"] == release
            and manifest_assignments[split]["rows"] == count
            and manifest_assignments[split]["class_counts"] == counts
            and manifest_assignments[split]["sha256"] == SPLIT_HASHES[split]
            for split, (release, count, counts) in RELEASES.items()
        )
        and package_manifest["dataset"]["source_workbook_sha256"] == WORKBOOK_SHA256
        and package_manifest["models"]["random_forest"]["sha256"] == MODEL_HASHES["random_forest"]
        and package_manifest["models"]["xgboost"]["sha256"] == MODEL_HASHES["xgboost"]
        and package_manifest["training_configuration"]["path"] == "ml/rq1/config/training_config.json"
        and package_manifest["training_configuration"]["sha256"]
        == sha256_file(training_config_path)
        and package_manifest["evaluation_configuration"]["path"] == "ml/rq1/config/evaluation_config.json"
        and package_manifest["evaluation_configuration"]["sha256"]
        == sha256_file(evaluation_config_path)
        and package_manifest["evaluation"]["metrics_path"] == "ml/rq1/results/step04_evaluation_metrics.json"
    )
    require(assertions["experiment_manifest_valid_and_consistent"], "Experiment manifest is inconsistent.")

    threshold = evaluation_config["primary_threshold"]
    assertions["training_and_evaluation_configurations_are_consistent"] = (
        threshold == 0.5
        and evaluation_config["protocol_frozen_before_evaluation"] is True
        and metrics["protocol"]["frozen_before_evaluation"] is True
        and metrics["protocol"]["primary_threshold"] == threshold
        and package_manifest["evaluation_configuration"]["threshold"] == threshold
        and training_config["feature_names"] == evaluation_config["feature_names"]
        and training_config["target_name"] == evaluation_config["target_name"]
    )
    require(assertions["training_and_evaluation_configurations_are_consistent"], "Training/evaluation protocol mismatch.")

    expected_metrics_hash = package_manifest["evaluation"]["metrics_sha256"]
    assertions["metrics_and_model_artifacts_match_package_manifest"] = (
        sha256_file(metrics_path) == expected_metrics_hash
        and sha256_file(comparison_path) == package_manifest["evaluation"]["comparison_csv_sha256"]
        and sha256_file(prediction_path) == package_manifest["evaluation"]["predictions_csv_sha256"]
        and all(
            actual_model_hashes[name] == package_manifest["models"][name]["sha256"]
            for name in MODEL_HASHES
        )
    )
    require(assertions["metrics_and_model_artifacts_match_package_manifest"], "Evaluation or model output checksum mismatch.")

    cohort_by_name = {cohort["cohort"]: cohort for cohort in metrics["cohorts"]}
    report_values_present = True
    arithmetic_valid = True
    baseline_valid = True
    for cohort_name, cohort in cohort_by_name.items():
        negatives = cohort["class_counts"]["0"]
        positives = cohort["class_counts"]["1"]
        for model_name, record in cohort["metrics_by_model"].items():
            tn, fp = record["confusion_matrix"][0]
            fn, tp = record["confusion_matrix"][1]
            total = tn + fp + fn + tp
            arithmetic_valid &= (
                total == cohort["sample_count"]
                and tn + fp == negatives
                and fn + tp == positives
                and close(record["accuracy"], (tn + tp) / total)
                and close(record["precision_positive"], tp / (tp + fp) if tp + fp else 0.0)
                and close(record["recall_positive"], tp / (tp + fn) if tp + fn else 0.0)
                and close(
                    record["f1_positive"],
                    2 * tp / (2 * tp + fp + fn) if 2 * tp + fp + fn else 0.0,
                )
                and close(record["specificity"], tn / (tn + fp) if tn + fp else 0.0)
                and close(
                    record["balanced_accuracy"],
                    (
                        (tn / (tn + fp) if tn + fp else 0.0)
                        + (tp / (tp + fn) if tp + fn else 0.0)
                    )
                    / 2,
                )
            )
            if model_name == "majority_class_baseline":
                baseline_valid &= (
                    fp == 0
                    and tp == 0
                    and record["precision_positive"] == 0
                    and record["recall_positive"] == 0
                    and record["f1_positive"] == 0
                )
            if cohort_name in {"test", "test_novel_feature_vectors_diagnostic"}:
                    compact_confusion = json.dumps(record["confusion_matrix"], separators=(",", ":"))
                    report_values_present &= compact_confusion in final_report
            for metric_name in REQUIRED_METRICS:
                report_values_present &= repr(record[metric_name]) in final_report
    assertions["saved_metrics_match_final_report_and_confusion_arithmetic"] = (
        report_values_present and arithmetic_valid
    )
    require(assertions["saved_metrics_match_final_report_and_confusion_arithmetic"], "Reported results differ from saved metrics or confusion arithmetic.")
    assertions["all_negative_baseline_detects_no_positive_samples"] = baseline_valid
    require(baseline_valid, "All-negative baseline has a positive prediction.")

    limitation_text = (final_report + "\n" + alignment_report).lower()
    assertions["critical_scientific_limitations_are_explicit"] = all(
        marker in limitation_text
        for marker in (
            "only 11 positive",
            "release-order",
            "java class-level",
            "not predictions for the ten selected github repositories",
            "production ready",
            "low",
            "feature-vector overlap",
        )
    )
    require(assertions["critical_scientific_limitations_are_explicit"], "A required scientific limitation is absent.")
    assertions["proposal_alignment_and_implementation_status_documented"] = all(
        marker in alignment_report
        for marker in (
            "IMPLEMENTED",
            "PARTIALLY ADDRESSED",
            "NOT YET IMPLEMENTED",
            "Commit frequency",
            "Changed lines",
            "Contributor count",
            "Bug history",
            "Static-analysis indicators",
            "CI/CD failure links",
        )
    )
    require(assertions["proposal_alignment_and_implementation_status_documented"], "Proposal alignment report is incomplete.")
    assertions["dataset_attribution_and_license_present"] = (
        "https://zenodo.org/records/4625975" in final_report
        and "CC BY 4.0" in final_report
        and "Alhusain" in final_report
    )
    require(assertions["dataset_attribution_and_license_present"], "Dataset attribution/license is missing.")

    required_scripts = (
        "02_validate_versioned_promise.py",
        "02_prepare_splits.py",
        "02_verify_splits.py",
        "03_train_models.py",
        "03_verify_training.py",
        "04_evaluate_models.py",
        "04_verify_evaluation.py",
        "05_verify_package.py",
    )
    assertions["reproducibility_guide_references_existing_commands"] = all(
        name in readme and (RQ1 / "scripts" / name).is_file()
        for name in required_scripts
    )
    require(assertions["reproducibility_guide_references_existing_commands"], "README references a missing command or script.")
    assertions["git_ignored_artifact_policy_is_documented_and_effective"] = (
        all(
            marker in readme.lower()
            for marker in ("git-ignored", "zenodo", "regenerate", "serialized `*.joblib` models")
        )
        and all(
            subprocess.run(
                ["git", "check-ignore", "-q", str(path.relative_to(ROOT))],
                cwd=ROOT,
                check=False,
            ).returncode
            == 0
            for path in (
                workbook_path,
                RQ1 / "datasets" / "processed" / "train.csv",
                RQ1 / "models" / "random_forest.joblib",
                RQ1 / ".venv" / "pyvenv.cfg",
                prediction_path,
                figures_dir / FIGURES[0],
            )
        )
    )
    require(assertions["git_ignored_artifact_policy_is_documented_and_effective"], "Git ignore policy is missing or ineffective.")

    figure_hashes = {
        name: sha256_file(figures_dir / name)
        for name in FIGURES
        if (figures_dir / name).is_file()
    }
    assertions["all_required_evaluation_figures_exist"] = set(figure_hashes) == set(FIGURES)
    require(assertions["all_required_evaluation_figures_exist"], "One or more evaluation figures are missing.")

    changed = git_names("diff", "--name-only")
    staged = git_names("diff", "--cached", "--name-only")
    assertions["no_tracked_or_staged_files_changed"] = not changed and not staged
    require(assertions["no_tracked_or_staged_files_changed"], "Tracked or staged changes were found.")
    step5_files = [
        readme_path,
        final_report_path,
        alignment_path,
        package_manifest_path,
        RQ1 / "scripts" / "05_verify_package.py",
    ]
    secret_pattern = re.compile(
        r"(?:gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|"
        r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----)"
    )
    assertions["step5_deliverables_contain_no_common_secret_patterns"] = all(
        secret_pattern.search(path.read_text(encoding="utf-8")) is None
        for path in step5_files
    )
    require(assertions["step5_deliverables_contain_no_common_secret_patterns"], "A credential-like pattern was found.")

    versions = {
        package: importlib.metadata.version(package)
        for package in ("numpy", "pandas", "scikit-learn", "xgboost", "joblib", "matplotlib")
    }
    assertions["runtime_environment_matches_recorded_manifest"] = (
        sys.version.split()[0] == package_manifest["environment"]["python"]
        and versions == package_manifest["environment"]["packages"]
    )
    require(assertions["runtime_environment_matches_recorded_manifest"], "Runtime environment differs from the package manifest.")

    return {
        "status": "PASS" if all(assertions.values()) else "FAIL",
        "assertion_count": len(assertions),
        "assertions": assertions,
        "prerequisite_verifiers": {
            "step1": {
                "validator_exit": 0,
                "core_assertions_true": sum(
                    value is True
                    for key, value in step1_assertions.items()
                    if key != "no_conflicting_feature_vectors_within_release"
                ),
                "known_conflicting_vector_warning": True,
            },
            "step2": {"status": step2["status"], "assertion_count": len(step2["assertions"])},
            "step3": {"status": step3["status"], "assertion_count": len(step3["assertions"])},
            "step4": {
                "status": "PASS",
                "assertion_count": 25,
                "evidence": "verified separately; Step 5 reads its report without rerunning its output-writing evaluator",
            },
        },
        "source_sha256": {
            "workbook": WORKBOOK_SHA256,
            **{f"{split}_csv": digest for split, digest in actual_split_hashes.items()},
            **{f"{name}_model": digest for name, digest in actual_model_hashes.items()},
            "metrics_json": sha256_file(metrics_path),
        },
        "test_results": {
            "rows": cohort_by_name["test"]["sample_count"],
            "class_counts": cohort_by_name["test"]["class_counts"],
            "threshold": threshold,
            "figures_verified": sorted(figure_hashes),
        },
        "git": {"tracked_changes": changed, "staged_changes": staged},
    }


def main() -> int:
    try:
        result = verify()
    except (AssertionError, KeyError, OSError, RuntimeError, ValueError) as error:
        print(json.dumps({"status": "FAIL", "error": str(error)}, indent=2))
        return 1
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

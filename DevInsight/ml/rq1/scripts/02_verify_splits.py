#!/usr/bin/env python3
"""Independently verify prepared JEdit release partitions and provenance."""

from __future__ import annotations

import argparse
import csv
import importlib.util
import json
import math
import sys
from collections import Counter
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
PREPARER_PATH = Path(__file__).with_name("02_prepare_splits.py")
_SPEC = importlib.util.spec_from_file_location("rq1_split_preparer", PREPARER_PATH)
if _SPEC is None or _SPEC.loader is None:
    raise ImportError(f"Unable to load split preparation module at {PREPARER_PATH}")
_PREPARER = importlib.util.module_from_spec(_SPEC)
sys.modules[_SPEC.name] = _PREPARER
_SPEC.loader.exec_module(_PREPARER)


def _read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open("r", encoding="utf-8", newline="") as source:
        reader = csv.DictReader(source)
        if reader.fieldnames is None:
            raise AssertionError(f"Missing CSV header in {path}")
        return list(reader.fieldnames), list(reader)


def _check_numeric_rows(
    rows: list[dict[str, str]], split_name: str
) -> list[dict[str, Any]]:
    parsed: list[dict[str, Any]] = []
    for row_index, row in enumerate(rows, start=2):
        for feature in _PREPARER.FEATURES:
            raw = row.get(feature)
            if raw is None or raw == "":
                raise AssertionError(
                    f"Missing {feature} in {split_name}.csv row {row_index}"
                )
            try:
                value = Decimal(raw)
            except InvalidOperation as error:
                raise AssertionError(
                    f"Nonnumeric {feature} in {split_name}.csv row {row_index}"
                ) from error
            if not value.is_finite() or not math.isfinite(float(value)):
                raise AssertionError(
                    f"Non-finite {feature} in {split_name}.csv row {row_index}"
                )
        target = row.get(_PREPARER.TARGET)
        if target not in _PREPARER.LABELS:
            raise AssertionError(
                f"Invalid target {target!r} in {split_name}.csv row {row_index}"
            )
        parsed.append(
            {
                "feature_vector": tuple(
                    Decimal(row[feature]) for feature in _PREPARER.FEATURES
                ),
                "target": target,
            }
        )
    return parsed


def verify(
    workbook_path: Path, output_dir: Path, manifest_path: Path
) -> dict[str, Any]:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    source = _PREPARER.load_selected_source(workbook_path)
    expected_releases = _PREPARER.SPLITS
    assertions: dict[str, bool] = {}

    assertions["workbook_sha256_matches_step1"] = (
        _PREPARER.sha256_file(workbook_path)
        == _PREPARER.EXPECTED_WORKBOOK_SHA256
        == manifest["source_workbook_sha256"]
    )
    if not assertions["workbook_sha256_matches_step1"]:
        raise AssertionError("Raw workbook checksum mismatch.")

    assignments = manifest["split_assignments"]
    actual_assignment = {
        entry["release_sheet"]: entry["split"] for entry in assignments
    }
    assertions["exact_release_to_split_assignments"] = (
        actual_assignment == expected_releases
    )
    if not assertions["exact_release_to_split_assignments"]:
        raise AssertionError(f"Unexpected assignments: {actual_assignment}")
    assertions["unused_releases_excluded"] = manifest["unused_releases"] == [
        "jedit_3_2_1",
        "jedit_4_0",
    ]
    if not assertions["unused_releases_excluded"]:
        raise AssertionError("Unused releases were not recorded correctly.")

    traceability = manifest["traceability_rows"]
    trace_keys = [
        (row["source_sheet"], row["source_row_index"])
        for row in traceability
    ]
    assertions["no_source_row_in_multiple_partitions"] = (
        len(trace_keys) == len(set(trace_keys))
    )
    if not assertions["no_source_row_in_multiple_partitions"]:
        raise AssertionError("A source row occurs more than once in the manifest.")
    assertions["traceability_assignments_match"] = all(
        row["split_assignment"] == expected_releases[row["source_sheet"]]
        for row in traceability
    )
    if not assertions["traceability_assignments_match"]:
        raise AssertionError("Traceability rows contain unexpected split assignments.")

    source_hash_before = _PREPARER.sha256_file(workbook_path)
    csv_data: dict[str, list[dict[str, Any]]] = {}
    for sheet, split_name in expected_releases.items():
        expected_rows = source[sheet]
        output_path = output_dir / f"{split_name}.csv"
        if not output_path.is_file():
            raise AssertionError(f"Missing split output: {output_path}")
        headers, rows = _read_csv(output_path)
        expected_headers = [*_PREPARER.FEATURES, _PREPARER.TARGET]
        if headers != expected_headers:
            raise AssertionError(f"Unexpected columns in {output_path}: {headers}")
        parsed_rows = _check_numeric_rows(rows, split_name)
        csv_data[split_name] = parsed_rows
        expected_counts = _PREPARER._label_counts(expected_rows)
        actual_counts = Counter(row["target"] for row in parsed_rows)
        actual_counts_dict = {
            label: actual_counts.get(label, 0) for label in ("0", "1")
        }
        if len(rows) != len(expected_rows):
            raise AssertionError(
                f"{split_name} row count {len(rows)} != source {len(expected_rows)}"
            )
        if actual_counts_dict != expected_counts:
            raise AssertionError(
                f"{split_name} class counts {actual_counts_dict} != "
                f"source {expected_counts}"
            )
        for actual, expected in zip(parsed_rows, expected_rows, strict=True):
            if actual["feature_vector"] != expected["feature_vector"]:
                raise AssertionError(
                    f"Feature values/order mismatch in {split_name}."
                )
            if actual["target"] != expected["target"]:
                raise AssertionError(f"Target changed in {split_name}.")
        manifest_output = manifest["outputs"][split_name]
        if _PREPARER.sha256_file(output_path) != manifest_output["sha256"]:
            raise AssertionError(f"Output checksum mismatch for {split_name}.")
        if manifest_output["rows"] != len(expected_rows):
            raise AssertionError(f"Manifest row count mismatch for {split_name}.")

        release_trace = [
            row for row in traceability if row["source_sheet"] == sheet
        ]
        expected_trace = [
            (
                row["source_row_index"],
                row["class_name"],
                expected_releases[sheet],
            )
            for row in expected_rows
        ]
        actual_trace = [
            (
                row["source_row_index"],
                row["class_name"],
                row["split_assignment"],
            )
            for row in release_trace
        ]
        if actual_trace != expected_trace:
            raise AssertionError(f"Source-row traceability mismatch for {sheet}.")

    assertions["correct_source_row_counts"] = all(
        len(csv_data[split]) == len(source[sheet])
        for sheet, split in expected_releases.items()
    )
    assertions["class_distributions_match_source"] = all(
        manifest["source_rows_by_release"][sheet]["class_counts"]
        == _PREPARER._label_counts(source[sheet])
        for sheet in expected_releases
    )
    assertions["six_numeric_features_and_target_only"] = all(
        list(_read_csv(output_dir / f"{split}.csv")[0])
        == [*_PREPARER.FEATURES, _PREPARER.TARGET]
        for split in expected_releases.values()
    )
    assertions["consistent_binary_target_domain"] = all(
        row["target"] in _PREPARER.LABELS
        for rows in csv_data.values()
        for row in rows
    )
    assertions["no_missing_or_nonfinite_values"] = True
    assertions["no_identifier_in_model_features"] = all(
        _PREPARER.IDENTIFIER not in _read_csv(
            output_dir / f"{split}.csv"
        )[0]
        for split in expected_releases.values()
    )
    assertions["no_source_rows_removed_or_created"] = all(
        [
            (row["source_row_index"], row["class_name"])
            for row in traceability
            if row["source_sheet"] == sheet
        ]
        == [
            (row["source_row_index"], row["class_name"])
            for row in source[sheet]
        ]
        for sheet in expected_releases
    )
    assertions["original_workbook_unchanged"] = (
        source_hash_before == _PREPARER.sha256_file(workbook_path)
    )
    assertions["input_and_script_hashes_reproducible"] = (
        manifest["source_workbook_sha256"] == source_hash_before
        and manifest["script_configuration"]["preparation_script_sha256"]
        == _PREPARER.sha256_file(PREPARER_PATH)
        and manifest["script_configuration"]["validator_script_sha256"]
        == _PREPARER.sha256_file(_PREPARER.VALIDATOR_PATH)
    )
    actual_audit = _PREPARER.build_audit(source)
    assertions["overlap_warnings_accurately_reported"] = (
        actual_audit == manifest["vector_overlap_audit"]
    )
    expected_novel_rows = [
        row
        for row in source["jedit_4_3"]
        if row["feature_vector"]
        not in {
            item["feature_vector"]
            for sheet in ("jedit_4_1", "jedit_4_2")
            for item in source[sheet]
        }
    ]
    diagnostic = manifest["diagnostic_test_subset"]
    assertions["diagnostic_subset_matches_definition"] = (
        diagnostic["rows"] == len(expected_novel_rows)
        and diagnostic["class_counts"]
        == _PREPARER._label_counts(expected_novel_rows)
        and diagnostic["primary_test_unchanged"] is True
    )
    assertions["no_models_or_model_metrics"] = (
        manifest["models_trained"] is False
        and manifest["model_metrics_generated"] is False
        and diagnostic["model_metrics_generated"] is False
    )
    if not all(assertions.values()):
        raise AssertionError(
            "Verification assertion failed: "
            + ", ".join(name for name, passed in assertions.items() if not passed)
        )
    return {
        "status": "PASS",
        "assertions": assertions,
        "split_rows": {
            split: len(rows) for split, rows in csv_data.items()
        },
        "class_counts": {
            split: {
                label: sum(row["target"] == label for row in rows)
                for label in ("0", "1")
            }
            for split, rows in csv_data.items()
        },
        "output_sha256": {
            split: manifest["outputs"][split]["sha256"] for split in csv_data
        },
        "vector_overlap_audit": actual_audit,
        "diagnostic_test_subset": diagnostic,
        "models_trained": False,
        "model_metrics_generated": False,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--workbook",
        type=Path,
        default=ROOT / "ml" / "rq1" / "datasets" / "raw"
        / "promise_regenerated_candidates.xlsx",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=ROOT / "ml" / "rq1" / "datasets" / "processed",
    )
    parser.add_argument(
        "--manifest",
        type=Path,
        default=ROOT / "ml" / "rq1" / "reports" / "step02_split_manifest.json",
    )
    arguments = parser.parse_args()
    result = verify(arguments.workbook, arguments.output_dir, arguments.manifest)
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

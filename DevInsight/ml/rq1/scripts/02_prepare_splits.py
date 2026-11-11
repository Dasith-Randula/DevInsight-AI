#!/usr/bin/env python3
"""Prepare fixed release-order JEdit partitions without fitting transformations."""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.util
import json
import math
import sys
import zipfile
from collections import Counter, defaultdict
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any
from xml.etree import ElementTree


SCRIPT_VERSION = "1.0.0"
EXPECTED_WORKBOOK_SHA256 = (
    "364ab30e660ba3d78644ac717d28bb224e03648f9ad06b42a3453daee2ae0c31"
)
SOURCE_URL = "https://zenodo.org/records/4625975"
PROJECT = "jedit"
IDENTIFIER = "ClassName"
TARGET = "Defect"
FEATURES = [
    "CBO",
    "DCC",
    "ExportCoupling",
    "ImportCoupling",
    "NOM",
    "WMC",
]
EXPECTED_HEADERS = [IDENTIFIER, *FEATURES, TARGET]
SPLITS = {
    "jedit_4_1": "train",
    "jedit_4_2": "validation",
    "jedit_4_3": "test",
}
LABELS = {"0", "1"}
MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
ROOT = Path(__file__).resolve().parents[3]
VALIDATOR_PATH = Path(__file__).with_name("02_validate_versioned_promise.py")
_VALIDATOR_SPEC = importlib.util.spec_from_file_location(
    "rq1_versioned_promise_validator", VALIDATOR_PATH
)
if _VALIDATOR_SPEC is None or _VALIDATOR_SPEC.loader is None:
    raise ImportError(f"Unable to load workbook parser at {VALIDATOR_PATH}")
_VALIDATOR = importlib.util.module_from_spec(_VALIDATOR_SPEC)
sys.modules[_VALIDATOR_SPEC.name] = _VALIDATOR
_VALIDATOR_SPEC.loader.exec_module(_VALIDATOR)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _sheet_row_numbers(path: Path, selected_sheets: set[str]) -> dict[str, list[int]]:
    namespaces = {
        "main": MAIN_NS,
        "rel": REL_NS,
        "package": PKG_REL_NS,
    }
    with zipfile.ZipFile(path) as workbook:
        workbook_xml = ElementTree.fromstring(workbook.read("xl/workbook.xml"))
        relationships = ElementTree.fromstring(
            workbook.read("xl/_rels/workbook.xml.rels")
        )
        targets = {
            relationship.get("Id"): relationship.get("Target")
            for relationship in relationships.findall(
                f"{{{PKG_REL_NS}}}Relationship"
            )
        }
        row_numbers: dict[str, list[int]] = {}
        for sheet in workbook_xml.findall(".//main:sheet", namespaces):
            name = sheet.get("name")
            if name not in selected_sheets:
                continue
            target = targets.get(sheet.get(f"{{{REL_NS}}}id"))
            if name is None or target is None:
                raise ValueError(f"Cannot resolve worksheet path for {name!r}.")
            sheet_path = target.lstrip("/")
            if not sheet_path.startswith("xl/"):
                sheet_path = f"xl/{sheet_path}"
            root = ElementTree.fromstring(workbook.read(sheet_path))
            rows = root.findall(".//main:sheetData/main:row", namespaces)
            numbers = [int(row.get("r", "0")) for row in rows]
            if not numbers or numbers[0] != 1:
                raise ValueError(f"{name} must have its header on Excel row 1.")
            if numbers[1:] != list(range(2, len(numbers) + 1)):
                raise ValueError(f"{name} has non-contiguous source row numbers.")
            row_numbers[name] = numbers[1:]
        if row_numbers.keys() != selected_sheets:
            missing = sorted(selected_sheets - row_numbers.keys())
            raise ValueError(f"Missing worksheet row numbers for: {missing}")
        return row_numbers


def _numeric_value(raw: str | None, sheet: str, row_index: int, column: str) -> Decimal:
    if raw is None or raw == "":
        raise ValueError(f"Missing {column} in {sheet} source row {row_index}.")
    try:
        value = Decimal(raw)
    except InvalidOperation as error:
        raise ValueError(
            f"Nonnumeric {column} in {sheet} source row {row_index}: {raw!r}"
        ) from error
    if not value.is_finite() or not math.isfinite(float(value)):
        raise ValueError(
            f"Non-finite {column} in {sheet} source row {row_index}: {raw!r}"
        )
    return value


def load_selected_source(workbook_path: Path) -> dict[str, list[dict[str, Any]]]:
    if not workbook_path.is_file():
        raise FileNotFoundError(f"Raw workbook not found: {workbook_path}")
    workbook_hash = sha256_file(workbook_path)
    if workbook_hash != EXPECTED_WORKBOOK_SHA256:
        raise ValueError(
            "Workbook SHA-256 differs from the Step 1 verified source: "
            f"{workbook_hash}"
        )
    all_sheets = _VALIDATOR._read_workbook(workbook_path)
    source_rows = _sheet_row_numbers(workbook_path, set(SPLITS))
    selected: dict[str, list[dict[str, Any]]] = {}
    for sheet_name, split_name in SPLITS.items():
        if sheet_name not in all_sheets:
            raise ValueError(f"Required release {sheet_name!r} is absent.")
        rows = all_sheets[sheet_name]
        if not rows or list(rows[0]) != EXPECTED_HEADERS:
            actual = list(rows[0]) if rows else []
            raise ValueError(
                f"Unexpected schema in {sheet_name}: expected {EXPECTED_HEADERS}, "
                f"found {actual}"
            )
        if len(rows) != len(source_rows[sheet_name]):
            raise ValueError(f"Source row index count mismatch in {sheet_name}.")
        prepared: list[dict[str, Any]] = []
        for row, row_index in zip(rows, source_rows[sheet_name], strict=True):
            if set(row) != set(EXPECTED_HEADERS):
                raise ValueError(f"Unexpected columns in {sheet_name} row {row_index}.")
            identifier = row.get(IDENTIFIER)
            target = row.get(TARGET)
            if identifier is None or identifier.strip() == "":
                raise ValueError(
                    f"Missing {IDENTIFIER} in {sheet_name} source row {row_index}."
                )
            if target not in LABELS:
                raise ValueError(
                    f"Invalid {TARGET}={target!r} in {sheet_name} "
                    f"source row {row_index}."
                )
            feature_values = {
                name: _numeric_value(row.get(name), sheet_name, row_index, name)
                for name in FEATURES
            }
            prepared.append(
                {
                    "sheet": sheet_name,
                    "split": split_name,
                    "source_row_index": row_index,
                    "class_name": identifier,
                    "features_raw": {name: row[name] for name in FEATURES},
                    "feature_vector": tuple(feature_values[name] for name in FEATURES),
                    "target": target,
                }
            )
        selected[sheet_name] = prepared
    return selected


def _label_counts(rows: list[dict[str, Any]]) -> dict[str, int]:
    counts = Counter(row["target"] for row in rows)
    return {label: counts.get(label, 0) for label in ("0", "1")}


def audit_vectors(
    left: list[dict[str, Any]], right: list[dict[str, Any]] | None = None
) -> dict[str, int]:
    if right is None:
        groups: dict[tuple[Decimal, ...], list[str]] = defaultdict(list)
        for row in left:
            groups[row["feature_vector"]].append(row["target"])
        duplicate_groups = [labels for labels in groups.values() if len(labels) > 1]
        identical_pairs = sum(
            sum(1 for i, label in enumerate(labels) for other in labels[i + 1 :] if label == other)
            for labels in duplicate_groups
        )
        conflicting_pairs = sum(
            sum(1 for i, label in enumerate(labels) for other in labels[i + 1 :] if label != other)
            for labels in duplicate_groups
        )
        return {
            "repeated_feature_vector_excess_rows": len(left) - len(groups),
            "unique_repeated_feature_vectors": len(duplicate_groups),
            "feature_vector_occurrence_pairs": sum(
                len(labels) * (len(labels) - 1) // 2 for labels in duplicate_groups
            ),
            "identical_label_matches": identical_pairs,
            "conflicting_label_matches": conflicting_pairs,
            "unique_overlapping_vectors": len(duplicate_groups),
            "rows_matching_another_row": sum(
                len(labels) for labels in duplicate_groups
            ),
        }

    left_groups: dict[tuple[Decimal, ...], list[str]] = defaultdict(list)
    right_groups: dict[tuple[Decimal, ...], list[str]] = defaultdict(list)
    for row in left:
        left_groups[row["feature_vector"]].append(row["target"])
    for row in right:
        right_groups[row["feature_vector"]].append(row["target"])
    common = set(left_groups) & set(right_groups)
    identical_pairs = 0
    conflicting_pairs = 0
    occurrence_pairs = 0
    for vector in common:
        left_labels = left_groups[vector]
        right_labels = right_groups[vector]
        occurrence_pairs += len(left_labels) * len(right_labels)
        identical_pairs += sum(
            left_label == right_label
            for left_label in left_labels
            for right_label in right_labels
        )
        conflicting_pairs += sum(
            left_label != right_label
            for left_label in left_labels
            for right_label in right_labels
        )
    return {
        "repeated_feature_vector_excess_rows": sum(
            len(left_groups[vector]) + len(right_groups[vector]) - 2
            for vector in common
        ),
        "unique_repeated_feature_vectors": len(common),
        "feature_vector_occurrence_pairs": occurrence_pairs,
        "identical_label_matches": identical_pairs,
        "conflicting_label_matches": conflicting_pairs,
        "unique_overlapping_vectors": len(common),
        "rows_matching_another_row": sum(
            len(left_groups[vector]) + len(right_groups[vector]) for vector in common
        ),
    }


def build_audit(
    selected: dict[str, list[dict[str, Any]]]
) -> dict[str, dict[str, int]]:
    split_rows = {split: selected[sheet] for sheet, split in SPLITS.items()}
    audit: dict[str, dict[str, int]] = {}
    for split_name, rows in split_rows.items():
        audit[f"within_{split_name}"] = audit_vectors(rows)
    split_names = list(split_rows)
    for left_index, left_name in enumerate(split_names):
        for right_name in split_names[left_index + 1 :]:
            audit[f"{left_name}_vs_{right_name}"] = audit_vectors(
                split_rows[left_name], split_rows[right_name]
            )
    return audit


def _write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=[*FEATURES, TARGET], lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow(
                {
                    **row["features_raw"],
                    TARGET: row["target"],
                }
            )


def prepare(workbook_path: Path, output_dir: Path, manifest_path: Path) -> dict[str, Any]:
    selected = load_selected_source(workbook_path)
    split_rows = {split: selected[sheet] for sheet, split in SPLITS.items()}
    for split_name, rows in split_rows.items():
        counts = _label_counts(rows)
        if not rows or not all(counts[label] > 0 for label in LABELS):
            raise ValueError(
                f"{split_name} has an unusable class distribution: {counts}"
            )

    output_dir.mkdir(parents=True, exist_ok=True)
    csv_paths = {
        split_name: output_dir / f"{split_name}.csv"
        for split_name in split_rows
    }
    for split_name, rows in split_rows.items():
        _write_csv(csv_paths[split_name], rows)

    selected_counts = {
        sheet: {
            "rows": len(rows),
            "class_counts": _label_counts(rows),
            "source_row_indices": [row["source_row_index"] for row in rows],
        }
        for sheet, rows in selected.items()
    }
    provenance_rows = [
        {
            "source_sheet": row["sheet"],
            "source_row_index": row["source_row_index"],
            "class_name": row["class_name"],
            "split_assignment": row["split"],
        }
        for sheet in SPLITS
        for row in selected[sheet]
    ]
    train_and_validation_vectors = {
        row["feature_vector"]
        for sheet in ("jedit_4_1", "jedit_4_2")
        for row in selected[sheet]
    }
    test_rows = selected["jedit_4_3"]
    novel_test_rows = [
        row
        for row in test_rows
        if row["feature_vector"] not in train_and_validation_vectors
    ]
    manifest: dict[str, Any] = {
        "manifest_version": 1,
        "dataset": "Regenerated PROMISE/BPD JEdit",
        "dataset_version": "Zenodo record 4625975, version 1",
        "source_url": SOURCE_URL,
        "source_workbook": str(workbook_path.resolve()),
        "source_workbook_sha256": sha256_file(workbook_path),
        "source_workbook_size_bytes": workbook_path.stat().st_size,
        "source_row_index_definition": (
            "1-based Excel worksheet row number; header is row 1; data starts at row 2"
        ),
        "feature_columns": FEATURES,
        "target_column": TARGET,
        "target_definition": (
            "Defect=1 means at least one recorded defect; Defect=0 means zero "
            "recorded defects, as documented by Alhusain (2021)."
        ),
        "prediction_unit": "Java class within a JEdit release",
        "split_assignments": [
            {
                "release_sheet": sheet,
                "split": split,
                "rows": selected_counts[sheet]["rows"],
                "class_counts": selected_counts[sheet]["class_counts"],
            }
            for sheet, split in SPLITS.items()
        ],
        "unused_releases": ["jedit_3_2_1", "jedit_4_0"],
        "release_order_note": (
            "Release-order holdout based on version identifiers; not a verified "
            "calendar-time split."
        ),
        "processing_policy": {
            "row_removal": "None; all selected release rows are retained.",
            "deduplication": "None; repeated and conflicting feature vectors are retained.",
            "identifier": "ClassName is stored in this manifest only, never in model CSVs.",
            "numeric_validation": "All six raw numeric source values must be finite.",
            "missing_values": (
                "None observed in selected releases; no imputation was performed."
            ),
            "scaling": "None; no transformation was fitted or applied.",
            "target_handling": "Original binary Defect values retained unchanged.",
        },
        "script_configuration": {
            "script_version": SCRIPT_VERSION,
            "preparation_script": str(Path(__file__).resolve()),
            "preparation_script_sha256": sha256_file(Path(__file__)),
            "validator_script": str(VALIDATOR_PATH.resolve()),
            "validator_script_sha256": sha256_file(VALIDATOR_PATH),
        },
        "source_rows_by_release": selected_counts,
        "traceability_rows": provenance_rows,
        "vector_overlap_audit": build_audit(selected),
        "diagnostic_test_subset": {
            "definition": (
                "jedit_4_3 records whose six-feature vector is absent from both "
                "selected training and validation releases"
            ),
            "rows": len(novel_test_rows),
            "class_counts": _label_counts(novel_test_rows),
            "primary_test_unchanged": True,
            "model_metrics_generated": False,
        },
        "outputs": {
            split_name: {
                "path": str(path.resolve()),
                "rows": len(split_rows[split_name]),
                "columns": [*FEATURES, TARGET],
                "sha256": sha256_file(path),
                "size_bytes": path.stat().st_size,
            }
            for split_name, path in csv_paths.items()
        },
        "models_trained": False,
        "model_metrics_generated": False,
    }
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return manifest


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
    manifest = prepare(arguments.workbook, arguments.output_dir, arguments.manifest)
    summary = {
        "source_workbook_sha256": manifest["source_workbook_sha256"],
        "splits": {
            item["split"]: {
                "release": item["release_sheet"],
                "rows": item["rows"],
                "class_counts": item["class_counts"],
                "output_sha256": manifest["outputs"][item["split"]]["sha256"],
            }
            for item in manifest["split_assignments"]
        },
        "vector_overlap_audit": manifest["vector_overlap_audit"],
        "diagnostic_test_subset": manifest["diagnostic_test_subset"],
        "manifest": str(arguments.manifest.resolve()),
        "models_trained": manifest["models_trained"],
        "model_metrics_generated": manifest["model_metrics_generated"],
    }
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Inspect the selected raw ARFF benchmark without transforming or splitting it."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from collections import Counter, defaultdict
from decimal import Decimal, InvalidOperation
from io import StringIO
from pathlib import Path
from typing import Any


DEFAULT_DATASET = (
    Path(__file__).resolve().parents[1] / "datasets" / "raw" / "jm1.arff"
)
ATTRIBUTE_RE = re.compile(
    r"""^@attribute\s+(?:'([^']+)'|"([^"]+)"|(\S+))\s+(.+)$""", re.IGNORECASE
)
IDENTIFIER_RE = re.compile(
    r"(?:^|[_\W])(project|repository|version|release|module|file|path|date|time|"
    r"timestamp|commit|sha|id)(?:$|[_\W])",
    re.IGNORECASE,
)
SUSPICIOUS_RE = re.compile(
    r"(?:^|[_\W])(bug|defect|fault|label|target|fix|post|after)(?:$|[_\W])",
    re.IGNORECASE,
)


def parse_arff(path: Path) -> tuple[str | None, list[tuple[str, str]], list[list[str]]]:
    text = path.read_text(encoding="utf-8-sig")
    relation: str | None = None
    attributes: list[tuple[str, str]] = []
    data_rows: list[list[str]] = []
    in_data = False

    for line_number, raw_line in enumerate(text.splitlines(), start=1):
        line = raw_line.strip()
        if not line or line.startswith("%"):
            continue
        if not in_data:
            if line.lower().startswith("@relation"):
                relation = line[len("@relation") :].strip().strip("'\"")
            elif line.lower().startswith("@attribute"):
                match = ATTRIBUTE_RE.match(line)
                if match is None:
                    raise ValueError(f"Unrecognized ARFF attribute at line {line_number}")
                name = next(part for part in match.groups()[:3] if part is not None)
                attributes.append((name, match.group(4).strip()))
            elif line.lower() == "@data":
                in_data = True
            continue

        parsed = next(csv.reader([line], skipinitialspace=True))
        if len(parsed) != len(attributes):
            raise ValueError(
                f"Row at line {line_number} has {len(parsed)} values; "
                f"expected {len(attributes)}"
            )
        data_rows.append([value.strip() for value in parsed])

    if not in_data or not attributes:
        raise ValueError("ARFF relation, attributes, or @data section is missing")
    return relation, attributes, data_rows


def canonical_value(value: str, declaration: str) -> Any:
    if value == "?":
        return None
    if declaration.lower() in {"numeric", "real", "integer"}:
        try:
            number = Decimal(value)
        except InvalidOperation as error:
            raise ValueError(f"Invalid numeric value: {value!r}") from error
        if not number.is_finite():
            raise ValueError(f"Non-finite numeric value: {value!r}")
        return number.normalize()
    return value.casefold()


def validate(path: Path, positive_label: str | None) -> dict[str, Any]:
    raw_bytes = path.read_bytes()
    text = raw_bytes.decode("utf-8-sig")
    relation, attributes, rows = parse_arff(path)
    column_names = [name for name, _ in attributes]
    target_column = next(
        (name for name in column_names if name.casefold() == "defects"), None
    )
    if target_column is None:
        raise ValueError("Expected binary target column 'defects' was not found")
    target_index = column_names.index(target_column)
    declarations = [declaration for _, declaration in attributes]

    missing_by_column = {
        name: sum(row[index] in {"?", ""} for row in rows)
        for index, name in enumerate(column_names)
    }
    unique_by_column = {
        name: len({row[index] for row in rows if row[index] not in {"?", ""}})
        for index, name in enumerate(column_names)
    }
    constants = [name for name, count in unique_by_column.items() if count <= 1]
    numeric_columns = [
        name
        for name, declaration in attributes
        if declaration.lower() in {"numeric", "real", "integer"}
    ]
    categorical_columns = [name for name in column_names if name not in numeric_columns]

    exact_counter: Counter[tuple[Any, ...]] = Counter()
    feature_counter: Counter[tuple[Any, ...]] = Counter()
    feature_labels: dict[tuple[Any, ...], set[str]] = defaultdict(set)
    feature_indices = [i for i in range(len(attributes)) if i != target_index]
    for row in rows:
        normalized = tuple(
            canonical_value(value, declarations[index])
            for index, value in enumerate(row)
        )
        exact_counter[normalized] += 1
        feature_key = tuple(
            canonical_value(row[index], declarations[index])
            for index in feature_indices
        )
        feature_counter[feature_key] += 1
        if row[target_index] not in {"?", ""}:
            feature_labels[feature_key].add(row[target_index].casefold())

    duplicate_exact_excess = sum(count - 1 for count in exact_counter.values() if count > 1)
    duplicate_feature_excess = sum(
        count - 1 for count in feature_counter.values() if count > 1
    )
    conflicting_duplicate_groups = sum(
        len(feature_labels[key]) > 1 for key, count in feature_counter.items() if count > 1
    )

    target_declaration = declarations[target_index]
    target_domain_match = re.fullmatch(r"\{(.*)\}", target_declaration)
    declared_target_values = (
        [value.strip().strip("'\"") for value in target_domain_match.group(1).split(",")]
        if target_domain_match
        else []
    )
    target_counts = Counter(
        row[target_index].strip().strip("'\"").casefold()
        for row in rows
        if row[target_index] not in {"?", ""}
    )
    unexpected_target_values = sorted(
        set(target_counts) - {value.casefold() for value in declared_target_values}
    )
    if unexpected_target_values:
        raise ValueError(f"Target values outside the declared domain: {unexpected_target_values}")
    if set(value.casefold() for value in declared_target_values) != {"false", "true"}:
        raise ValueError("Expected the target domain to be exactly {false,true}")
    if not target_counts.get("false") or not target_counts.get("true"):
        raise ValueError("Both false and true target classes must be represented")
    target_total = sum(target_counts.values())
    positive_value = positive_label.casefold() if positive_label is not None else None
    if positive_value is not None and positive_value not in target_counts:
        raise ValueError(f"Positive label {positive_label!r} is not present in the target")
    positive_count = target_counts.get(positive_value) if positive_value is not None else None
    negative_count = (
        target_total - positive_count if positive_count is not None else None
    )
    majority_count = max(target_counts.values())
    minority_count = min(target_counts.values())

    identifiers = [name for name in column_names if IDENTIFIER_RE.search(name)]
    suspicious_non_target = [
        name
        for name in column_names
        if name != target_column and SUSPICIOUS_RE.search(name)
    ]
    return {
        "dataset_path": str(path),
        "file_size_bytes": len(raw_bytes),
        "sha256": hashlib.sha256(raw_bytes).hexdigest(),
        "encoding": "UTF-8 (BOM accepted)",
        "arff_parsing": "PASS",
        "relation": relation,
        "row_count": len(rows),
        "column_count_including_target": len(attributes),
        "feature_count": len(attributes) - 1,
        "columns_in_source_order": [
            {"name": name, "declaration": declaration}
            for name, declaration in attributes
        ],
        "numeric_columns": numeric_columns,
        "categorical_columns": categorical_columns,
        "missing_values_by_column": missing_by_column,
        "missing_value_total": sum(missing_by_column.values()),
        "rows_with_missing_values": sum(any(value in {"?", ""} for value in row) for row in rows),
        "constant_columns": constants,
        "exact_duplicate_row_excess": duplicate_exact_excess,
        "duplicate_feature_row_excess_ignoring_target": duplicate_feature_excess,
        "duplicate_feature_groups_with_conflicting_labels": conflicting_duplicate_groups,
        "target": {
            "column": target_column,
            "declaration": target_declaration,
            "declared_values": declared_target_values,
            "observed_distribution": dict(sorted(target_counts.items())),
            "positive_label": positive_value,
            "positive_count": positive_count,
            "negative_count": negative_count,
            "labelled_row_count": target_total,
            "positive_fraction": (
                positive_count / target_total if positive_count is not None and target_total else None
            ),
            "negative_to_positive_ratio": (
                negative_count / positive_count
                if positive_count is not None and positive_count
                else None
            ),
            "majority_to_minority_ratio": (
                majority_count / minority_count if minority_count else None
            ),
            "unexpected_values": unexpected_target_values,
        },
        "row_level_identifiers_detected": identifiers,
        "suspicious_non_target_column_names": suspicious_non_target,
        "project_version_time_leakage_assessment": (
            "Not inferable from columns: no row-level project/version/time identifiers "
            "were detected. The source does not establish when features were measured "
            "relative to defect labeling; semantic/temporal leakage is UNKNOWN."
        ),
        "independent_testing_assessment": (
            "A project-held-out or earlier-version-to-later-version evaluation cannot "
            "be defined from this file because it has no row-level project/version "
            "identifier. No split was created."
        ),
        "cross_version_duplicate_assessment": (
            "Not assessable: no version identifier or linked version files are provided."
        ),
        "preprocessing_performed": False,
        "split_performed": False,
        "model_fitted": False,
        "performance_metrics_calculated": False,
        "source_text_characters": len(text),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--data",
        type=Path,
        default=DEFAULT_DATASET,
        help="Path to the raw ARFF dataset (defaults to the selected JM1 file)",
    )
    parser.add_argument(
        "--positive-label",
        help="Explicitly identify the positive target label only after source semantics are verified",
    )
    args = parser.parse_args()
    report = validate(args.data, args.positive_label)
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

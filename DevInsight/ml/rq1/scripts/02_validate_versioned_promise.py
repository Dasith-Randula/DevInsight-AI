#!/usr/bin/env python3
"""Validate versioned PROMISE sheets in the licensed Zenodo workbook."""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
import zipfile
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any
from xml.etree import ElementTree


MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
TARGET = "Defect"
IDENTIFIER = "ClassName"


def _column_index(reference: str) -> int:
    letters = re.match(r"[A-Z]+", reference)
    if letters is None:
        raise ValueError(f"Invalid spreadsheet cell reference: {reference}")
    index = 0
    for character in letters.group():
        index = index * 26 + ord(character) - ord("A") + 1
    return index - 1


def _read_cell(cell: ElementTree.Element, shared_strings: list[str]) -> str | None:
    cell_type = cell.get("t")
    value = cell.find(f"{{{MAIN_NS}}}v")
    if cell_type == "inlineStr":
        inline = cell.find(f"{{{MAIN_NS}}}is")
        return "".join(inline.itertext()) if inline is not None else ""
    if value is None:
        return None
    if cell_type == "s":
        return shared_strings[int(value.text or "0")]
    return value.text


def _read_workbook(path: Path) -> dict[str, list[dict[str, str | None]]]:
    with zipfile.ZipFile(path) as workbook:
        shared_strings: list[str] = []
        if "xl/sharedStrings.xml" in workbook.namelist():
            strings = ElementTree.fromstring(workbook.read("xl/sharedStrings.xml"))
            shared_strings = [
                "".join(item.itertext())
                for item in strings.findall(f"{{{MAIN_NS}}}si")
            ]

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
        sheets: dict[str, list[dict[str, str | None]]] = {}
        for sheet in workbook_xml.findall(
            f".//{{{MAIN_NS}}}sheet"
        ):
            name = sheet.get("name")
            relationship_id = sheet.get(f"{{{REL_NS}}}id")
            target = targets.get(relationship_id)
            if name is None or target is None:
                raise ValueError("Workbook contains a sheet with no resolvable path.")
            sheet_path = target.lstrip("/")
            if not sheet_path.startswith("xl/"):
                sheet_path = f"xl/{sheet_path}"
            root = ElementTree.fromstring(workbook.read(sheet_path))
            parsed_rows: list[dict[str, str | None]] = []
            raw_rows = root.findall(f".//{{{MAIN_NS}}}sheetData/{{{MAIN_NS}}}row")
            if not raw_rows:
                sheets[name] = parsed_rows
                continue
            header_cells = raw_rows[0].findall(f"{{{MAIN_NS}}}c")
            headers: list[str] = []
            for cell in header_cells:
                column = _column_index(cell.get("r", ""))
                while len(headers) <= column:
                    headers.append("")
                headers[column] = _read_cell(cell, shared_strings) or ""
            for row in raw_rows[1:]:
                values: list[str | None] = [None] * len(headers)
                for cell in row.findall(f"{{{MAIN_NS}}}c"):
                    column = _column_index(cell.get("r", ""))
                    if column < len(headers):
                        values[column] = _read_cell(cell, shared_strings)
                parsed_rows.append(dict(zip(headers, values)))
            sheets[name] = parsed_rows
        return sheets


def _version_key(sheet_name: str, project: str) -> tuple[int, ...]:
    version = sheet_name[len(project) :].lstrip("_-.")
    parts = re.findall(r"\d+", version)
    if not parts:
        raise ValueError(f"Could not identify release version in {sheet_name!r}.")
    return tuple(int(part) for part in parts)


def _feature_key(row: dict[str, str | None], features: list[str]) -> tuple[str | None, ...]:
    return tuple(row[name] for name in features)


def _validate_release(
    sheet_name: str, rows: list[dict[str, str | None]], headers: list[str]
) -> dict[str, Any]:
    if not rows:
        raise ValueError(f"Release {sheet_name} has no data rows.")
    if IDENTIFIER not in headers or TARGET not in headers:
        raise ValueError(
            f"Release {sheet_name} must contain {IDENTIFIER!r} and {TARGET!r}."
        )

    features = [name for name in headers if name not in {IDENTIFIER, TARGET}]
    missing_by_column = {
        column: sum(row.get(column) in (None, "") for row in rows)
        for column in headers
    }
    labels = Counter(row.get(TARGET) for row in rows)
    invalid_labels = sorted(
        str(label) for label in labels if label not in {"0", "1"}
    )
    nonnumeric_features: dict[str, int] = {}
    nonfinite_features: dict[str, int] = {}
    for feature in features:
        bad_values = 0
        nonfinite_values = 0
        for row in rows:
            value = row.get(feature)
            try:
                if value in (None, ""):
                    continue
                numeric_value = float(value)
                if not math.isfinite(numeric_value):
                    nonfinite_values += 1
            except ValueError:
                bad_values += 1
        if bad_values:
            nonnumeric_features[feature] = bad_values
        if nonfinite_values:
            nonfinite_features[feature] = nonfinite_values

    full_rows = [tuple(row.get(column) for column in headers) for row in rows]
    ids: dict[str | None, set[str | None]] = defaultdict(set)
    feature_labels: dict[tuple[str | None, ...], set[str | None]] = defaultdict(set)
    for row in rows:
        ids[row.get(IDENTIFIER)].add(row.get(TARGET))
        feature_labels[_feature_key(row, features)].add(row.get(TARGET))

    return {
        "release": sheet_name,
        "rows": len(rows),
        "columns": len(headers),
        "features": features,
        "target": TARGET,
        "identifier": IDENTIFIER,
        "class_counts_raw": dict(sorted(labels.items(), key=lambda item: str(item[0]))),
        "missing_values_by_column": missing_by_column,
        "missing_values_total": sum(missing_by_column.values()),
        "duplicate_full_row_excess": len(full_rows) - len(set(full_rows)),
        "blank_identifier_rows": sum(row.get(IDENTIFIER) in (None, "") for row in rows),
        "duplicate_identifier_excess": len(rows)
        - len({row.get(IDENTIFIER) for row in rows}),
        "conflicting_identifier_groups": sum(len(values) > 1 for values in ids.values()),
        "duplicate_feature_vector_excess": len(rows)
        - len({_feature_key(row, features) for row in rows}),
        "conflicting_feature_vector_groups": sum(
            len(values) > 1 for values in feature_labels.values()
        ),
        "constant_features": [
            feature
            for feature in features
            if len({row.get(feature) for row in rows}) <= 1
        ],
        "nonnumeric_features": nonnumeric_features,
        "nonfinite_features": nonfinite_features,
        "invalid_target_values": invalid_labels,
    }


def validate(path: Path, project: str) -> dict[str, Any]:
    sheets = _read_workbook(path)
    prefix = f"{project}_"
    selected = {
        name: rows
        for name, rows in sheets.items()
        if name.casefold().startswith(prefix.casefold())
    }
    if len(selected) < 3:
        raise ValueError(
            f"Expected at least three {project!r} version sheets; found {len(selected)}."
        )

    release_names = sorted(selected, key=lambda name: _version_key(name, project))
    headers_by_release = {
        name: list(selected[name][0].keys()) if selected[name] else []
        for name in release_names
    }
    common_headers = headers_by_release[release_names[0]]
    if any(headers != common_headers for headers in headers_by_release.values()):
        raise ValueError("Release sheets do not have a consistent feature schema.")
    if len(common_headers) != len(set(common_headers)) or "" in common_headers:
        raise ValueError("Release schema contains blank or duplicate column names.")

    releases = {
        name: _validate_release(name, selected[name], common_headers)
        for name in release_names
    }
    release_rows = {name: selected[name] for name in release_names}
    feature_names = [
        column for column in common_headers if column not in {IDENTIFIER, TARGET}
    ]
    release_order_checks: list[dict[str, Any]] = []
    seen_vectors: set[tuple[str | None, ...]] = set()
    seen_ids: set[str | None] = set()
    for name in release_names:
        rows = release_rows[name]
        vectors = [_feature_key(row, feature_names) for row in rows]
        novel_rows = [
            row
            for row, vector in zip(rows, vectors)
            if vector not in seen_vectors
        ]
        novel_vectors = {vector for vector in vectors if vector not in seen_vectors}
        new_id_rows = [row for row in rows if row.get(IDENTIFIER) not in seen_ids]
        release_order_checks.append(
            {
                "release": name,
                "rows_with_previously_seen_feature_vector": len(rows) - len(novel_rows),
                "rows_with_novel_feature_vector": len(novel_rows),
                "novel_unique_feature_vectors": len(novel_vectors),
                "novel_feature_vector_class_counts_raw": dict(
                    sorted(
                        Counter(row.get(TARGET) for row in novel_rows).items(),
                        key=lambda item: str(item[0]),
                    )
                ),
                "rows_with_previously_seen_class_identifier": len(rows)
                - len(new_id_rows),
                "rows_with_new_class_identifier": len(new_id_rows),
                "new_class_identifier_counts_raw": dict(
                    sorted(
                        Counter(row.get(TARGET) for row in new_id_rows).items(),
                        key=lambda item: str(item[0]),
                    )
                ),
            }
        )
        seen_vectors.update(vectors)
        seen_ids.update(row.get(IDENTIFIER) for row in rows)

    pairwise: list[dict[str, Any]] = []
    for left_index, left_name in enumerate(release_names):
        left_rows = release_rows[left_name]
        for right_name in release_names[left_index + 1 :]:
            right_rows = release_rows[right_name]
            left_ids: dict[str | None, set[str | None]] = defaultdict(set)
            right_ids: dict[str | None, set[str | None]] = defaultdict(set)
            for row in left_rows:
                left_ids[row.get(IDENTIFIER)].add(row.get(TARGET))
            for row in right_rows:
                right_ids[row.get(IDENTIFIER)].add(row.get(TARGET))
            shared_ids = set(left_ids) & set(right_ids)
            shared_ids.discard(None)
            label_changes = sum(left_ids[name] != right_ids[name] for name in shared_ids)

            left_vectors: dict[tuple[str | None, ...], set[str | None]] = defaultdict(set)
            right_vectors: dict[tuple[str | None, ...], set[str | None]] = defaultdict(set)
            for row in left_rows:
                left_vectors[_feature_key(row, feature_names)].add(row.get(TARGET))
            for row in right_rows:
                right_vectors[_feature_key(row, feature_names)].add(row.get(TARGET))
            shared_vectors = set(left_vectors) & set(right_vectors)
            vector_label_conflicts = sum(
                left_vectors[vector] != right_vectors[vector]
                for vector in shared_vectors
            )
            right_full_rows = {
                tuple(row.get(column) for column in common_headers)
                for row in right_rows
            }
            left_full_rows = {
                tuple(row.get(column) for column in common_headers)
                for row in left_rows
            }
            pairwise.append(
                {
                    "earlier_release": left_name,
                    "later_release": right_name,
                    "shared_class_identifiers": len(shared_ids),
                    "shared_identifiers_with_label_changes": label_changes,
                    "shared_feature_vectors": len(shared_vectors),
                    "shared_vectors_with_label_changes": vector_label_conflicts,
                    "identical_full_records_shared": len(left_full_rows & right_full_rows),
                }
            )

    return {
        "workbook": path.name,
        "project": project,
        "release_order_by_version_identifier": release_names,
        "headers": common_headers,
        "releases": releases,
        "release_order_checks": release_order_checks,
        "cross_release_comparisons": pairwise,
        "assertions": {
            "at_least_three_releases": len(release_names) >= 3,
            "consistent_schema": True,
            "class_identifier_and_binary_target_present": (
                IDENTIFIER in common_headers and TARGET in common_headers
            ),
            "both_classes_in_each_release": all(
                release["class_counts_raw"].get("0", 0) > 0
                and release["class_counts_raw"].get("1", 0) > 0
                for release in releases.values()
            ),
            "only_binary_target_values": all(
                not release["invalid_target_values"] for release in releases.values()
            ),
            "no_missing_cells": all(
                release["missing_values_total"] == 0
                for release in releases.values()
            ),
            "nonblank_unique_class_identifiers": all(
                release["blank_identifier_rows"] == 0
                and release["duplicate_identifier_excess"] == 0
                for release in releases.values()
            ),
            "no_conflicting_labels_for_class_identifier": all(
                release["conflicting_identifier_groups"] == 0
                for release in releases.values()
            ),
            "no_duplicate_full_records_within_release": all(
                release["duplicate_full_row_excess"] == 0
                for release in releases.values()
            ),
            "no_conflicting_feature_vectors_within_release": all(
                release["conflicting_feature_vector_groups"] == 0
                for release in releases.values()
            ),
            "numeric_features": all(
                not release["nonnumeric_features"]
                and not release["nonfinite_features"]
                for release in releases.values()
            ),
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--workbook",
        type=Path,
        default=Path("ml/rq1/datasets/raw/promise_regenerated_candidates.xlsx"),
    )
    parser.add_argument("--project", default="jedit")
    arguments = parser.parse_args()
    if not arguments.workbook.is_file():
        parser.error(f"Workbook not found: {arguments.workbook}")
    try:
        report = validate(arguments.workbook, arguments.project.casefold())
    except (OSError, ValueError, zipfile.BadZipFile, ElementTree.ParseError) as error:
        print(f"VALIDATION FAILED: {error}", file=sys.stderr)
        return 1
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

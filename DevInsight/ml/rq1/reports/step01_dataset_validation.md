# RQ1 Step 1 — JEdit release data validation

- **Validation date:** 2026-11-12
- **Input:** `ml/rq1/datasets/raw/promise_regenerated_candidates.xlsx`
- **Command:** `python -B ml\rq1\scripts\02_validate_versioned_promise.py --workbook ml\rq1\datasets\raw\promise_regenerated_candidates.xlsx --project jedit`

## Parsing and schema

The Python standard-library OOXML reader parsed the workbook directly from its ZIP/XML contents. It identified five JEdit sheets ordered by their version identifiers: `jedit_3_2_1`, `jedit_4_0`, `jedit_4_1`, `jedit_4_2`, and `jedit_4_3`. Every sheet has the same eight-column schema:

`ClassName`, `CBO`, `DCC`, `ExportCoupling`, `ImportCoupling`, `NOM`, `WMC`, `Defect`

`ClassName` is a categorical class identifier; the six metric columns are numeric; `Defect` is binary. The paper cited by Zenodo documents the binary mapping: at least one source defect becomes faulty (`1`), zero defects becomes not-faulty (`0`). The original counts are not present in the selected workbook.

## Observed per-release results

| Sheet / version identifier | Rows | Columns | `Defect=0` | `Defect=1` | Missing cells | Exact full-row duplicate excess | Repeated feature-vector excess | Conflicting feature-vector groups |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `jedit_3_2_1` | 163 | 8 | 75 | 88 | 0 | 0 | 6 | 0 |
| `jedit_4_0` | 192 | 8 | 119 | 73 | 0 | 0 | 5 | 1 |
| `jedit_4_1` | 197 | 8 | 122 | 75 | 0 | 0 | 6 | 0 |
| `jedit_4_2` | 225 | 8 | 178 | 47 | 0 | 0 | 4 | 0 |
| `jedit_4_3` | 470 | 8 | 459 | 11 | 0 | 0 | 31 | 1 |

Each release has both binary labels; no target values outside `{0,1}` were found. There are no blank or repeated class identifiers within an individual release, no conflicting labels for a class identifier within a release, no constant metric features, and no nonnumeric/non-finite metric values. Across all five releases: **1,247 rows** and **6 numeric predictors per row**.

## Release overlap and leakage audit

For each pair, “shared classes” counts `ClassName` intersections; “changed class labels” counts shared class identifiers whose observed label differs. “Shared vectors” ignores the identifier and target; “changed vector labels” counts shared vectors whose label sets differ. Full records include identifier, metrics, and target.

| Earlier → later sheet | Shared classes | Shared classes with label changes | Shared feature vectors | Shared vectors with label changes | Identical full records |
|---|---:|---:|---:|---:|---:|
| `jedit_3_2_1` → `jedit_4_0` | 156 | 56 | 57 | 24 | 36 |
| `jedit_3_2_1` → `jedit_4_1` | 144 | 46 | 41 | 17 | 27 |
| `jedit_3_2_1` → `jedit_4_2` | 132 | 52 | 25 | 7 | 18 |
| `jedit_3_2_1` → `jedit_4_3` | 126 | 69 | 21 | 4 | 14 |
| `jedit_4_0` → `jedit_4_1` | 177 | 46 | 85 | 25 | 65 |
| `jedit_4_0` → `jedit_4_2` | 161 | 51 | 43 | 6 | 37 |
| `jedit_4_0` → `jedit_4_3` | 151 | 65 | 32 | 5 | 22 |
| `jedit_4_1` → `jedit_4_2` | 179 | 58 | 59 | 11 | 48 |
| `jedit_4_1` → `jedit_4_3` | 167 | 70 | 38 | 7 | 30 |
| `jedit_4_2` → `jedit_4_3` | 212 | 46 | 89 | 5 | 77 |

In the proposed latest-version test sheet `jedit_4_3`, 110 rows have a feature vector seen in an earlier release; 360 rows have novel feature vectors (345 unique vectors), including all 11 positive examples. This makes a secondary novel-vector evaluation cohort feasible without deleting or altering raw repeated classes. The test still contains only 11 positives and is not a robust estimate by itself.

## Data-quality policy and boundaries

- Preserve the original workbook bytes, row order, labels, and all repeated class observations.
- Never use `ClassName` as a predictor. Do not randomly split rows across versions.
- Keep repeated classes in successive versions as distinct release observations; report class/feature overlap and label changes.
- In later evaluation, separately identify exact feature-vector overlap with earlier versions. Report full-release and novel-vector cohorts; do not silently discard repeated records from the raw or chosen benchmark.
- Two releases have a same-release feature-vector conflict (`jedit_4_0` and `jedit_4_3`). Keep both labels pending a documented policy; assess sensitivity before modeling.
- The source documents counts per class and binary relabeling but not the defect-label observation window, issue/commit traceability, or whether counts are cumulative across releases. Version order is not independently verified calendar time.
- No preprocessing, imputation, row removal, label editing, splitting, model fitting, or performance calculation was performed.

## Validation assertion outcomes

**Passed:** at least three releases; consistent schemas; identifier and binary target present; both labels in each release; target values binary; no missing cells; nonblank unique per-release class identifiers; no within-identifier label conflicts; no exact duplicate full rows within a release; numeric finite features.

**Data-quality warning:** “no conflicting feature vectors within release” is false because one conflict group is present in `jedit_4_0` and one in `jedit_4_3`. The validator reports these facts and exits successfully; it does not repair the data.

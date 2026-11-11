# Main Step 1 Recovery — Versioned dataset resolution

- **Project:** DevInsight: An AI-Powered Software Engineering Intelligence Platform for Project Risk Prediction and Root Cause Analysis
- **Date:** 2026-11-12
- **Final status:** **PASS** for dataset selection and validation only

## 1. Why the original JM1 selection was limited

JM1 is an unversioned NASA/PROMISE C software-module dataset. It has no row-level project/version/time identifier, so no release-based independent holdout can be constructed. It is module-level rather than verified file-level, its source page class-count table conflicts with the downloaded OpenML file, and it has 88 repeated feature-vector groups with conflicting labels. JM1 and KC1 were preserved unchanged and are no longer the selected benchmark.

## 2. Alternative selected

Selected JEdit from the **Regenerated PROMISE and BPD Datasets** workbook, Zenodo record 4625975. The workbook contains five JEdit release sheets. This provides an explicit Java class-level prediction unit and version identifiers suitable for a release-order holdout. The selection does not change the official RQ1 statement or claim correspondence to DevInsight’s GitHub language stack.

## 3. Source and provenance

- Zenodo record: https://zenodo.org/records/4625975
- DOI: https://doi.org/10.5281/zenodo.4625975
- Record metadata: 36 datasets representing versions of 13 open-source Java systems; creator Sultan Alhusain; version 1; open access; license `CC BY 4.0`.
- Cited paper: S. Alhusain, “Predicting Relative Thresholds for Object Oriented Metrics,” 2021 IEEE/ACM International Conference on Technical Debt, pp. 55–63, DOI https://doi.org/10.1109/TechDebt52882.2021.00015; author manuscript https://arxiv.org/abs/2103.11442.
- The paper says its class-level datasets were obtained from PROMISE and Bug Prediction Dataset sources, regenerated using a common tool, and deposited in this Zenodo record.
- GitHub mirrors inspected: https://github.com/feiwww/PROMISE-backup and https://github.com/jalaxy33/PROMISE-dataset. Neither reports a repository license; neither was used to acquire the selected raw workbook or to infer its license/schema.

## 4. Verified label semantics

The cited paper’s Dataset Preparation section states each record is a class with a number of defects, and classes are relabeled faulty when the count is **≥1**, otherwise not faulty. The workbook’s `Defect` column contains only `0` and `1`; therefore `1` = one or more defects/faulty, and `0` = zero defects/not faulty. A blank label, if present, would be unknown, not negative. No target is missing in the inspected JEdit sheets. The workbook does not retain original bug counts or their issue/fixing provenance.

## 5. Exact observed dataset statistics

The acquired workbook is 585,068 bytes with SHA-256 `364ab30e660ba3d78644ac717d28bb224e03648f9ad06b42a3453daee2ae0c31`.

| JEdit sheet | Version identifier | Rows | Defect 0 | Defect 1 |
|---|---|---:|---:|---:|
| `jedit_3_2_1` | 3.2.1 | 163 | 75 | 88 |
| `jedit_4_0` | 4.0 | 192 | 119 | 73 |
| `jedit_4_1` | 4.1 | 197 | 122 | 75 |
| `jedit_4_2` | 4.2 | 225 | 178 | 47 |
| `jedit_4_3` | 4.3 | 470 | 459 | 11 |

Total JEdit data: 1,247 rows; each sheet has 8 columns: `ClassName`, `CBO`, `DCC`, `ExportCoupling`, `ImportCoupling`, `NOM`, `WMC`, `Defect`. The six metrics are numeric; `ClassName` is an identifier, not a model feature.

## 6. Release ordering

The workbook sheets order by version identifiers as 3.2.1, 4.0, 4.1, 4.2, 4.3. Calendar release dates and label-observation dates were not independently confirmed. All split references in this report are **release-order holdouts**, not verified temporal splits.

## 7. Duplicate and conflicting-label analysis

Within each release there are no missing cells, duplicate full records, blank/duplicate `ClassName` values, or conflicting labels for a class identifier. All metric columns are numeric and finite, and no metric is constant.

| Release | Repeated feature-vector excess | Conflicting feature-vector groups |
|---|---:|---:|
| 3.2.1 | 6 | 0 |
| 4.0 | 5 | 1 |
| 4.1 | 6 | 0 |
| 4.2 | 4 | 0 |
| 4.3 | 31 | 1 |

Across the proposed sequence:

| Pair | Shared classes | Shared class labels changed | Shared feature vectors | Shared vectors with label changes | Exact full records shared |
|---|---:|---:|---:|---:|---:|
| 4.1 → 4.2 | 179 | 58 | 59 | 11 | 48 |
| 4.2 → 4.3 | 212 | 46 | 89 | 5 | 77 |

In 4.3, 110 rows reuse a feature vector found in an earlier release; 360 rows have novel vectors (345 unique), including all 11 positive rows. Retain all original classes and versions. Do not use class names as features, randomly mix releases, deduplicate across releases, or alter labels. For a future leakage-aware primary cohort, measure exact novel feature vectors separately from the full-release cohort; keep all rows in the raw source. Resolve the two conflicting same-release vector groups with an explicit future policy and sensitivity reporting.

## 8. Proposed independent testing strategy

Proposed sequence: **train on 4.1 → validate on 4.2 → test on 4.3**, with version sheets kept disjoint. A future primary evaluation can score the 4.3 novel-feature-vector cohort alongside full-release sensitivity results. This preserves recurring classes as release observations while disclosing exact feature/record overlap. It is not a test of unseen projects; it is not proven chronological at the date/label-window level. The 4.3 holdout is strongly imbalanced (11/470 positive), which limits inferential strength.

The analysis only assesses feasibility; it created no split or transformed data.

## 9. Compatibility with the official RQ1 objective

This is a preliminary class-level Java defect benchmark, while the official question concerns GitHub repository data and bug-prone files. It supports experimentation on six static OO metrics and a binary class defect label; it does not establish DevInsight performance on its own Python/Dart GitHub repositories. Do not silently rewrite the proposal or generalize benchmark results to the live product.

## 10. Python/Dart GitHub limitations

The workbook contains Java class metrics and defect labels, not Python/Dart files, GitHub commit histories, issue/PR links, contributor counts, changed lines, static-analyzer reports, CI failures, or versioned live repository data. The target does not preserve defect counts or a trace to defect-inducing changes. The class-level output is not a direct file-level GitHub label.

## 11. Actual verification commands

Download and checksum:

```powershell
$r=Invoke-RestMethod 'https://zenodo.org/api/records/4625975'; $f=$r.files[0]; Invoke-WebRequest -Uri $f.links.self -OutFile 'ml\rq1\datasets\raw\promise_regenerated_candidates.xlsx'
Get-Item 'ml\rq1\datasets\raw\promise_regenerated_candidates.xlsx' | Select-Object Name,Length
Get-FileHash 'ml\rq1\datasets\raw\promise_regenerated_candidates.xlsx' -Algorithm SHA256
```

Validation:

```powershell
python -B ml\rq1\scripts\02_validate_versioned_promise.py --workbook ml\rq1\datasets\raw\promise_regenerated_candidates.xlsx --project jedit
```

Repository/progress checks:

```powershell
git branch --show-current
git status --short
git rev-parse HEAD
git check-ignore -v ml/rq1/datasets/raw/promise_regenerated_candidates.xlsx
python -m json.tool ml\rq1\progress.json
git diff --check
```

## 12. Test and assertion outcomes

The versioned workbook validator exited successfully and emitted JSON. Parsing, consistent schema, both classes in all five releases, binary-only labels, no missing values, numeric finite metrics, unique nonblank per-release class identifiers, and no conflicting labels per class identifier all passed. It reports no duplicate full rows within releases. The assertion for zero within-release conflicting feature vectors is intentionally false (one group in release 4.0 and one in 4.3); this finding is surfaced, not silently handled. No model/split/test artifact or performance metric was produced.

## 13. Warnings and limitations

- JEdit is Java class-level data, not DevInsight’s Python/Dart file-level GitHub corpus.
- Only 11 positive labels occur in the final 4.3 release.
- Release identifiers are ordered but dates and label windows are unverified.
- Cross-release repeated feature vectors and exact records are common; some class labels change.
- Two same-release feature-vector groups have conflicting labels.
- No historical defect link, static-analysis warning, contributor, CI/CD, or commit/change feature is supplied.

## 14. Complete created/modified file list

Created or updated for recovery:

- `ml/rq1/README.md`
- `ml/rq1/scripts/02_validate_versioned_promise.py`
- `ml/rq1/reports/step01_dataset_comparison.md`
- `ml/rq1/reports/step01_dataset_validation.md`
- `ml/rq1/verification/step01_verification_report.md`
- `ml/rq1/verification/step01_resolution_report.md`
- `ml/rq1/progress.md`
- `ml/rq1/progress.json`
- Ignored raw file: `ml/rq1/datasets/raw/promise_regenerated_candidates.xlsx`

Existing JM1/KC1 files and user research files were preserved. No application/backend/configuration/research dataset outside `ml/rq1/` was modified; no dependencies were added.

## 15. Final decision and readiness

**PASS — Main Step 1 dataset selection and validation.** Required source, license, label semantics, unit, schema, release statistics, validation, and risk evidence are documented. Main Step 2 can be considered only when requested. Steps 2–5 remain NOT_STARTED; progress estimate changes from 76% to **80%** based on the stated planning weight, not model accuracy.

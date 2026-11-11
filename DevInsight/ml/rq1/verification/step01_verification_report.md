# Main Step 1 — Dataset selection and validation verification

- **Project:** DevInsight: An AI-Powered Software Engineering Intelligence Platform for Project Risk Prediction and Root Cause Analysis
- **Verification date:** 2026-11-12
- **Scope:** Dataset selection/validation only. No preprocessing, split files, model training/evaluation, FastAPI integration, branch switch, commit, or push.

## A. Executive summary

**Decision: PASS for Main Step 1.** A genuine versioned class-level software defect dataset was acquired from a CC BY 4.0 Zenodo record; the cited paper verifies the `Defect` label mapping; five JEdit releases have consistent numeric feature schemas, both classes, and a feasible release-order holdout. Data-quality and overlap risks, including repeated records and within-release conflicting vectors, are documented. This PASS does not mean data were preprocessed/split, that the holdout is a verified temporal split, or that RQ1 model results exist.

## B. Dataset candidates investigated

- **Selected:** Alhusain’s regenerated PROMISE/BPD dataset workbook from Zenodo record 4625975.
- **Not selected/acquired:** `feiwww/PROMISE-backup` and `jalaxy33/PROMISE-dataset`, both public GitHub mirrors with no repository license reported; labels and schemas in the mirrors must not be assumed identical to the Zenodo workbook.
- **Previous candidates, preserved:** PROMISE/NASA JM1 (OpenML 1053) and KC1 (OpenML 1067); JM1’s unversioned module rows and source-count discrepancy make it inferior for the present release-order design.

## C. Evidence and original sources

- Zenodo record and metadata/license: https://zenodo.org/records/4625975
- DOI: https://doi.org/10.5281/zenodo.4625975
- Cited source: S. Alhusain, “Predicting Relative Thresholds for Object Oriented Metrics,” TechDebt 2021, pp. 55–63, DOI https://doi.org/10.1109/TechDebt52882.2021.00015; accessible author manuscript https://arxiv.org/abs/2103.11442.
- The paper’s Dataset Preparation section states each source table has classes with defect counts and re-labels classes faulty when defect count is at least 1, otherwise not faulty. It also says datasets from PROMISE and the Bug Prediction Dataset were regenerated using a common tool and published in the workbook.
- Mirror comparison references: https://github.com/feiwww/PROMISE-backup and https://github.com/jalaxy33/PROMISE-dataset. They were not used for raw acquisition or licensing.

## D. Final dataset choice and justification

Use the workbook’s JEdit class-level releases. Unlike JM1, they have project/version labels and support an ordered release holdout. It is an appropriate preliminary static-metric class-level benchmark, not a direct sample of DevInsight’s GitHub data or proposal features.

## E. Dataset path, checksum, and acquisition

| File | Path | Size | SHA-256 | Source / method |
|---|---|---:|---|---|
| Regenerated PROMISE and BPD Datasets.xlsx | `ml/rq1/datasets/raw/promise_regenerated_candidates.xlsx` | 585,068 bytes | `364ab30e660ba3d78644ac717d28bb224e03648f9ad06b42a3453daee2ae0c31` | Zenodo record 4625975 file API; downloaded with PowerShell `Invoke-WebRequest` on 2026-11-12 |

The raw workbook is covered by `ml/rq1/.gitignore` (`datasets/raw/`). It was not staged. Zenodo metadata reports CC BY 4.0 for this record; this is not a license assertion about the GitHub mirrors.

## F. Actual row and column counts

Five JEdit sheets contain **1,247 rows total**. Each has 8 columns: a class identifier, six numeric metrics, and one binary target. The proposed sequence (`jedit_4_1`, `jedit_4_2`, `jedit_4_3`) contains 197, 225, and 470 rows, respectively.

| Release sheet | Rows | 0 / not faulty | 1 / faulty |
|---|---:|---:|---:|
| `jedit_3_2_1` | 163 | 75 | 88 |
| `jedit_4_0` | 192 | 119 | 73 |
| `jedit_4_1` | 197 | 122 | 75 |
| `jedit_4_2` | 225 | 178 | 47 |
| `jedit_4_3` | 470 | 459 | 11 |

## G. Feature schema and target definition

- Identifier: `ClassName` (not a predictor).
- Numeric features: `CBO`, `DCC`, `ExportCoupling`, `ImportCoupling`, `NOM`, `WMC`.
- Target: `Defect`, binary `0`/`1`.
- Verified semantics from Alhusain (2021): one or more source defects → faulty (`1`); zero defects → not faulty (`0`). The workbook has binarized labels and does not retain the original defect count.
- Prediction unit: one class in a specific JEdit release.

## H. Class distribution

Both labels occur in every release. The proposed later-release test `jedit_4_3` has 11 faulty and 459 not-faulty rows (2.34% faulty), so estimates from it will be uncertain. These are dataset counts, not model metrics.

## I. Missing and duplicate data assessment

- Missing cells: zero across all selected JEdit release sheets.
- Duplicate full rows within a release: zero excess rows.
- Blank/duplicate `ClassName` within releases: none; no within-class label conflicts.
- Constant, nonnumeric, or non-finite numeric features: none.
- Repeated feature-vector excesses by release: 6, 5, 6, 4, and 31, respectively.
- Same-release feature-vector groups with conflicting labels: one in `jedit_4_0` and one in `jedit_4_3`.
- Proposed releases overlap substantially. For `jedit_4_1` → `jedit_4_2` → `jedit_4_3`, adjacent shared feature-vector counts are 59 and 89; 48 and 77 exact full records recur, respectively. Class labels also change across versions.
- Of `jedit_4_3`, 110 rows have a feature vector seen earlier; 360 rows have novel feature vectors (345 unique), including all 11 positive rows.

Raw releases remain unchanged. Preserve repeated classes as separate release observations, exclude `ClassName` from predictors, report overlap, and in Main Step 2 plan both a full-release evaluation and a feature-vector-novel cohort. Resolve the two conflicting-vector groups by a documented, sensitivity-reported policy; do not silently relabel or deduplicate.

## J. Leakage and split feasibility assessment

Proposed release-order holdout: **train `jedit_4_1`; validate `jedit_4_2`; test `jedit_4_3`**. Keep the release sheets separate; do not random-split rows. An additional primary/sensitivity analysis can identify exact feature vectors observed earlier without deleting raw data; the candidate later-release cohort retains all 11 positive rows. This establishes a feasible release-order design, not an already-created split.

Release dates and defect-observation windows were not independently verified. Do not call this a verified temporal split. Labels may have cross-release overlap, and the workbook does not establish whether defect counts are cumulative or version-bounded. This is not an unseen-project test.

## K. Proposal feature alignment

| Feature | Status | Evidence / limitation |
|---|---|---|
| Commit frequency | UNAVAILABLE | No commit or time fields. |
| Changed lines | UNAVAILABLE | No change metrics. |
| Contributing developers | UNAVAILABLE | No authors/contributors. |
| Historical bug information | PROXY_ONLY | Binary class target derived from defect counts; no counts, issue links, dates, or fixing relations. |
| Static analysis indicators | PROXY_ONLY | Static object-oriented metrics, not analyzer warnings. |
| CI/CD failure links | UNAVAILABLE | No build/test/CI data. |

## L. Exact executed commands

```powershell
$r=Invoke-RestMethod 'https://zenodo.org/api/records/4625975'; $f=$r.files[0]; Invoke-WebRequest -Uri $f.links.self -OutFile 'ml\rq1\datasets\raw\promise_regenerated_candidates.xlsx'
Get-Item 'ml\rq1\datasets\raw\promise_regenerated_candidates.xlsx' | Select-Object Name,Length
Get-FileHash 'ml\rq1\datasets\raw\promise_regenerated_candidates.xlsx' -Algorithm SHA256
python -B ml\rq1\scripts\02_validate_versioned_promise.py --workbook ml\rq1\datasets\raw\promise_regenerated_candidates.xlsx --project jedit
git branch --show-current
git status --short
git rev-parse HEAD
git check-ignore -v ml/rq1/datasets/raw/promise_regenerated_candidates.xlsx
```

Final JSON, whitespace, and original-data integrity checks are recorded in Section M and repeated at completion.

## M. Test results and validation assertions

The validator executed successfully and emitted JSON. Assertions passed for: five releases; common schema; binary target and both labels in each release; no missing cells; unique nonblank class identifiers within releases; no class-level label conflicts within a release; no exact duplicate full rows within releases; and finite numeric metrics. The “no conflicting feature vectors within release” assertion is **false** because the two groups described above are present. This is an observed data warning, not a parser failure; no repair was attempted.

No model, split artifact, ML metric, or API integration was generated. `progress.json` parses as JSON. `git diff --check` and raw-file/hash/branch checks are run at task completion.

## N. Warnings and limitations

- Java class-level benchmark, not Python/Dart GitHub files.
- Latest candidate test has only 11 positive classes.
- Release versions establish an ordering of version identifiers, not independently verified dates.
- Defect observation windows/count accumulation are undocumented in the workbook.
- Significant cross-release repeated classes, metrics, and full records; two within-release conflicting metric-vector groups.
- No commit frequency, change size, authors, issue/PR links, CI failures, static-analysis warnings, or root-cause evidence.

## O. Unresolved blockers

No blocker prevents dataset selection/validation or a cautious release-order design. Before Main Step 2, document the treatment of the two conflicting same-release vectors, confirm whether the novel-vector cohort is primary or sensitivity-only, and retain the test-class imbalance and unverified label time window as explicit threats to validity.

## P. Created/modified file list

Created/updated for this recovery:

- `ml/rq1/README.md`
- `ml/rq1/scripts/02_validate_versioned_promise.py`
- `ml/rq1/reports/step01_dataset_comparison.md`
- `ml/rq1/reports/step01_dataset_validation.md`
- `ml/rq1/verification/step01_verification_report.md`
- `ml/rq1/verification/step01_resolution_report.md`
- `ml/rq1/progress.md`
- `ml/rq1/progress.json`
- Ignored raw workbook: `ml/rq1/datasets/raw/promise_regenerated_candidates.xlsx`

No Flutter, FastAPI, Supabase, existing repository-screening, GitHub research dataset, or original JM1/KC1 file was modified. No package/dependency was added.

## Q. Git branch and working-tree verification

- Branch: `Research`; HEAD before and after the task: `9362ace7f4ab56800a0d1efa83f1c45b2c0080c9`.
- No branch switch, merge, stage, commit, or push.
- Existing untracked research files `data/bug_fix_review.csv`, `data/bug_fix_review_timeline_cache.json`, `data/bug_issue_samples_pilot.csv`, and `data/repository_bug_audit_pilot.csv` were left untouched.
- `ml/rq1/` is untracked on this branch; raw files are separately ignored by its scoped `.gitignore`.

## R. Final decision

**PASS — Main Step 1 dataset selection and validation.** The source is acquired and checksummed; label mapping and unit are explicit; five compatible releases support a release-order holdout; data quality and overlap risks are measured; and the read-only validator runs. This does not certify temporal validity or any ML result.

## S. Readiness for Main Step 2

**Ready to begin Main Step 2 only when explicitly requested.** Step 2 may design preprocessing and release-based splitting while preserving raw data and carrying forward the documented duplicate, leakage, label-window, and imbalance limitations. Steps 2–5 remain NOT_STARTED; no split has been made in this task.

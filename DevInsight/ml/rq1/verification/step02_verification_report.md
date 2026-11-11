# Main Step 2 — Preprocessing and release-order split verification

- **Project:** DevInsight: An AI-Powered Software Engineering Intelligence Platform for Project Risk Prediction and Root Cause Analysis
- **Verification date:** 2026-11-12
- **Decision:** **PASS** for preprocessing and fixed release-order partitioning only
- **Scope exclusions:** No model training, predictions, performance metrics, API integration, branch switch, commit, or push.

## A. Executive summary

The Step 1 Zenodo workbook checksum and JEdit schemas were rechecked. The exact requested partitions were generated without row redistribution: `jedit_4_1` for training, `jedit_4_2` for validation, and `jedit_4_3` for testing. All 892 selected release rows were retained. Each CSV contains only the six approved numeric features and the original binary `Defect` target. Excel source row number and `ClassName` are preserved separately in the split manifest.

The independent verifier passed all 17 assertions. No imputations or scaling were needed or applied. Repeated and conflicting feature vectors remain in the primary partitions and are reported. This is a **release-order holdout**, not a verified temporal split.

## B. Dataset and source integrity

- Source: “Regenerated PROMISE and BPD Datasets.xlsx,” [Zenodo record 4625975](https://zenodo.org/records/4625975), version 1; CC BY 4.0 as reported by the Zenodo record.
- Local source: `ml/rq1/datasets/raw/promise_regenerated_candidates.xlsx`
- Observed size: 585,068 bytes.
- SHA-256 before and after preparation: `364ab30e660ba3d78644ac717d28bb224e03648f9ad06b42a3453daee2ae0c31`, matching Step 1.
- The Step 1 workbook validator confirmed all five JEdit releases. The selected three sheets have the exact expected schema and no missing cells.
- `jedit_3_2_1` and `jedit_4_0` were excluded from the partitions and left unchanged.

## C. Prediction unit and label verification

- Prediction unit: one Java class observation in one JEdit release.
- Identifier: `ClassName`, retained only in the manifest for traceability.
- Target: original `Defect` values (`1` = at least one recorded defect; `0` = zero recorded defects), unchanged from the workbook.
- The six source feature names and the binary target were checked against Step 1. No target value was used as an input feature.

## D. Preprocessing rules

1. Read the workbook using the Step 1 standard-library OOXML parser and require the expected Step 1 source SHA-256.
2. Select only `jedit_4_1`, `jedit_4_2`, and `jedit_4_3`; reject a missing release, changed schema, unexpected columns, missing values, nonnumeric/non-finite features, blank identifiers, or nonbinary targets.
3. Preserve source row order, all rows, original feature values, and original labels. Do not deduplicate, relabel, or randomly split.
4. Write only the six features and `Defect` to each CSV. Store `ClassName` and the original Excel worksheet row number in the JSON manifest, not in model inputs.
5. Apply no imputation, scaling, or other fitted transformation. The selected rows contain no missing values.

## E. Exact feature schema

The identical ordered CSV columns are:

`CBO`, `DCC`, `ExportCoupling`, `ImportCoupling`, `NOM`, `WMC`, `Defect`

The first six are numeric predictors. `Defect` is the binary target. No identifier or release column is present in any model CSV.

## F. Train/validation/test release assignments

| Partition | Source sheet | Excel data rows | Assignment |
|---|---|---:|---|
| Train | `jedit_4_1` | 2–198 | All 197 rows |
| Validation | `jedit_4_2` | 2–226 | All 225 rows |
| Test | `jedit_4_3` | 2–471 | All 470 rows |

These are assignments by documented release identifier order. Calendar release dates and defect-observation windows remain unverified, so this is not described as a fully verified temporal split.

## G. Rows and class distributions

| Partition | Rows | `Defect=0` | `Defect=1` |
|---|---:|---:|---:|
| Train (`jedit_4_1`) | 197 | 122 | 75 |
| Validation (`jedit_4_2`) | 225 | 178 | 47 |
| Test (`jedit_4_3`) | 470 | 459 | 11 |

Both classes occur in all three partitions. The test set is highly imbalanced and has only 11 positive cases; this limits later evaluation interpretation.

## H. Missing-value handling

The rechecked selected releases and generated files contain no missing feature or target values. No imputation was performed or fitted. If a later source revision introduces missing values, Step 2 must be rerun and any imputation must be fitted on training data only.

## I. Duplicate and conflicting-label audit

For within-partition results, “repeated excess rows” is row count minus distinct feature vectors; “label matches” counts unordered row pairs inside duplicate-vector groups. For between-partition results, an occurrence pair is one row from each partition sharing a feature vector; matches are classified by whether their labels are equal. No rows were removed.

| Scope | Repeated excess rows | Unique repeated/shared vectors | Feature-vector occurrence pairs | Identical-label matches | Conflicting-label matches |
|---|---:|---:|---:|---:|---:|
| Within train | 6 | 3 | 12 | 12 | 0 |
| Within validation | 4 | 4 | 4 | 4 | 0 |
| Within test | 31 | 18 | 60 | 56 | 4 |
| Train vs. validation | 7 | 59 | 70 | 58 | 12 |
| Train vs. test | 14 | 38 | 59 | 50 | 9 |
| Validation vs. test | 19 | 89 | 109 | 104 | 5 |

The within-test conflicting matches include the known same-release conflicting-vector group. Cross-partition matches do not establish that rows represent the same class. The raw workbook and all repeated observations are preserved; no voting or relabeling was performed.

## J. Cross-release overlap and leakage analysis

Exact six-feature vector overlap occurs between every selected partition pair. Identical and conflicting label match counts are row-pair counts as defined in Section I, not counts of unique classes. The feature vectors alone do not prove class identity. Repeated metrics and labels can affect interpretation of a release holdout, even though no rows were mixed between releases.

`ClassName` was not included as a predictor. The split preserves release boundaries and therefore avoids random cross-release redistribution, but it does not eliminate metric-vector overlap. Release dates, label windows, and whether defect counts are cumulative remain undocumented limitations from Step 1.

## K. Predefined sensitivity analysis

The primary test partition remains **all 470 rows of `jedit_4_3`**. The predeclared diagnostic cohort contains `jedit_4_3` rows whose six-feature vector is absent from both selected earlier partitions (`jedit_4_1` and `jedit_4_2`): **366 rows**, with **355 zero** and **11 positive** labels. It is a diagnostic subset only, not a replacement for the primary test. No model metrics were calculated.

## L. Generated files and SHA-256 checksums

| File | Purpose | SHA-256 |
|---|---|---|
| `ml/rq1/datasets/processed/train.csv` | `jedit_4_1`, 197 rows | `1767f58d2664adfeb2c62dee4f8b139852c8336810da7253ca617153985f7f0d` |
| `ml/rq1/datasets/processed/validation.csv` | `jedit_4_2`, 225 rows | `9b4b765bda5a874e4ff59c7db095db2a2276fe34167c5e931d26d2c218bf70ad` |
| `ml/rq1/datasets/processed/test.csv` | `jedit_4_3`, 470 rows | `ca4c71b7b22f3efd1a32d52781df9ac7c5410bfeddf3da94dd78068cae8469b7` |
| `ml/rq1/reports/step02_split_manifest.json` | Source row traceability, assignments, policy, source/output/script hashes, counts, and overlap audit | `7d8b875249f0a2eb2a47cbac42588e3266ef865f76794c9b8e0914773e992684` |

The CSV directory is covered by `ml/rq1/.gitignore`. The JSON manifest is a small, non-raw metadata artifact retained with the reports.

## M. Exact commands executed

From the `DevInsight` directory:

```powershell
python -B -m py_compile ml\rq1\scripts\02_prepare_splits.py ml\rq1\scripts\02_verify_splits.py
python -B ml\rq1\scripts\02_prepare_splits.py
python -B ml\rq1\scripts\02_verify_splits.py
```

The first verifier execution failed with `KeyError: 'split_assignment'` due to a mismatch in the verifier’s expected manifest field. The verifier was corrected, the preparation command reran to refresh the recorded script hash, and the verifier was rerun. The final verifier result was `PASS`, with all 17 assertions true. The final task checks also included:

```powershell
python -m json.tool ml\rq1\progress.json
git diff --check
git branch --show-current
git rev-parse HEAD
git status --short --branch
git check-ignore -q ml/rq1/datasets/processed/train.csv
git check-ignore -q ml/rq1/datasets/processed/validation.csv
git check-ignore -q ml/rq1/datasets/processed/test.csv
```

## N. Automated verification results

The independent `02_verify_splits.py` run reported **PASS** for all of the following:

1. Raw workbook SHA-256 matches Step 1.
2. Exact release-to-split assignments and excluded unused releases.
3. No source row is assigned more than once; manifest assignments match.
4. Correct source row counts and class distributions.
5. Exactly six identical numeric feature columns plus `Defect`.
6. Consistent binary target domain.
7. No missing or non-finite feature/target values.
8. No identifier among model input columns.
9. No source rows removed or created; CSV feature values and labels equal source values.
10. Original workbook unchanged.
11. Source and script hashes are reproducibly recorded; generated file checksums match.
12. Manifest overlap counts and diagnostic subset match independent recomputation.
13. Manifest explicitly records no model training and no generated model metrics.

The expected feature-vector overlap and conflict counts were reported as warnings, not treated as reasons to alter the data.

## O. Warnings and research limitations

- This is a Java class-level benchmark, not DevInsight’s Python/Dart GitHub file corpus.
- Only 11 positive rows occur in the full test release.
- Repeated feature vectors exist within and across partitions, including conflicting labels; equal feature values do not prove equal class identity.
- Version order is not verified calendar chronology; defect observation windows and count accumulation are unspecified.
- No commit frequency, change size, contributors, issue/PR links, CI failures, static-analyzer findings, or root-cause evidence are present.
- No models were trained, predictions generated, or performance metrics calculated.

## P. Reproducibility assessment

Both scripts use Python’s standard library plus the existing Step 1 workbook parser; no dependency was installed. The preparation script verifies the fixed Step 1 workbook checksum and records its own and the validator’s checksums. The manifest records ordered source row numbers, identifiers, split assignments, processing policy, outputs, and checksums. Re-running preparation with the same workbook and scripts deterministically regenerates the same CSV bytes and hashes. The processed CSVs are Git-ignored.

## Q. Files created or modified

- Created `ml/rq1/scripts/02_prepare_splits.py`
- Created `ml/rq1/scripts/02_verify_splits.py`
- Created ignored outputs `ml/rq1/datasets/processed/train.csv`, `validation.csv`, and `test.csv`
- Created `ml/rq1/reports/step02_split_manifest.json`
- Created this report: `ml/rq1/verification/step02_verification_report.md`
- Updated `ml/rq1/README.md`
- Updated `ml/rq1/.gitignore` to ignore `datasets/processed/`
- Updated `ml/rq1/progress.md` and `ml/rq1/progress.json`

No raw data, JM1/KC1 data, other research data, Flutter, FastAPI, Supabase, or unrelated untracked research files were modified.

## R. Git branch and worktree status

Before Step 2, the branch was `Research` and HEAD was `9362ace7f4ab56800a0d1efa83f1c45b2c0080c9`. The task did not switch branches or stage, commit, or push. Existing unrelated untracked research files were left untouched. Final branch, HEAD, status, ignored-output checks, and whitespace checks are recorded after report/progress updates.

## S. Final decision

**PASS — Main Step 2 preprocessing and data splitting.** The exact release assignments are reproducible; all rows and source labels are preserved; the schemas, traceability, output hashes, and overlap audit pass automated verification. The status does not imply model training, prediction quality, or a verified temporal design.

## T. Readiness for Main Step 3

**Ready for Main Step 3 when requested.** Training can use the fixed train/validation partitions and reserve the full `jedit_4_3` release as the primary test, with the 366-row novel-vector cohort reported only as the predefined diagnostic. Carry forward severe test imbalance, cross-release overlap, and unverified release-date/label-window limitations. No model training has begun.

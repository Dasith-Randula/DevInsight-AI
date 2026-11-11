# Main Step 3 — Random Forest and XGBoost training verification

- **Project:** DevInsight: An AI-Powered Software Engineering Intelligence Platform for Project Risk Prediction and Root Cause Analysis
- **Execution date:** 2026-11-12
- **Decision:** **PASS** for fixed-configuration training and training-artifact integrity only
- **Scope exclusions:** No held-out evaluation, model comparison, hyperparameter search, FastAPI integration, branch switch, commit, or push.

## A. Executive summary

The Step 2 verifier passed before model training. An isolated Python 3.14.2 ML environment was created with pinned, import-verified package versions. The Random Forest and XGBoost classifiers were trained using only the verified `jedit_4_1` training CSV: 197 Java class rows, with 122 negative and 75 positive labels. The six features and original binary `Defect` target were validated; validation/test rows were not loaded.

Both fitted artifacts were saved, loaded, checksum-verified, and checked as binary classifiers with the configured feature order. A repeat fit on the same training rows produced exactly the same training-row probability outputs for both models. All 16 training-verification assertions passed. No held-out performance measures were calculated.

## B. Scope and research objective

This is the preliminary RQ1 class-level defect-prediction training stage on versioned Java benchmark data. It does not establish accuracy on DevInsight’s Python/Dart GitHub files. The split is release-order, not a fully verified temporal split. Step 4 remains responsible for a separately specified held-out evaluation.

## C. Environment and dependency verification

- Interpreter: Python **3.14.2**, isolated at `ml/rq1/.venv/`.
- The isolated environment was created without system site packages; package installation did not alter a FastAPI/backend environment.
- `requirements.txt` pins the direct runtime dependencies actually used by training and verification:

| Package | Verified version |
|---|---:|
| numpy | 2.4.1 |
| pandas | 2.3.3 |
| scikit-learn | 1.8.0 |
| xgboost | 3.1.3 |
| joblib | 1.5.3 |

The pinned Windows/Python 3.14 wheels installed successfully. Imports and model constructors succeeded. Transitive packages were installed by pip; no additional direct dependency was added.

## D. Dataset checksum and schema integrity

- Workbook SHA-256: `364ab30e660ba3d78644ac717d28bb224e03648f9ad06b42a3453daee2ae0c31` (matches Step 1).
- Training CSV SHA-256: `1767f58d2664adfeb2c62dee4f8b139852c8336810da7253ca617153985f7f0d`.
- Validation CSV SHA-256: `9b4b765bda5a874e4ff59c7db095db2a2276fe34167c5e931d26d2c218bf70ad`.
- Test CSV SHA-256: `ca4c71b7b22f3efd1a32d52781df9ac7c5410bfeddf3da94dd78068cae8469b7`.

The training script verifies the workbook and all three fixed split checksums against the Step 2 manifest/config, and verifies the exact release assignments. It reads only `train.csv` into a dataframe. Its exact columns are `CBO`, `DCC`, `ExportCoupling`, `ImportCoupling`, `NOM`, `WMC`, `Defect`. It rejects changed schema/order, incorrect row count, missing/non-finite values, or any target domain other than `{0,1}`. The six feature columns are selected explicitly before fitting; `Defect` cannot enter the model input matrix.

## E. Fixed training configuration

Configuration: `ml/rq1/config/training_config.json`.

- Prediction unit: one Java class observation in a JEdit release.
- Train / validation / test releases: `jedit_4_1` / `jedit_4_2` / `jedit_4_3`.
- Seed: **42**.
- No transformation or imputation was fitted.
- Models were neither tuned nor selected using validation or test data.

**Random Forest (`sklearn.ensemble.RandomForestClassifier`):** `n_estimators=200`, `max_depth=5`, `min_samples_leaf=3`, `class_weight="balanced"`, `random_state=42`, `n_jobs=1`.

**XGBoost (`xgboost.XGBClassifier`):** `n_estimators=150`, `max_depth=3`, `learning_rate=0.05`, `subsample=1.0`, `colsample_bytree=1.0`, `objective="binary:logistic"`, `eval_metric="logloss"`, `tree_method="hist"`, `random_state=42`, `n_jobs=1`, and training-only `scale_pos_weight=1.6266666666666667`.

## F. Random Forest training evidence

The script fit the configured estimator on the 197 rows in `train.csv`, with class counts 122/75 and the exact six configured features. The artifact loads as a fitted `RandomForestClassifier`, advertises classes `[0, 1]`, preserves `feature_names_in_` in the expected order, and reports the configured balanced class-weight policy.

- Artifact: `ml/rq1/models/random_forest.joblib`
- SHA-256: `09d4d67e915b3025e1f5f52e294d22c3d74c900eec2df7635f5d2002912ec681`

## G. XGBoost training evidence

The script fit the configured `XGBClassifier` on the same training-only matrix and labels. The artifact loads as a fitted classifier, recognizes classes `[0, 1]`, retains the feature order, and its fitted `scale_pos_weight` equals the training-only negative/positive ratio.

- Artifact: `ml/rq1/models/xgboost.joblib`
- SHA-256: `c6f1ebf8b78a34562cb6e90e20e4ec4be2ea6bc5f91466873beb5da59a3a4678`

## H. Class imbalance handling

Training labels only: 122 non-defective and 75 defective classes.

- Random Forest uses `class_weight="balanced"`, which derives class weights from labels passed to its training fit.
- XGBoost uses `scale_pos_weight = 122 / 75 = 1.6266666666666667`.
- No validation or test labels were used to derive either setting.

## I. Leakage prevention

The training code constructs the input matrix from the exact six feature columns and separately holds `Defect` as the target. It validates expected train checksum and count and rejects source/split/config drift. Validation/test CSVs are checksummed and their release IDs verified from the Step 2 manifest; their row contents are not parsed or loaded. The training routine never opens those rows for fitting or selection. The verifier likewise uses only training rows for probability/repeat-fit checks; it hashes, but does not load, validation/test files.

The fixed release design remains vulnerable to repeated feature vectors and changing prevalence across releases, as documented in Step 2. These are validity limitations, not grounds for silently removing records at this stage.

## J. Model artifact verification

Both artifacts exist, load with joblib, pass scikit-learn’s fitted-state check, expose six features in the configured order, and recognize both target classes. On the 197 training rows, both produce finite `(197, 2)` probability matrices with values in `[0,1]`. No validation/test predictions were requested or generated.

## K. Training manifest and SHA-256 checksums

Manifest: `ml/rq1/results/step03_training_manifest.json`.

It records algorithm, release, training rows and class counts, feature order, target definition, full fixed hyperparameters, class-balance policy and source counts, dependency versions, fixed input hashes, model artifact hashes, configuration/script hashes, and UTC training timestamp. It records that validation/test data were not used for training/selection and that no test performance metrics or held-out predictions were generated.

Observed training timestamp: `2026-11-11T20:36:52.410816+00:00`. Manifest SHA-256: `e4ecb17216133f885f357877225da52b45627bc3b33a5d27abfb010311343085`.

The model hashes are in Sections F and G. The raw workbook and all Step 2 CSV hashes are recorded in Section D and the manifest. The model binaries and virtual environment are Git-ignored; the manifest is a small metadata file.

## L. Reproducibility results

The verifier performed a second fit of each same configured estimator on the same training-only rows, then compared the row probabilities with the saved model:

| Model | Max absolute probability difference | Tolerance (`atol`, `rtol`) | Probability hash equal on repeat |
|---|---:|---:|---|
| Random Forest | 0.0 | `1e-12` | Yes |
| XGBoost | 0.0 | `1e-12` | Yes |

The checks establish reproducibility of the observed training-row probability outputs in this pinned environment. They do not establish held-out quality or guarantee byte-identical serialization on another system.

## M. Actual commands executed

From the `DevInsight` directory:

```powershell
python --version
python -B -m py_compile ml\rq1\scripts\03_train_models.py ml\rq1\scripts\03_verify_training.py
python -m json.tool ml\rq1\config\training_config.json
python -m venv ml\rq1\.venv
ml\rq1\.venv\Scripts\python.exe -m pip install --disable-pip-version-check -r ml\rq1\requirements.txt
ml\rq1\.venv\Scripts\python.exe --version
ml\rq1\.venv\Scripts\python.exe -c "import importlib.metadata as m; print({p:m.version(p) for p in ['numpy','pandas','scikit-learn','xgboost','joblib']})"
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\02_verify_splits.py
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\03_train_models.py
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\03_verify_training.py
python -m json.tool ml\rq1\config\training_config.json
python -m json.tool ml\rq1\results\step03_training_manifest.json
python -m json.tool ml\rq1\progress.json
git diff --check
git status --short --branch
git branch --show-current
git rev-parse HEAD
```

The initial syntax check caught one mismatched bracket in the training target validation; it was corrected before the training run. The later syntax check passed. The first training-integrity run and the final run both passed; final artifacts/checksums are documented here. No failure required changing model parameters or touching the test data.

## N. Automated verification assertions

All **16** assertions passed:

1. Both model artifact SHA-256 values match.
2. Both artifacts exist, load, and are fitted classifiers.
3. Both recognize classes 0 and 1 and use the six configured features.
4. Installed package versions match configuration and manifest.
5. Feature order is exact and target is excluded.
6. Fixed source/split hashes are recorded consistently in training manifest.
7. Validation/test row data were not loaded by the training verifier.
8. No validation/test model selection or test metrics occurred.
9. Repeat-fit training probabilities are equivalent within tolerance.
10. Raw workbook and all Step 2 split hashes are unchanged.
11. Step 2 release assignments match the fixed configuration.
12. Training config/script hashes match manifest.
13. Training CSV hash matches manifest.
14. Training probability outputs are finite and bounded.
15. Training row/class counts match the source and manifest.
16. XGBoost class weight is computed from and matches training labels only.

The separate Step 2 verifier was rerun immediately before training and passed its 17 assertions. Its observed release counts and overlap audit are recorded in the Step 2 report.

## O. Errors encountered and resolutions

- The first `py_compile` invocation detected a bracket mismatch in the `Defect` domain check. The expression was corrected; syntax validation then passed before training.
- No dependency incompatibility occurred on Python 3.14.2. All pinned wheels installed, imports and constructors succeeded, and both estimators trained and loaded.
- No training or verification assertion failed in the final run.

## P. Warnings and known limitations

- Java class-level benchmark, not DevInsight’s Python/Dart GitHub file corpus.
- The holdout is by release identifier order, not verified calendar chronology.
- Class prevalence shifts across releases; `jedit_4_3` contains only 11 positive classes.
- Repeated feature vectors and conflicting-label matches exist across/within releases; feature equality does not prove class identity.
- No test or validation metrics, predictions, threshold choice, or preferred-model decision is reported here.
- Training-row probability reproducibility is not a performance result.

## Q. Files created and modified

- Created `ml/rq1/requirements.txt`
- Created `ml/rq1/config/training_config.json`
- Created `ml/rq1/scripts/03_train_models.py`
- Created `ml/rq1/scripts/03_verify_training.py`
- Created `ml/rq1/models/random_forest.joblib` (Git-ignored)
- Created `ml/rq1/models/xgboost.joblib` (Git-ignored)
- Created `ml/rq1/results/step03_training_manifest.json`
- Created `ml/rq1/reports/step03_training_summary.md`
- Created this report: `ml/rq1/verification/step03_verification_report.md`
- Updated `ml/rq1/.gitignore`, `ml/rq1/README.md`, `ml/rq1/progress.md`, and `ml/rq1/progress.json`
- Created ignored isolated environment `ml/rq1/.venv/`

No Step 1/2 data, Flutter, FastAPI, Supabase, RQ2/RQ3, or unrelated research files were modified.

## R. Git branch and worktree validation

The task remained on `Research`, HEAD `9362ace7f4ab56800a0d1efa83f1c45b2c0080c9`. No branch switch, stage, commit, or push was performed. Model artifacts and `.venv` are covered by the scoped `.gitignore`. Existing untracked research files were not edited. Final status and whitespace checks were run after these documentation/progress updates.

## S. Final decision

**PASS — Main Step 3 training and training-integrity verification.** The two configured classifiers were trained on the verified training release only, checksummed, loaded, and shown to reproduce their training-row probabilities under repeat fitting. This PASS is not a model-quality claim.

## T. Readiness for Main Step 4

**Ready for Step 4 when explicitly requested.** Preserve `jedit_4_3` as the primary held-out test and follow the predeclared diagnostic-cohort policy from Step 2. Define evaluation outputs before looking at test results; account for the small positive count, release prevalence shift, overlap, and unverified temporal ordering. Step 3 did not calculate test performance metrics or select a preferred model.

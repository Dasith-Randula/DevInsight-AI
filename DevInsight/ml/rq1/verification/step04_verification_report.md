# Main Step 4 — Model evaluation verification

- **Project:** DevInsight: An AI-Powered Software Engineering Intelligence Platform for Project Risk Prediction and Root Cause Analysis
- **Execution date:** 2026-11-12
- **Decision:** **PASS** for fixed-protocol evaluation and independent verification
- **Scope exclusions:** No retraining, threshold tuning, test-based model selection, Step 5 packaging, application/backend change, branch switch, commit, or push.

## A. Executive summary

Step 2’s split verifier and Step 3’s isolated-environment model verifier both passed before evaluation. The evaluation protocol was written and checksum-frozen before scoring: positive class 1, common threshold 0.50, validation before the untouched full test, and a deterministic all-negative baseline. Both frozen model artifacts and fixed release CSVs passed hash/schema checks. The evaluation generated validation, full-test, and predefined novel-feature-vector diagnostic metrics and plots.

The independent verifier passed all **25 assertions**, including independent metric recomputation, expected split integrity, baseline behavior, repeat evaluation, unchanged model hashes, and no application/database paths in Git status. No model was refit, no test-guided tuning occurred, and no test result was used to choose a model.

## B. Evaluation objective

Compare fixed Random Forest and XGBoost classifiers with a deterministic `Defect=0` baseline on the versioned JEdit class-level benchmark. This is a preliminary benchmark experiment only, not a claim about DevInsight’s Python/Dart GitHub repositories or production performance.

## C. Dataset and model provenance

- Workbook SHA-256: `364ab30e660ba3d78644ac717d28bb224e03648f9ad06b42a3453daee2ae0c31`.
- Training CSV (`jedit_4_1`) SHA-256: `1767f58d2664adfeb2c62dee4f8b139852c8336810da7253ca617153985f7f0d`.
- Validation CSV (`jedit_4_2`) SHA-256: `9b4b765bda5a874e4ff59c7db095db2a2276fe34167c5e931d26d2c218bf70ad`.
- Test CSV (`jedit_4_3`) SHA-256: `ca4c71b7b22f3efd1a32d52781df9ac7c5410bfeddf3da94dd78068cae8469b7`.
- Random Forest artifact SHA-256: `09d4d67e915b3025e1f5f52e294d22c3d74c900eec2df7635f5d2002912ec681`.
- XGBoost artifact SHA-256: `c6f1ebf8b78a34562cb6e90e20e4ec4be2ea6bc5f91466873beb5da59a3a4678`.
- Feature order: `CBO`, `DCC`, `ExportCoupling`, `ImportCoupling`, `NOM`, `WMC`; target `Defect`, positive class 1.

The validation and test cohorts contain 225 (178/47) and 470 (459/11) rows respectively. The model artifacts are the exact artifacts recorded in the Step 3 manifest.

## D. Frozen evaluation protocol

Protocol file: `ml/rq1/config/evaluation_config.json`; SHA-256 `04d1a226ab888e79c2048dafc4104499816c44c636c6fb01792eb913d980dd4f`.

- Primary threshold: 0.50 for both models; fixed before test scoring.
- No validation threshold search, hyperparameter search, or retraining.
- Score order: validation release, full final test release, then a clearly labeled diagnostic subset.
- Baseline: always predict class 0, with fixed score 0; no fitting.
- Confusion matrix: `[[TN, FP], [FN, TP]]`.
- Precision/F1 zero-division policy: 0.
- ROC-AUC, AP, and trapezoidal PR-AUC are null if undefined; no undefined value was replaced by zero.
- 95% Wilson intervals describe positive-class recall uncertainty only.

## E. Validation results

Validation release `jedit_4_2`: 225 rows; 178 negative / 47 positive; positive prevalence 20.89%.

| Model | Confusion matrix | Predicted + | Accuracy | Precision (1) | Recall (1) | F1 (1) | Specificity | Balanced accuracy | ROC-AUC | Average Precision | Trapezoidal PR-AUC |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Random Forest | `[[136,42],[11,36]]` | 78 | 0.7644 | 0.4615 | 0.7660 | 0.5760 | 0.7640 | 0.7650 | 0.7868 | 0.5860 | 0.5781 |
| XGBoost | `[[126,52],[14,33]]` | 85 | 0.7067 | 0.3882 | 0.7021 | 0.5000 | 0.7079 | 0.7050 | 0.7651 | 0.5390 | 0.5239 |
| Majority baseline | `[[178,0],[47,0]]` | 0 | 0.7911 | 0.0000 | 0.0000 | 0.0000 | 1.0000 | 0.5000 | 0.5000 | 0.2089 | 0.6044 |

Wilson recall intervals: Random Forest `[0.6278, 0.8640]`; XGBoost `[0.5602, 0.8135]`; baseline `[0.0000, 0.0756]`.

## F. Test results

Full untouched test release `jedit_4_3`: 470 rows; 459 negative / 11 positive; positive prevalence 2.34%.

| Model | Confusion matrix | Predicted + | Accuracy | Precision (1) | Recall (1) | F1 (1) | Specificity | Balanced accuracy | ROC-AUC | Average Precision | Trapezoidal PR-AUC |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Random Forest | `[[307,152],[4,7]]` | 159 | 0.6681 | 0.0440 | 0.6364 | 0.0824 | 0.6688 | 0.6526 | 0.5958 | 0.1035 | 0.0848 |
| XGBoost | `[[289,170],[7,4]]` | 174 | 0.6234 | 0.0230 | 0.3636 | 0.0432 | 0.6296 | 0.4966 | 0.5463 | 0.0625 | 0.0514 |
| Majority baseline | `[[459,0],[11,0]]` | 0 | 0.9766 | 0.0000 | 0.0000 | 0.0000 | 1.0000 | 0.5000 | 0.5000 | 0.0234 | 0.5117 |

Wilson recall intervals: Random Forest `[0.3538, 0.8483]`; XGBoost `[0.1517, 0.6462]`; baseline `[0.0000, 0.2588]`.

## G. Majority-class baseline results

The training release had 122 class-0 observations and 75 class-1 observations, so the fixed training-majority label is 0. The baseline predicts 0 for every validation/test/diagnostic record. It obtains 0.9766 test accuracy but 0 recall and 0 F1 for defects; high accuracy reflects the 97.66% negative test prevalence, not successful defect identification.

For the constant baseline score, ROC-AUC is 0.5 and Average Precision equals the cohort prevalence. The separately calculated trapezoidal PR area differs from AP and should not be read as Average Precision.

## H. Confusion matrix interpretation

At threshold 0.50, Random Forest found 7 of 11 test positives (TP=7, FN=4) while producing 152 false positives. XGBoost found 4 (TP=4, FN=7) and produced 170 false positives. The majority baseline found none. The plotted test matrices use rows for actual class and columns for predicted class in order 0, 1.

## I. Precision/recall/F1 analysis

Positive-class precision is low on test: 4.40% for Random Forest and 2.30% for XGBoost. Thus most predicted positives are false alarms at the fixed threshold. Recall is 63.64% and 36.36%, respectively, but estimates are uncertain with only 11 positives. The corresponding descriptive Wilson 95% intervals are wide. These observed metrics do not justify a deployment claim or a preferred-model claim.

## J. Class imbalance and prevalence shift

| Dataset | Positive / total | Positive prevalence |
|---|---:|---:|
| Train `jedit_4_1` | 75/197 | 38.07% |
| Validation `jedit_4_2` | 47/225 | 20.89% |
| Test `jedit_4_3` | 11/470 | 2.34% |
| Novel-vector diagnostic | 11/366 | 3.01% |

The severe prevalence shift from train to test makes accuracy especially misleading; a majority-negative classifier gets nearly 98% test accuracy without detecting any defect. Low test prevalence also makes precision sensitive to false positives. The diagnostic cohort is still highly imbalanced and includes the same 11 positives.

## K. ROC-AUC and Average Precision interpretation

Both target classes occur in each evaluated cohort, so ROC-AUC and AP are defined. On full test, ROC-AUC is 0.5958 (Random Forest) and 0.5463 (XGBoost); AP is 0.1035 and 0.0625 against a positive prevalence of 0.0234. These rank-based summaries are descriptive and have substantial uncertainty given 11 positive records.

Average Precision is the step-wise ranking summary from `average_precision_score`; it is not an accuracy measure and is not identical to trapezoidal PR-AUC. Both are separately recorded in the JSON/CSV. On the all-negative baseline, AP equals prevalence; the trapezoidal value differs because it linearly integrates the precision-recall curve endpoints under a constant tied score.

## L. Cross-release overlap diagnostic results

The predefined diagnostic subset has 366 rows: 355 negative and all 11 positive test observations. It excludes rows whose exact six-feature vector appears in either training or validation, but retains all novel-vector test rows and is not a new independent test. Diagnostic results:

| Model | Confusion matrix | Predicted + | Accuracy | Precision (1) | Recall (1) | F1 (1) | ROC-AUC | Average Precision | Trapezoidal PR-AUC |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Random Forest | `[[218,137],[4,7]]` | 144 | 0.6148 | 0.0486 | 0.6364 | 0.0903 | 0.5770 | 0.1127 | 0.0930 |
| XGBoost | `[[207,148],[7,4]]` | 152 | 0.5765 | 0.0263 | 0.3636 | 0.0491 | 0.5238 | 0.0689 | 0.0567 |
| Majority baseline | `[[355,0],[11,0]]` | 0 | 0.9699 | 0.0000 | 0.0000 | 0.0000 | 0.5000 | 0.0301 | 0.5150 |

No overlapping test record was removed from the primary evaluation. Matching feature values do not prove the same class identity.

## M. Reproducibility verification

The independent verifier ran the evaluation a second time without fitting any estimator. All saved metric values matched recomputation from the row-level predictions, and the repeat run produced matching cohort metrics. Model artifact hashes were unchanged. Model binary hashes:

- Random Forest: `09d4d67e915b3025e1f5f52e294d22c3d74c900eec2df7635f5d2002912ec681`
- XGBoost: `c6f1ebf8b78a34562cb6e90e20e4ec4be2ea6bc5f91466873beb5da59a3a4678`

Evaluation prediction CSV SHA-256: `db64d38963428c0c038edca955241ed72bfcec4467342999265c0ba757222868` (3,183 cohort/model rows). Comparison CSV SHA-256: `6ed825cbd70f4a8f1f457ec2865f42c2a27484ec9aa870c9525df21a3c4204d6`.
Evaluation metrics JSON SHA-256 after the Step 5 audit's latest successful Step 4 verification run: `83c600cb0f6301ba37423f2dd1c1fd9d32e17df2540627f93de16c6f41857816`. The verifier reruns the frozen evaluator, which writes a fresh UTC timestamp into this JSON; consequently, its file checksum can change while the validated metrics and prediction results remain the same.

## N. Data leakage prevention

The evaluator checks fixed workbook, split, and model hashes plus release assignments. It uses `predict_proba` from the saved model artifacts and selects the probability column for class 1 explicitly. It contains no `fit`, `fit_transform`, or `partial_fit` calls. The protocol fixed threshold 0.50 before scoring. No validation threshold was tuned, no hyperparameters changed, and test results did not guide model selection. Test rows were scored only after protocol freeze and validation scoring.

## O. Actual commands executed

From the `DevInsight` directory (PowerShell):

```powershell
python -B ml\rq1\scripts\02_verify_splits.py
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\03_verify_training.py
ml\rq1\.venv\Scripts\python.exe -c "import matplotlib, importlib.metadata as m; print('matplotlib',m.version('matplotlib'))"
ml\rq1\.venv\Scripts\python.exe -m pip install --disable-pip-version-check matplotlib
ml\rq1\.venv\Scripts\python.exe -B -m py_compile ml\rq1\scripts\04_evaluate_models.py ml\rq1\scripts\04_verify_evaluation.py
ml\rq1\.venv\Scripts\python.exe -m json.tool ml\rq1\config\evaluation_config.json
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\04_evaluate_models.py
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\04_verify_evaluation.py
python -m json.tool ml\rq1\results\step04_evaluation_metrics.json
python -m json.tool ml\rq1\progress.json
git diff --check
git status --short --branch
git branch --show-current
git rev-parse HEAD
```

The prerequisite verifiers passed: Step 2 **17/17**, Step 3 **16/16**. Final Step 4 verifier output: `status=PASS`, **25 assertions** passed, with repeat evaluation metrics matching. Matplotlib 3.11.2 installed successfully in the isolated ML environment.

## P. Complete verification assertions

All **25** independent assertions passed:

1. `accuracy_precision_recall_f1_recomputed`
2. `balanced_accuracy_specificity_recomputed`
3. `confusion_matrices_sum_to_samples`
4. `dataset_and_training_input_hashes_unchanged`
5. `diagnostic_subset_definition_and_counts_correct`
6. `diagnostic_subset_verified`
7. `evaluation_files_valid_json_and_csv` (including comparison values and checksums)
8. `evaluation_json_and_prediction_csv_parse`
9. `exactly_six_approved_features_used`
10. `full_test_has_470_rows_and_11_positives`
11. `majority_baseline_predicts_zero_for_every_row`
12. `model_artifact_hashes_unchanged_after_evaluation`
13. `model_checksums_match_training_manifest`
14. `models_load_with_expected_class_and_feature_order`
15. `no_application_or_database_files_modified`
16. `no_model_refitted`
17. `no_refit_test_tuning_or_selection`
18. `one_prediction_per_sample_model_and_cohort`
19. `positive_class_is_defect_one`
20. `probability_outputs_finite_and_between_zero_and_one`
21. `repeated_evaluation_metrics_match`
22. `required_visualizations_exist`
23. `threshold_frozen_at_0_50`
24. `training_input_hash_unchanged`
25. `validation_and_test_releases_correctly_assigned`

## Q. Errors and fixes

- Matplotlib was not installed in the ML virtual environment; it was installed there as **3.11.2** and pinned in `requirements.txt`.
- First evaluator attempt found a key mismatch between `training_csv` configuration naming and the evaluator’s split iteration; corrected before scores were generated.
- The first independent verifier attempt found the same naming mismatch, then a comparison-row-count assertion incorrectly expected one row per prediction rather than one row per cohort/model. Both verifier issues were corrected; final independent verification passed all 25 assertions.
- No model artifact, model parameter, threshold, or dataset was changed to address these tooling issues.

## R. Limitations and threats to validity

- Java class-level benchmark, not DevInsight’s Python/Dart GitHub files.
- Release-order holdout; release calendar dates and label-observation windows are not independently verified.
- Class prevalence shifts from 38.07% train to 2.34% test.
- Test has only 11 positive observations; recall confidence intervals are wide.
- Cross-release feature-vector overlap and conflicting-label matches remain.
- Very low test precision and test balanced accuracy near 0.5 for XGBoost; high baseline accuracy is caused by class imbalance.
- Evaluation is one fixed benchmark split, not external validation or production performance.

## S. Generated file list

- `ml/rq1/config/evaluation_config.json`
- `ml/rq1/scripts/04_evaluate_models.py`
- `ml/rq1/scripts/04_verify_evaluation.py`
- `ml/rq1/results/step04_evaluation_metrics.json`
- `ml/rq1/results/step04_model_comparison.csv`
- `ml/rq1/results/predictions/step04_predictions.csv` (Git-ignored)
- `ml/rq1/results/figures/confusion_validation.png` (Git-ignored)
- `ml/rq1/results/figures/confusion_test.png` (Git-ignored)
- `ml/rq1/results/figures/precision_recall_validation.png` (Git-ignored)
- `ml/rq1/results/figures/precision_recall_test.png` (Git-ignored)
- `ml/rq1/results/figures/roc_validation.png` (Git-ignored)
- `ml/rq1/results/figures/roc_test.png` (Git-ignored)
- `ml/rq1/results/figures/test_model_comparison.png` (Git-ignored)
- `ml/rq1/reports/step04_model_evaluation.md`
- This verification report: `ml/rq1/verification/step04_verification_report.md`
- Updated `ml/rq1/requirements.txt`, `ml/rq1/.gitignore`, `ml/rq1/README.md`, `ml/rq1/progress.md`, and `ml/rq1/progress.json`

No source CSV, raw workbook, model binary, Step 1–3 evidence, application, or database configuration was modified.

## T. Git branch and worktree status

The branch remained `Research`, HEAD remained `9362ace7f4ab56800a0d1efa83f1c45b2c0080c9`. No branch switch, stage, commit, or push occurred. Existing unrelated untracked research files were preserved. Generated predictions and figures are Git-ignored; model files and the ML environment remain ignored.

## U. Final decision

**PASS — Main Step 4 evaluation and independent verification.** Scores are genuine, reproducible results from the frozen threshold/protocol and verified local artifacts. The PASS establishes execution integrity, not model adequacy or generalization.

## V. Readiness for Main Step 5

Step 4 is complete. Main Step 5 may begin only when explicitly requested. Preserve the frozen artifacts, raw scores, the 0.50 threshold, and the caveats above. Do not recast these benchmark results as live DevInsight predictions or evidence of Python/Dart GitHub performance.

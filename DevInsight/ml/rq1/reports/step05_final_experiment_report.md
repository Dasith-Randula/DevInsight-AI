# DevInsight RQ1 — Final preliminary experiment report

## 1. Research title

**DevInsight: An AI-Powered Software Engineering Intelligence Platform for Project Risk Prediction and Root Cause Analysis**

## 2. Abstract and experiment overview

This report packages the completed preliminary RQ1 machine-learning experiment. Random Forest and XGBoost were trained on 197 JEdit Java-class observations from `jedit_4_1`, then evaluated under a fixed release-order holdout on `jedit_4_2` and `jedit_4_3`, with an all-negative baseline. The threshold was fixed at 0.50 before evaluation. The primary test contains 470 rows but only 11 positive cases. Both learned models have low test precision; the all-negative baseline's high test accuracy is caused by the severe class imbalance and it detects no positive cases.

These are results from a Java class-level benchmark. They are **not predictions for the ten selected GitHub repositories**, are not evidence that DevInsight identifies code errors in connected repositories, and do not establish production readiness, file-level validity, or cross-project generalization.

## 3. RQ1 research question

The approved proposal's RQ1 asks about predicting code errors and bug-prone files from software-project signals. This preliminary benchmark assesses whether fixed tree-based models can classify defect labels in versioned JEdit class data. The benchmark does not contain the proposal's repository-level histories or its intended file-level GitHub target.

## 4. First-half experiment scope

The completed scope includes source/data validation, deterministic release-preserving preprocessing, fixed Random Forest and XGBoost training, a frozen holdout evaluation, a baseline comparison, and independent verification. This package does not implement RQ2 or RQ3, connect a model to FastAPI or Flutter, or evaluate DevInsight's ten selected GitHub repositories.

## 5. Dataset and source

The selected dataset is the JEdit project from the regenerated PROMISE/Bug Prediction Dataset workbook. It contains five version-labeled Java class releases and 1,247 rows total. The three selected releases account for 892 rows; `jedit_3_2_1` and `jedit_4_0` remain unused in the train/validation/test partitions.

## 6. Dataset provenance and license

Source: [Zenodo record 4625975](https://zenodo.org/records/4625975), “Software Defect Prediction Datasets,” version 1, DOI [10.5281/zenodo.4625975](https://doi.org/10.5281/zenodo.4625975). Zenodo metadata reports **CC BY 4.0** for this record. The raw workbook path is `ml/rq1/datasets/raw/promise_regenerated_candidates.xlsx`; SHA-256 is `364ab30e660ba3d78644ac717d28bb224e03648f9ad06b42a3453daee2ae0c31`.

Attribution: Sultan Alhusain, “Predicting Relative Thresholds for Object Oriented Metrics,” 2021 IEEE/ACM International Conference on Technical Debt, pp. 55–63, DOI [10.1109/TechDebt52882.2021.00015](https://doi.org/10.1109/TechDebt52882.2021.00015); author manuscript [arXiv:2103.11442](https://arxiv.org/abs/2103.11442). The cited dataset-preparation description documents the binary mapping from class defect counts: one or more defects is faulty; zero defects is not faulty.

## 7. Prediction unit and target labels

The prediction unit is **one Java class observation in one JEdit release**, not a GitHub file. `Defect=0` represents zero recorded defects; `Defect=1` represents at least one recorded defect. The workbook contains the original binary labels, not the underlying defect counts, linked issues, or defect-observation windows.

## 8. Features and definitions

The exact model input order is `CBO`, `DCC`, `ExportCoupling`, `ImportCoupling`, `NOM`, `WMC`. `ClassName` and the target are not predictors. The feature names are retained as supplied by the workbook; its tables do not document all computation formulas or the direction convention for the two coupling fields.

| Feature | Name/interpretation |
|---|---|
| `CBO` | Coupling Between Objects metric name. |
| `DCC` | Direct Class Coupling metric name. |
| `ExportCoupling` | Dataset-provided export-coupling measure; exact formula/direction is not documented in the workbook. |
| `ImportCoupling` | Dataset-provided import-coupling measure; exact formula/direction is not documented in the workbook. |
| `NOM` | Number of Methods metric name. |
| `WMC` | Weighted Methods per Class metric name. |

These are Java object-oriented structural/coupling metrics, not commit-frequency, changed-line, contributor, issue-link, static-analyzer-warning, or CI-failure features.

## 9. Data quality and limitations

The five JEdit sheets share the same eight source columns: `ClassName`, the six numeric metrics, and `Defect`. No missing cells or nonnumeric/non-finite metric values were found. There are no duplicate full rows within a release. Repeated feature-vector excesses by release are 6, 5, 6, 4, and 31 for `jedit_3_2_1`, `jedit_4_0`, `jedit_4_1`, `jedit_4_2`, and `jedit_4_3`, respectively. One conflicting-vector group occurs in `jedit_4_0`, and one in `jedit_4_3`. Shared feature vectors and some conflicting labels also occur between releases. A matching vector does not prove that records represent the same class identity.

For the selected partitions, train/validation share 59 unique vectors across 70 row-pair matches (12 conflicting-label matches); train/test share 38 vectors across 59 row-pair matches (9 conflicting-label matches); validation/test share 89 vectors across 109 row-pair matches (5 conflicting-label matches). These are feature-vector overlap counts, not counts of proven repeated class identities.

## 10. Preprocessing

Only the six approved numeric features and the original binary `Defect` target were written to each processed CSV. Source row indices and `ClassName` are kept separately in the split manifest. All selected rows and labels were retained. No imputation, scaling, deduplication, label voting/relabeling, or random redistribution was performed. No fitted transformation was needed.

## 11. Release-order split methodology

Whole releases were assigned to partitions and were not mixed:

| Partition | Release | Rows | `Defect=0` | `Defect=1` | CSV SHA-256 |
|---|---|---:|---:|---:|---|
| Training | `jedit_4_1` | 197 | 122 | 75 | `1767f58d2664adfeb2c62dee4f8b139852c8336810da7253ca617153985f7f0d` |
| Validation | `jedit_4_2` | 225 | 178 | 47 | `9b4b765bda5a874e4ff59c7db095db2a2276fe34167c5e931d26d2c218bf70ad` |
| Testing | `jedit_4_3` | 470 | 459 | 11 | `ca4c71b7b22f3efd1a32d52781df9ac7c5410bfeddf3da94dd78068cae8469b7` |

This is a **release-order holdout**, not a fully verified chronological/temporal evaluation: calendar release dates and defect-observation windows were not independently verified. Positive prevalence shifts from 38.071% in training to 20.889% in validation and 2.340% in testing.

## 12. Random Forest methodology

`RandomForestClassifier` was fitted on the training release only. The saved model was loaded for Step 4 scoring; the evaluation did not refit it.

## 13. XGBoost methodology

`XGBClassifier` was fitted on the same training-only release. The saved model was loaded for Step 4 scoring; the evaluation did not refit it.

## 14. Training configurations

Both configurations used `random_state=42` and `n_jobs=1`.

| Model | Fixed configuration |
|---|---|
| Random Forest | `n_estimators=200`, `max_depth=5`, `min_samples_leaf=3`, `class_weight="balanced"` |
| XGBoost | `n_estimators=150`, `max_depth=3`, `learning_rate=0.05`, `subsample=1.0`, `colsample_bytree=1.0`, `objective="binary:logistic"`, `eval_metric="logloss"`, `tree_method="hist"` |

No hyperparameter search was performed. Validation/test labels were not used for training or model selection.

## 15. Class imbalance handling

Random Forest uses `class_weight="balanced"`, calculated from the training labels. XGBoost uses `scale_pos_weight = 122 / 75 = 1.6266666666666667`, calculated from the training release only. Neither setting uses validation or test labels.

## 16. Validation results

The validation cohort has 225 rows (178 negative, 47 positive). Metrics below are full-precision values from `results/step04_evaluation_metrics.json`; confusion matrices are `[[TN, FP], [FN, TP]]`.

| Model | Confusion matrix | Accuracy | Precision (1) | Recall (1) | F1 (1) | Specificity | Balanced accuracy | ROC-AUC | Average Precision | Trapezoidal PR-AUC |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Random Forest | `[[136,42],[11,36]]` | 0.7644444444444445 | 0.46153846153846156 | 0.7659574468085106 | 0.576 | 0.7640449438202247 | 0.7650011953143676 | 0.78675591680612 | 0.585984586297168 | 0.5781204642265395 |
| XGBoost | `[[126,52],[14,33]]` | 0.7066666666666667 | 0.38823529411764707 | 0.7021276595744681 | 0.5 | 0.7078651685393258 | 0.704996414056897 | 0.7650609610327516 | 0.5390196428705561 | 0.5239405713976697 |
| All-negative baseline | `[[178,0],[47,0]]` | 0.7911111111111111 | 0.0 | 0.0 | 0.0 | 1.0 | 0.5 | 0.5 | 0.2088888888888889 | 0.6044444444444445 |

## 17. Test results

The primary test is the full `jedit_4_3` release: 470 rows (459 negative, 11 positive). The fixed threshold is 0.50.

| Model | Confusion matrix | Accuracy | Precision (1) | Recall (1) | F1 (1) | Specificity | Balanced accuracy | ROC-AUC | Average Precision | Trapezoidal PR-AUC |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Random Forest | `[[307,152],[4,7]]` | 0.6680851063829787 | 0.0440251572327044 | 0.6363636363636364 | 0.08235294117647059 | 0.6688453159041394 | 0.6526044761338878 | 0.5957615369380076 | 0.10354424810844678 | 0.08475838716813333 |
| XGBoost | `[[289,170],[7,4]]` | 0.6234042553191489 | 0.022988505747126436 | 0.36363636363636365 | 0.043243243243243246 | 0.6296296296296297 | 0.49663299663299665 | 0.5463458110516933 | 0.06250555663742237 | 0.05135412776967349 |
| All-negative baseline | `[[459,0],[11,0]]` | 0.9765957446808511 | 0.0 | 0.0 | 0.0 | 1.0 | 0.5 | 0.5 | 0.023404255319148935 | 0.5117021276595745 |

## 18. Majority-class baseline comparison

The deterministic baseline predicts `Defect=0` for every row. It reaches 0.9765957446808511 test accuracy because 459 of 470 test labels are negative, while detecting **zero** of the 11 defective classes. Its 97.66% accuracy is therefore misleading as a defect-detection result. The baseline is included to expose the effect of class imbalance, not as evidence of useful defect ranking.

## 19. Confusion matrices

At threshold 0.50 on the primary test:

- Random Forest: TN=307, FP=152, FN=4, TP=7. It identified 7 of 11 positive cases and generated 152 false positives.
- XGBoost: TN=289, FP=170, FN=7, TP=4. It identified 4 of 11 positive cases and generated 170 false positives.
- All-negative baseline: TN=459, FP=0, FN=11, TP=0. It identified no positive cases.

## 20. ROC-AUC and Average Precision

On the full test, Random Forest ROC-AUC is 0.5957615369380076 and Average Precision (AP) is 0.10354424810844678; XGBoost ROC-AUC is 0.5463458110516933 and AP is 0.06250555663742237. AP is useful alongside threshold metrics because it summarizes ranking quality with a focus on the positive class; on a low-prevalence cohort, the no-skill constant-score AP equals positive prevalence (0.023404255319148935 here).

AP and trapezoidal PR-AUC are not interchangeable. The all-negative baseline's trapezoidal PR-AUC is 0.5117021276595745, but this does **not** show strong ranking: every baseline score is tied and constant, ROC-AUC is 0.5, and AP is exactly the test prevalence. Trapezoidal integration over the precision-recall curve's endpoint/interpolation yields the much larger area; it must be reported separately and not called AP.

With only 11 positive test cases, one additional true positive changes observed recall by 1/11. The descriptive 95% Wilson recall intervals are [0.35380117450784887, 0.8483352890463243] for Random Forest and [0.15166471095367573, 0.6461988254921511] for XGBoost. They are wide and do not provide a generalization guarantee.

## 21. Novel-vector diagnostic analysis

The predefined diagnostic subset contains test rows whose exact six-feature vector is absent from both earlier selected partitions. It has 366 rows (355 negative, 11 positive) and is diagnostic only; the primary test remains the full 470-row release.

| Model | Confusion matrix | Accuracy | Precision (1) | Recall (1) | F1 (1) | Specificity | Balanced accuracy | ROC-AUC | Average Precision | Trapezoidal PR-AUC |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Random Forest | `[[218,137],[4,7]]` | 0.6147540983606558 | 0.04861111111111111 | 0.6363636363636364 | 0.09032258064516129 | 0.6140845070422535 | 0.6252240717029449 | 0.5769526248399488 | 0.11266960815740323 | 0.0930425035711531 |
| XGBoost | `[[207,148],[7,4]]` | 0.5765027322404371 | 0.02631578947368421 | 0.36363636363636365 | 0.049079754601226995 | 0.5830985915492958 | 0.4733674775928297 | 0.5238156209987196 | 0.06885259001532602 | 0.056666191848721514 |
| All-negative baseline | `[[355,0],[11,0]]` | 0.9699453551912568 | 0.0 | 0.0 | 0.0 | 1.0 | 0.5 | 0.5 | 0.030054644808743168 | 0.5150273224043715 |

This cohort retains all 11 positive test records. Novel feature vectors do not prove novel class identity, just as a repeated vector does not prove identical class identity.

## 22. Reproducibility and verification

The Step 1 JEdit validator was rerun on the source workbook. Step 2, Step 3, and Step 4 independent verifiers were run again in the isolated ML environment. Observed outcomes: Step 2 **17/17**, Step 3 **16/16**, Step 4 **25/25** assertions passed. The Step 1 validator exited successfully and confirmed the expected schema, five releases, counts, and data conditions, with one expected false assertion for the known conflicting feature-vector groups in `jedit_4_0` and `jedit_4_3`.

The Step 3 verifier repeated the fixed training fits in memory and confirmed the same training-row probabilities; it did not replace saved artifacts. The Step 4 verifier independently recomputed saved metrics from prediction outputs and confirmed repeat-evaluation metric equality, the fixed threshold, unchanged model hashes, expected cohort sizes, and required plots. No new model artifact was trained or saved in Step 5.

The Step 4 verifier's repeat evaluation refreshes the timestamped metrics JSON. After the latest successful Step 4 verification run, the current metrics JSON SHA-256 is `83c600cb0f6301ba37423f2dd1c1fd9d32e17df2540627f93de16c6f41857816`. The Step 4 verification report had recorded a prior digest that no longer matched after this rerun; its checksum note was corrected. The verifier confirmed the saved values against the prediction rows and repeat metrics, and the Step 5 manifest records the current checksum. No metric value was replaced by the reference rounded figures.

## 23. Interpretation of results

Random Forest's observed recall is moderate (7/11, 0.6363636363636364), but precision is only 0.0440251572327044: 152 of 159 predicted positives are false alarms. XGBoost has lower observed recall (4/11, 0.36363636363636365) and precision (0.022988505747126436), with 170 false positives. Low positive prevalence means even a classifier with some sensitivity can produce many false alarms relative to the small number of true positives; this depresses precision and F1. F1 is low because it is the harmonic mean of precision and recall and is strongly constrained by the very low precision.

Accuracy alone favors the all-negative baseline because 97.66% of test rows are negative. That baseline is useless for finding positives at this operating point. Average Precision complements thresholded metrics by assessing positive-class ranking, but its value remains prevalence-dependent and uncertain with only 11 positive examples. The baseline's trapezoidal PR-AUC near 0.5117 is a tied-score integration artifact, not useful discrimination. These test results are descriptive; **no final model preference is claimed** from the already inspected test data.

## 24. Research limitations

- The experiment uses a Java class-level benchmark, not DevInsight's Python/Dart GitHub files.
- These are not real predictions for the ten selected GitHub repositories.
- The split is release-order based, not a fully verified chronological evaluation.
- The test release has only 11 positive records, making recall estimates uncertain.
- Positive prevalence shifts from 38.071% in training to 2.340% in testing.
- Feature-vector overlap and conflicting-label matches exist across/within releases; feature equality does not establish class identity.
- The workbook does not establish defect-observation windows, issue/commit traceability, or whether defect labels are cumulative/version-bounded.
- Test precision is low, and neither model is production ready.
- The findings do not prove cross-project generalization, file-level prediction validity, or deployment readiness.

## 25. Next-phase research improvements

Future work should define a traceable file-level target for the selected repositories, document defect-label windows and issue/fix links, construct repository-derived features matching the approved proposal, and validate on project- and time-separated cohorts. It should quantify repeated-entity/feature leakage, report uncertainty with enough positive cases, and predeclare baselines, decision costs, and any threshold policy before test access. External-project validation is required before generalization claims. Model-serving and RQ2/RQ3 work remain separate future scopes.

## 26. Conclusion

The fixed experiment and its package are reproducible against the recorded source, split, model, and evaluation artifacts. The result is a preliminary benchmark demonstration only. The low test precision, severe prevalence shift, 11 positive test cases, release chronology uncertainty, and Java class-level unit prevent claims about real repository prediction. Neither model is production ready, and no preferred model is selected.

## 27. Dataset and research references

1. Sultan Alhusain, [“Predicting Relative Thresholds for Object Oriented Metrics,”](https://doi.org/10.1109/TechDebt52882.2021.00015) 2021 IEEE/ACM International Conference on Technical Debt, pp. 55–63. DOI: 10.1109/TechDebt52882.2021.00015. Author manuscript: [arXiv:2103.11442](https://arxiv.org/abs/2103.11442).
2. Alhusain, [Software Defect Prediction Datasets, Zenodo record 4625975](https://zenodo.org/records/4625975), version 1, DOI: 10.5281/zenodo.4625975. Zenodo metadata reports CC BY 4.0 for the record.
3. Experiment provenance, exact configurations, full precision outputs, and independent checks are recorded in `ml/rq1/results/step05_experiment_manifest.json`, `ml/rq1/config/`, and `ml/rq1/verification/`.

# Step 4 — Model evaluation and comparison

## Frozen protocol

Evaluation used the locally verified Step 3 model artifacts and fixed Step 2 CSVs. The protocol in `ml/rq1/config/evaluation_config.json` was frozen before evaluation (SHA-256 `04d1a226ab888e79c2048dafc4104499816c44c636c6fb01792eb913d980dd4f`):

- Threshold: **0.50**, identical for both models; no threshold or hyperparameter tuning.
- Order: validation `jedit_4_2`, then full test `jedit_4_3`, followed by the predefined novel-feature-vector diagnostic subset.
- Positive class: `Defect=1`.
- Comparison: Random Forest, XGBoost, and a deterministic baseline that predicts `Defect=0` for every sample.
- Precision/F1 zero-division policy: 0. Undefined ROC/PR metrics are represented as JSON `null`.
- Recall uncertainty: descriptive 95% Wilson score interval.

No model was retrained, refitted, or selected using test outcomes.

## Results

Confusion matrices use `[[TN, FP], [FN, TP]]`. “PR trapezoid” is trapezoidal area under the precision-recall curve; it is distinct from Average Precision (AP).

### Validation — 225 rows (178 negative, 47 positive; positive prevalence 20.89%)

| Model | Confusion matrix | Predicted + | Accuracy | Precision | Recall | F1 | Specificity | Balanced accuracy | ROC-AUC | Average Precision | PR trapezoid | Recall Wilson 95% |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Random Forest | `[[136,42],[11,36]]` | 78 | 0.7644 | 0.4615 | 0.7660 | 0.5760 | 0.7640 | 0.7650 | 0.7868 | 0.5860 | 0.5781 | [0.6278, 0.8640] |
| XGBoost | `[[126,52],[14,33]]` | 85 | 0.7067 | 0.3882 | 0.7021 | 0.5000 | 0.7079 | 0.7050 | 0.7651 | 0.5390 | 0.5239 | [0.5602, 0.8135] |
| Majority baseline | `[[178,0],[47,0]]` | 0 | 0.7911 | 0.0000 | 0.0000 | 0.0000 | 1.0000 | 0.5000 | 0.5000 | 0.2089 | 0.6044 | [0.0000, 0.0756] |

### Full test — 470 rows (459 negative, 11 positive; positive prevalence 2.34%)

| Model | Confusion matrix | Predicted + | Accuracy | Precision | Recall | F1 | Specificity | Balanced accuracy | ROC-AUC | Average Precision | PR trapezoid | Recall Wilson 95% |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Random Forest | `[[307,152],[4,7]]` | 159 | 0.6681 | 0.0440 | 0.6364 | 0.0824 | 0.6688 | 0.6526 | 0.5958 | 0.1035 | 0.0848 | [0.3538, 0.8483] |
| XGBoost | `[[289,170],[7,4]]` | 174 | 0.6234 | 0.0230 | 0.3636 | 0.0432 | 0.6296 | 0.4966 | 0.5463 | 0.0625 | 0.0514 | [0.1517, 0.6462] |
| Majority baseline | `[[459,0],[11,0]]` | 0 | 0.9766 | 0.0000 | 0.0000 | 0.0000 | 1.0000 | 0.5000 | 0.5000 | 0.0234 | 0.5117 | [0.0000, 0.2588] |

### Novel-feature-vector diagnostic — 366 rows (355 negative, 11 positive; prevalence 3.01%)

This diagnostic contains test rows whose exact six-feature vector is absent from both selected training and validation releases. It is not a replacement or independent test set.

| Model | Confusion matrix | Predicted + | Accuracy | Precision | Recall | F1 | Specificity | Balanced accuracy | ROC-AUC | Average Precision | PR trapezoid | Recall Wilson 95% |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Random Forest | `[[218,137],[4,7]]` | 144 | 0.6148 | 0.0486 | 0.6364 | 0.0903 | 0.6141 | 0.6252 | 0.5770 | 0.1127 | 0.0930 | [0.3538, 0.8483] |
| XGBoost | `[[207,148],[7,4]]` | 152 | 0.5765 | 0.0263 | 0.3636 | 0.0491 | 0.5831 | 0.4734 | 0.5238 | 0.0689 | 0.0567 | [0.1517, 0.6462] |
| Majority baseline | `[[355,0],[11,0]]` | 0 | 0.9699 | 0.0000 | 0.0000 | 0.0000 | 1.0000 | 0.5000 | 0.5000 | 0.0301 | 0.5150 | [0.0000, 0.2588] |

## Interpretation and limitations

The training positive prevalence was **38.07%** (75/197), compared with **20.89%** in validation and **2.34%** in test. This pronounced release prevalence shift matters. The all-negative baseline reaches **97.66% test accuracy** solely because 459/470 test labels are negative, while it detects none of the 11 positive classes. Accuracy alone therefore obscures defect detection.

At the fixed 0.50 threshold, Random Forest detects 7/11 test positives and XGBoost detects 4/11, but they also predict 159 and 174 positives, respectively, yielding only 4.40% and 2.30% positive precision. Their test ROC-AUCs are 0.5958 and 0.5463; Average Precision is 0.1035 and 0.0625, versus test prevalence 0.0234 for the all-negative baseline. These are descriptive results for this small benchmark release, not evidence of deployment readiness or generalization. The 95% Wilson recall intervals are wide because the test has only 11 positive examples.

Validation results are stronger than test results, consistent with the marked distribution/prevalence shift. No model is selected as preferred based on the test. The diagnostic novel-vector subset still contains the same 11 positive observations and remains highly imbalanced; feature-vector equality/novelty does not establish class identity.

Average Precision is the step-wise ranking summary returned by `average_precision_score`, not accuracy. Trapezoidal PR area is separately calculated from the precision-recall curve. For the constant-score all-negative baseline, those two summaries differ substantially due to the curve endpoint/interpolation; AP equals the positive prevalence and is the more interpretable baseline comparison here. ROC-AUC is defined for these cohorts because each has both classes; its baseline value is 0.5 for tied constant scores.

This benchmark is Java class-level data, not DevInsight’s Python/Dart GitHub files. The release split is not independently verified chronological time; defect-label windows are undocumented; feature vectors overlap across releases; and only 11 positives occur in the test. These results cannot establish performance on the application’s target repositories.

## Outputs

- Metrics JSON: `../results/step04_evaluation_metrics.json`
- Comparison CSV: `../results/step04_model_comparison.csv`
- Row-level predictions (Git-ignored): `../results/predictions/step04_predictions.csv`
- Figures (Git-ignored): `../results/figures/`
- Independent verification: `../verification/step04_verification_report.md`

Charts: [test confusion matrices](../results/figures/confusion_test.png), [validation confusion matrices](../results/figures/confusion_validation.png), [test comparison](../results/figures/test_model_comparison.png), [test PR curves](../results/figures/precision_recall_test.png), [test ROC curves](../results/figures/roc_test.png), [validation PR curves](../results/figures/precision_recall_validation.png), [validation ROC curves](../results/figures/roc_validation.png).

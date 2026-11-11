# Step 3 — Training summary

## Scope and objective

Main Step 3 trained two fixed binary classifiers for preliminary Java class-level defect prediction using the Step 2 `jedit_4_1` training release only. The models support the project’s preliminary defect-prediction research, but this benchmark is not DevInsight’s Python/Dart GitHub file corpus. No held-out evaluation or product integration was performed.

## Models and training data

- **Training unit/release:** Java class observations from JEdit `jedit_4_1`.
- **Rows:** 197 (`Defect=0`: 122; `Defect=1`: 75).
- **Features, in exact order:** `CBO`, `DCC`, `ExportCoupling`, `ImportCoupling`, `NOM`, `WMC`.
- **Target:** `Defect`, unchanged; 0 means non-defective, 1 means at least one recorded defect.
- **Random Forest:** 200 trees, maximum depth 5, minimum leaf size 3, `class_weight="balanced"`, `random_state=42`, one job.
- **XGBoost:** 150 trees, depth 3, learning rate 0.05, full row/column sampling, `binary:logistic`, log-loss training objective, histogram tree method, `random_state=42`, one job.
- **Class imbalance:** Random Forest balances classes using its training labels. XGBoost `scale_pos_weight=122/75=1.6266666666666667`, computed only from the training release.

Both methods were chosen as fixed tree-based baselines suitable for tabular numeric metrics. Hyperparameters were not searched or selected against validation/test data. No input scaling or fitted preprocessing was used.

## Environment and artifacts

An isolated Python 3.14.2 environment was created at `ml/rq1/.venv/`; its directory is Git-ignored and does not replace or alter a FastAPI environment. Verified package versions:

| Package | Version |
|---|---:|
| numpy | 2.4.1 |
| pandas | 2.3.3 |
| scikit-learn | 1.8.0 |
| xgboost | 3.1.3 |
| joblib | 1.5.3 |

Artifacts are stored at:

- `ml/rq1/models/random_forest.joblib`
- `ml/rq1/models/xgboost.joblib`
- Provenance: `ml/rq1/results/step03_training_manifest.json`

The model files are Git-ignored. SHA-256 digests and timestamp are in the manifest and detailed verification report.

## Reproducibility and boundaries

The training-integrity verifier loaded each classifier and refit the same fixed configuration on the same training rows. Both training-row probability matrices were identical on repeat (`max absolute difference = 0.0`, tolerance `1e-12`). These are training-integrity checks, not evaluation metrics.

Validation/test files were checksum-verified as provenance inputs; their rows/labels were not loaded for fit, tuning, selection, or scoring. No held-out predictions, confusion matrices, accuracy, precision, recall, F1, PR-AUC, or other performance metrics were generated. Step 4 must define and report held-out evaluation separately; the final release has only 11 positive rows and substantial prevalence shift/feature-vector overlap. Release order is not verified calendar chronology.

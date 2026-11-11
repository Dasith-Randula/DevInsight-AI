# DevInsight RQ1 preliminary experiment

This package records the first-half RQ1 preliminary experiment: a Java class-level defect-prediction benchmark on versioned JEdit data. It is not a deployed DevInsight model and does not report predictions for the project's ten selected GitHub repositories.

## Research objective and boundary

The approved proposal's RQ1 concerns predicting code errors and bug-prone files using repository-derived signals. This package tests two proposed algorithms, Random Forest and XGBoost, on an available, versioned benchmark. It uses six structural Java class metrics, not the proposal's GitHub commit, issue, pull-request, contributor, or CI features. The experiment is therefore a preliminary methodological benchmark, not a validated answer for file-level GitHub prediction.

Prediction unit: one Java class observation in one JEdit release.

Target: `Defect=0` means zero recorded defects; `Defect=1` means at least one recorded defect. The workbook contains binary labels, not the original defect counts.

Features, in fixed order: `CBO`, `DCC`, `ExportCoupling`, `ImportCoupling`, `NOM`, `WMC`.

The fixed release-order holdout is `jedit_4_1` (train), `jedit_4_2` (validation), and `jedit_4_3` (test). Do not describe this as a verified chronological split: release dates and label-observation windows were not independently established. The final release contains only 11 positive rows.

## Source, attribution, and license

The selected source is the regenerated PROMISE/Bug Prediction Dataset workbook in [Zenodo record 4625975](https://zenodo.org/records/4625975), DOI [10.5281/zenodo.4625975](https://doi.org/10.5281/zenodo.4625975), version 1. Zenodo metadata reports CC BY 4.0 for this record. Attribution: Sultan Alhusain, “Predicting Relative Thresholds for Object Oriented Metrics,” 2021 IEEE/ACM International Conference on Technical Debt, pp. 55–63, DOI [10.1109/TechDebt52882.2021.00015](https://doi.org/10.1109/TechDebt52882.2021.00015); author manuscript [arXiv:2103.11442](https://arxiv.org/abs/2103.11442).

The original workbook is expected at:

```text
ml/rq1/datasets/raw/promise_regenerated_candidates.xlsx
```

The raw workbook is Git-ignored and is not included in a GitHub clone. Obtain it from the Zenodo record; do not substitute a similarly named community mirror. From the repository's `DevInsight` directory, PowerShell can download the record's workbook as follows:

```powershell
$record = Invoke-RestMethod 'https://zenodo.org/api/records/4625975'
$file = $record.files | Where-Object { $_.key -eq 'Regenerated PROMISE and BPD Datasets.xlsx' }
if (-not $file) { throw 'Expected workbook file was not found in Zenodo record 4625975.' }
New-Item -ItemType Directory -Force ml\rq1\datasets\raw | Out-Null
Invoke-WebRequest -Uri $file.links.self -OutFile ml\rq1\datasets\raw\promise_regenerated_candidates.xlsx
```

Confirm integrity before continuing:

```powershell
$expected = '364ab30e660ba3d78644ac717d28bb224e03648f9ad06b42a3453daee2ae0c31'
$actual = (Get-FileHash ml\rq1\datasets\raw\promise_regenerated_candidates.xlsx -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -ne $expected) { throw "Workbook SHA-256 mismatch: $actual" }
```

## Environment

The verified environment is Windows, Python **3.14.2**, with the exact dependency pins in `requirements.txt`. Python 3.14.2 is the version actually verified for this package; other Python versions have not been verified here. Use a package-local virtual environment so the ML dependencies do not replace or alter a FastAPI/backend environment.

From `DevInsight`:

```powershell
py -3.14 -m venv ml\rq1\.venv
ml\rq1\.venv\Scripts\python.exe -m pip install --disable-pip-version-check -r ml\rq1\requirements.txt
ml\rq1\.venv\Scripts\python.exe --version
ml\rq1\.venv\Scripts\python.exe -c "import importlib.metadata as m; print({p:m.version(p) for p in ['numpy','pandas','scikit-learn','xgboost','joblib','matplotlib']})"
```

The isolated environment is Git-ignored. Dependency installation is not needed to run the standard-library Step 1 and Step 2 data scripts, but the pinned environment is needed for model integrity/evaluation verification and for reproducing models/results.

## Package layout

| Path | Purpose |
|---|---|
| `datasets/raw/` | Acquired source workbook; Git-ignored |
| `datasets/processed/` | Deterministic train/validation/test CSVs; Git-ignored and regenerated from the source |
| `config/training_config.json` | Fixed model parameters and training-only class-imbalance policy |
| `config/evaluation_config.json` | Frozen 0.50 threshold and metric protocol |
| `scripts/02_validate_versioned_promise.py` | Step 1 JEdit workbook validator |
| `scripts/02_prepare_splits.py`, `scripts/02_verify_splits.py` | Step 2 preparation and independent split verification |
| `scripts/03_train_models.py`, `scripts/03_verify_training.py` | Step 3 training and training-artifact verification |
| `scripts/04_evaluate_models.py`, `scripts/04_verify_evaluation.py` | Step 4 frozen evaluation and independent verification |
| `scripts/05_verify_package.py` | Step 5 complete-package verifier; does not train or tune models |
| `models/` | Serialized classifiers; Git-ignored |
| `reports/step02_split_manifest.json` | Source-row traceability, release assignments, split checksums, and overlap audit |
| `results/step03_training_manifest.json` | Training provenance and model checksums |
| `results/step04_evaluation_metrics.json` | Full-precision saved evaluation results |
| `results/step04_model_comparison.csv` | Model/cohort comparison table |
| `results/predictions/` | Row-level scores and predictions; Git-ignored |
| `results/figures/` | Generated evaluation plots; Git-ignored |
| `results/step05_experiment_manifest.json` | Final experiment provenance manifest |
| `verification/step05_package_verifier_output.json` | Captured JSON stdout from the final package-verifier run |
| `reports/`, `verification/` | Human-readable experiment reports and verification evidence |

`scripts/01_validate_dataset.py` belongs to the preserved JM1 candidate workflow; it is not the selected JEdit workbook validator. Use `02_validate_versioned_promise.py` for the JEdit source.

## Reproduce from the original source

Run commands from the `DevInsight` directory. First run the selected-dataset validator:

```powershell
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\02_validate_versioned_promise.py --workbook ml\rq1\datasets\raw\promise_regenerated_candidates.xlsx --project jedit
```

Generate and verify the fixed release partitions:

```powershell
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\02_prepare_splits.py
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\02_verify_splits.py
```

The selected CSVs contain the six numeric features followed by `Defect`; identifiers and original worksheet row indices are kept in the separate split manifest. All selected source rows are retained. There is no random redistribution, imputation, scaling, deduplication, or label modification.

The following are reproduction instructions only. They are provided to make a complete rerun possible; **they were not executed as part of Main Step 5**:

```powershell
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\03_train_models.py
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\03_verify_training.py
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\04_evaluate_models.py
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\04_verify_evaluation.py
```

Training uses only the `jedit_4_1` training CSV and the fixed configuration. Evaluation loads the saved models and uses the frozen 0.50 threshold; it does not refit. Never use test results to tune thresholds, select hyperparameters, or choose a preferred model.

Verify the completed package after required inputs and generated artifacts are present:

```powershell
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\05_verify_package.py
```

The independent Step 2–4 verifiers are:

```powershell
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\02_verify_splits.py
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\03_verify_training.py
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\04_verify_evaluation.py
```

The Step 1 validator emits its observed sheet-level checks and warnings as JSON. Its known within-release conflicting-feature-vector warning is expected and documented; the conflicting rows are not changed. The Step 5 verifier reruns the source, split, and training checks, validates the recorded passing Step 4 verification evidence, and independently checks the saved evaluation arithmetic and report values. It does not retrain models or rerun the Step 4 evaluator. This avoids rewriting the timestamped metrics JSON and generated plots during package verification; run `04_verify_evaluation.py` separately when intentionally reproducing Step 4.

## GitHub and ignored artifacts

`ml/rq1/.gitignore` intentionally excludes the raw workbook, processed CSVs, `.venv`, serialized `*.joblib` models, row-level prediction outputs, and generated figures. Those files will not be available automatically after cloning. A reviewer obtains the raw source from the attributed Zenodo record, confirms its SHA-256, regenerates the splits, then follows the documented Step 3/4 commands to regenerate ignored models and outputs. The small JSON manifests, scripts, requirements, reports, and verification evidence are intended to be reviewable in Git.

Check ignore behavior from `DevInsight` with:

```powershell
git check-ignore -v ml\rq1\datasets\raw\promise_regenerated_candidates.xlsx
git check-ignore -v ml\rq1\datasets\processed\train.csv
git check-ignore -v ml\rq1\models\random_forest.joblib
git check-ignore -v ml\rq1\.venv\pyvenv.cfg
git check-ignore -v ml\rq1\results\predictions\step04_predictions.csv
git check-ignore -v ml\rq1\results\figures\confusion_test.png
```

## Interpretation limits

This is a release-order evaluation on Java class-level metrics, not a fully verified temporal evaluation and not a prediction experiment on the ten selected GitHub repositories. The six metrics do not represent the proposal's commit frequency, changed lines, contributors, issue/bug-history links, analyzer findings, or CI failures. Prevalence changes from 38.07% in training to 2.34% in testing; the test release has only 11 positive labels. Feature-vector overlap and conflicting-label matches remain, and metric equality does not prove class identity. The models have low test precision and are not production ready. These findings do not establish file-level validity, cross-project generalization, or deployment readiness.

See `reports/step05_final_experiment_report.md`, `reports/step05_rq1_proposal_alignment.md`, and `verification/step05_verification_report.md` for the complete results, alignment audit, and reproducibility evidence. Step 5 does not begin RQ2/RQ3 or integrate a model into FastAPI or Flutter.

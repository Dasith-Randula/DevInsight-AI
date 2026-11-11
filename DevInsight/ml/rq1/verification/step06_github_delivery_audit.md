# Main Step 6 — RQ1 ML GitHub delivery audit

## 1. Git branch and HEAD

- Branch: `Research`
- HEAD: `9362ace7f4ab56800a0d1efa83f1c45b2c0080c9`
- Initial audit state: no staged files and no tracked-file diffs.
- No stage, commit, push, merge, or branch switch was performed.

## 2. RQ1 package verification

Command:

```powershell
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\05_verify_package.py
```

Result: **PASS, 23/23 assertions**. Step 2, 3, and 4 prerequisite verifiers passed 17/17, 16/16, and 25/25 assertions. The Step 1 validator exited successfully and retained its known conflicting-feature-vector warning. The Step 5 progress estimate remains 96%; no Step 6 completion status was added.

## 3. Classification of every file under `ml/rq1/`

The recursive inventory contains **13,094 files** after adding this audit report:

| Category | Count | Classification |
|---|---:|---|
| 1. Source code | 9 | `scripts/*.py`; all are reviewable source. The JM1 validator is preserved candidate-workflow code and is explicitly identified as non-selected in the README. |
| 2. Configuration | 5 | `.gitignore`, `progress.json`, `requirements.txt`, and the two training/evaluation JSON configs. |
| 3. Research documentation | 9 | `README.md`, `progress.md`, and the seven entries under `reports/` (including the generated Step 2 split manifest, withheld from staging below). |
| 4. Verification evidence | 8 | Step 1–6 reports and captured Step 5 verifier JSON output. |
| 5. Small trackable results | 4 | Step 3 training manifest, Step 4 metrics JSON, Step 4 comparison CSV, and Step 5 experiment manifest. Two JSON outputs are withheld due to portability/checksum concerns below. |
| 6. Raw or processed data | 6 | Three raw files (`jm1.arff`, `kc1.arff`, Zenodo workbook) and three processed split CSVs; ignored. |
| 7. Trained model binaries | 2 | Random Forest and XGBoost `.joblib`; ignored. |
| 8. Virtual environment | 13,036 | All files below `ml/rq1/.venv/`; ignored. |
| 9. Generated predictions / figures | 8 | One row-level prediction CSV and seven PNGs; ignored. |
| 10. Temporary or cache files | 7 | Python bytecode/cache files; ignored. |

The counts include the Step 2 split manifest under research documentation and the generated JSON outputs under small results; categories are mutually exclusive. The full inventory has 51 files outside the virtual environment and cache category. No unexpected file category was found.

## 4. Source files approved for Git

Approved source paths:

- `ml/rq1/scripts/01_validate_dataset.py`
- `ml/rq1/scripts/02_prepare_splits.py`
- `ml/rq1/scripts/02_validate_versioned_promise.py`
- `ml/rq1/scripts/02_verify_splits.py`
- `ml/rq1/scripts/03_train_models.py`
- `ml/rq1/scripts/03_verify_training.py`
- `ml/rq1/scripts/04_evaluate_models.py`
- `ml/rq1/scripts/04_verify_evaluation.py`
- `ml/rq1/scripts/05_verify_package.py`

Approved configuration and environment paths:

- `ml/rq1/.gitignore`
- `ml/rq1/config/evaluation_config.json`
- `ml/rq1/config/training_config.json`
- `ml/rq1/progress.json`
- `ml/rq1/progress.md`
- `ml/rq1/requirements.txt`

## 5. Results and reports approved for Git

The following documentation/evidence is approved for the proposed staging subset:

- `ml/rq1/README.md`
- `ml/rq1/reports/step01_dataset_comparison.md`
- `ml/rq1/reports/step01_dataset_validation.md`
- `ml/rq1/reports/step03_training_summary.md`
- `ml/rq1/reports/step04_model_evaluation.md`
- `ml/rq1/reports/step05_final_experiment_report.md`
- `ml/rq1/reports/step05_rq1_proposal_alignment.md`
- `ml/rq1/verification/step01_resolution_report.md`
- `ml/rq1/verification/step01_verification_report.md`
- `ml/rq1/verification/step02_verification_report.md`
- `ml/rq1/verification/step03_verification_report.md`
- `ml/rq1/verification/step04_verification_report.md`
- `ml/rq1/verification/step05_package_verifier_output.json`
- `ml/rq1/verification/step05_verification_report.md`
- This audit: `ml/rq1/verification/step06_github_delivery_audit.md`

Small results approved in the proposed staging subset:

- `ml/rq1/results/step03_training_manifest.json`
- `ml/rq1/results/step04_model_comparison.csv`

The Step 4 comparison CSV has no machine-specific path fields. It is a compact table; its digest is `6ed825cbd70f4a8f1f457ec2865f42c2a27484ec9aa870c9525df21a3c4204d6`.

## 6. Files to remain ignored or withheld

### Intentionally Git-ignored

- `ml/rq1/datasets/raw/` — `jm1.arff`, `kc1.arff`, and `promise_regenerated_candidates.xlsx`.
- `ml/rq1/datasets/processed/` — `train.csv`, `validation.csv`, `test.csv`.
- `ml/rq1/models/` — `random_forest.joblib`, `xgboost.joblib`.
- `ml/rq1/.venv/` — all 13,036 environment files.
- `ml/rq1/scripts/__pycache__/` and other Python bytecode/cache files.
- `ml/rq1/results/predictions/step04_predictions.csv`.
- `ml/rq1/results/figures/` — seven generated PNG charts.

The README documents that ignored graphs and predictions are reproducible outputs, not GitHub assets. The graphs are regenerated by `04_evaluate_models.py`; the README's acquisition and regeneration sequence describes the required raw workbook and model artifacts.

### Withhold from the proposed Git staging set pending path portability work

- `ml/rq1/reports/step02_split_manifest.json`
- `ml/rq1/results/step04_evaluation_metrics.json`
- `ml/rq1/results/step05_experiment_manifest.json`

The first two contain absolute `C:\Users\User\Desktop\FYP\Project\DevInsight-AI\DevInsight\...` paths. The Step 5 manifest refers to the current metrics checksum, which is tied to the timestamped, machine-specific Step 4 JSON; it should be refreshed after the portable-output correction. These three files are not ignored by `.gitignore`, so they must be explicitly excluded from the exact staging command below.

## 7. Machine-specific path findings

### Step 2 split manifest: absolute paths are provenance-only for current verification

`reports/step02_split_manifest.json` records absolute paths in six provenance fields: `outputs.train.path`, `outputs.validation.path`, `outputs.test.path`, `scripts.preparation_script`, `scripts.validator_script`, and `source_workbook`. The current Step 2/3/4 scripts do not use those `path` strings to locate inputs:

- `02_verify_splits.py` resolves workbook, CSV, and manifest locations from command-line defaults rooted at the repository, and checks manifest row counts and SHA-256 values rather than its recorded output paths.
- `03_train_models.py` reads the split assignments and `outputs[*].sha256`; it locates files via relative paths in `training_config.json`.
- Step 4 scripts read release assignments and counts from the split manifest and resolve actual data/model paths from the evaluation config.

Therefore those absolute path values are historical provenance metadata, not the current execution dependency. They nevertheless expose the checkout layout and are not portable metadata.

### Step 4 metrics JSON: absolute figure paths break independent verification elsewhere

`results/step04_evaluation_metrics.json` stores all seven generated figure paths as absolute paths. Unlike the Step 2 manifest fields, these paths are consumed by `scripts/04_verify_evaluation.py`, which tests `Path(results["figures"][key]).is_file()` directly. On another Windows checkout, the original user's checkout path will not exist; on non-Windows systems the drive/backslash string is not a valid repository-relative figure location. Thus the current Step 4 verifier is not cross-machine portable with the saved metrics JSON as-is.

The Step 4 metrics JSON also has a timestamp refreshed by repeated evaluation. Its SHA-256 is `83c600cb0f6301ba37423f2dd1c1fd9d32e17df2540627f93de16c6f41857816` in this checkout, but a rerun changes its timestamp and file hash even when metric values and prediction rows are identical.

### Minimal recommended portable correction (not applied)

1. Change the Step 2 manifest writer to record project-relative POSIX paths for workbook, split files, and script metadata; retain SHA-256/count provenance. Regenerate the manifest and rerun Step 2 verification; explicitly update the Step 2 report's manifest checksum.
2. Change the Step 4 evaluator to serialize figure paths as repository-relative POSIX paths. Change the Step 4 verifier to resolve relative paths from `ROOT` (optionally continuing to accept absolute paths for backward compatibility).
3. Rerun only the prescribed Step 4 evaluator/verifier with the existing models, frozen 0.50 threshold, and same data. Independently confirm every metric value and prediction hash is unchanged; update the metrics/Step 5 manifest hashes and report notes to match the newly generated files.
4. Rerun the Step 5 package verifier and record the new output.

This audit did not edit the source manifests, metrics, checksums, evaluation code, or prior Step 1–5 statuses. Do not stage the withheld files as if they were portable; make and document the correction as a separate, explicit change before delivering the complete result package.

## 8. Reproducibility, secrets, and large-file audit

- README commands point to existing selected-workflow scripts; the Step 1 JEdit validator is correctly identified as `02_validate_versioned_promise.py`, not the legacy JM1 `01_validate_dataset.py`.
- `requirements.txt` pins the six installed packages, matching the verified Python 3.14.2 environment. README states the tested version and uses a separate Windows virtual environment.
- Dataset download instructions select the Zenodo workbook by key, check for a missing file, and give the expected SHA-256. Attribution and CC BY 4.0 record scope are stated.
- Script entry points use repository-root-relative defaults/config paths. The Step 2 manifest's absolute path values are not consumed for execution as detailed above.
- Source/split/model/evaluation checksums are recorded. The timestamped metrics JSON is not byte-stable, and its figure paths are machine-specific; do not claim portable byte-for-byte package reproducibility until corrected.
- The README says generated graphs/predictions are ignored and gives regeneration instructions; they are not promised as GitHub assets.
- Credential-pattern scan over proposed text/code/config/manifest candidates found no GitHub tokens, AWS access-key patterns, Supabase `sbp_` tokens, JWT-shaped strings, or private-key headers. This is a pattern scan, not proof that all possible secrets are absent.
- No non-virtual-environment file under `ml/rq1/` exceeds 1 MiB. The largest proposed trackable code file is `scripts/04_evaluate_models.py` at 30,616 bytes. The raw workbook, model binaries, and generated outputs are small individually but remain excluded by category/ignore policy.
- All four protected files still exist and are untracked: `data/bug_fix_review.csv`, `data/bug_fix_review_timeline_cache.json`, `data/bug_issue_samples_pilot.csv`, and `data/repository_bug_audit_pilot.csv`. They are not included in the add command.
- No staged files, tracked diffs, or unrelated application paths were found. Nonignored candidates are confined to `ml/rq1/`; four unrelated research files remain untracked outside it.

## 9. Exact recommended `git add` command

The command below stages **32** reviewed source/configuration/documentation/evidence/compact-result files, including this audit. It intentionally excludes the three withheld JSON paths above and does not include any data, model, environment, prediction, figure, or unrelated research file. It has **not** been run.

```powershell
git add -- `
  ml/rq1/.gitignore `
  ml/rq1/README.md `
  ml/rq1/config/evaluation_config.json `
  ml/rq1/config/training_config.json `
  ml/rq1/progress.json `
  ml/rq1/progress.md `
  ml/rq1/requirements.txt `
  ml/rq1/reports/step01_dataset_comparison.md `
  ml/rq1/reports/step01_dataset_validation.md `
  ml/rq1/reports/step03_training_summary.md `
  ml/rq1/reports/step04_model_evaluation.md `
  ml/rq1/reports/step05_final_experiment_report.md `
  ml/rq1/reports/step05_rq1_proposal_alignment.md `
  ml/rq1/results/step03_training_manifest.json `
  ml/rq1/results/step04_model_comparison.csv `
  ml/rq1/scripts/01_validate_dataset.py `
  ml/rq1/scripts/02_prepare_splits.py `
  ml/rq1/scripts/02_validate_versioned_promise.py `
  ml/rq1/scripts/02_verify_splits.py `
  ml/rq1/scripts/03_train_models.py `
  ml/rq1/scripts/03_verify_training.py `
  ml/rq1/scripts/04_evaluate_models.py `
  ml/rq1/scripts/04_verify_evaluation.py `
  ml/rq1/scripts/05_verify_package.py `
  ml/rq1/verification/step01_resolution_report.md `
  ml/rq1/verification/step01_verification_report.md `
  ml/rq1/verification/step02_verification_report.md `
  ml/rq1/verification/step03_verification_report.md `
  ml/rq1/verification/step04_verification_report.md `
  ml/rq1/verification/step05_package_verifier_output.json `
  ml/rq1/verification/step05_verification_report.md `
  ml/rq1/verification/step06_github_delivery_audit.md
```

## 10. Expected staged files

Exactly the 32 paths in the command in Section 9. Verify after manual staging with:

```powershell
git diff --cached --name-only
git diff --cached --check
git diff --cached --stat
```

Then confirm no ignored or protected path is staged using `git status --short` and `git diff --cached --name-only`. No staging was performed by this audit.

## 11. Expected remaining untracked files after that command

The three withheld package files:

- `ml/rq1/reports/step02_split_manifest.json`
- `ml/rq1/results/step04_evaluation_metrics.json`
- `ml/rq1/results/step05_experiment_manifest.json`

And the four protected unrelated research files:

- `data/bug_fix_review.csv`
- `data/bug_fix_review_timeline_cache.json`
- `data/bug_issue_samples_pilot.csv`
- `data/repository_bug_audit_pilot.csv`

Ignored data, models, environment, predictions, and figures remain absent from ordinary `git status`; they are not to be forced into the index.

## 12. Blockers

**Blocker for complete, portable RQ1 result delivery:** the Step 4 metrics JSON embeds absolute figure paths that the independent Step 4 verifier dereferences, and the Step 2 manifest embeds absolute workstation paths. The Step 4 metrics checksum also changes on verifier reruns because its UTC timestamp changes. Withhold the Step 2 manifest, Step 4 metrics JSON, and dependent Step 5 manifest until the explicitly documented path/checksum portability correction has been implemented and verified.

There is no blocker to manually staging the safe 32-file subset for review. It is not equivalent to committing the complete reproducible experiment-output package.

## 13. Final decision

**PARTIAL — audit and safe staging plan complete; complete GitHub delivery is not yet portable.** The current package verifier passes 23/23, the branch/HEAD and worktree are unchanged, and the exact safe subset is identified. The proposed subset can be staged manually, but the three withheld JSON files need portable path/checksum handling before the full Step 1–5 result package is ready for commit/push. No files were staged, committed, pushed, merged, or deployed.

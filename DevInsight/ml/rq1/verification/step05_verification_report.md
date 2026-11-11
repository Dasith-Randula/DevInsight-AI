# Main Step 5 — Final experiment package verification

## A. Executive summary

**Decision: PASS** for the final RQ1 preliminary experiment package. The isolated Python 3.14.2 environment was used to rerun the Step 1 JEdit source validator and the Step 2–4 verifiers. Step 2 passed 17/17 assertions, Step 3 passed 16/16, and Step 4 passed 25/25. The Step 1 validator exited successfully and confirmed the expected source, five releases, schema, and counts; its one false assertion is the known, documented within-release conflicting-feature-vector warning in `jedit_4_0` and `jedit_4_3`.

The new Step 5 package verifier passed **23/23 assertions**. It checked the source/split/model checksums, frozen configurations, output metrics and confusion arithmetic, baseline behavior, report/proposal alignment, ignored-artifact handling, figures, environment, and Git safety. No new model artifact was trained or saved, no model/configuration/dataset was changed, and no test-based tuning or model selection was done. The required Step 3 integrity verifier performed its documented deterministic repeat-fit check in memory.

## B. Experiment deliverables

- `ml/rq1/reports/step05_final_experiment_report.md` — full-precision results, methodology, interpretation, limitations, and references.
- `ml/rq1/reports/step05_rq1_proposal_alignment.md` — completed, partially addressed, and future proposal scope.
- `ml/rq1/README.md` — Windows PowerShell reproducibility instructions, source acquisition/attribution, and ignore policy.
- `ml/rq1/results/step05_experiment_manifest.json` — source, split, model, config, evaluation, and environment provenance.
- `ml/rq1/scripts/05_verify_package.py` — independent final package checks.
- `ml/rq1/verification/step05_package_verifier_output.json` — captured JSON stdout from the final passing verifier run.

## C. Dataset and provenance verification

The selected source workbook exists at `ml/rq1/datasets/raw/promise_regenerated_candidates.xlsx`. Observed SHA-256: `364ab30e660ba3d78644ac717d28bb224e03648f9ad06b42a3453daee2ae0c31`, matching Step 1, Step 2, training/evaluation configs, and the final manifest. The source is Zenodo record 4625975, version 1; the record metadata reports CC BY 4.0. Attribution to Sultan Alhusain's TechDebt 2021 paper and DOI is in the reports.

The Step 1 validator output showed the expected five sheets in release identifier order: `jedit_3_2_1`, `jedit_4_0`, `jedit_4_1`, `jedit_4_2`, and `jedit_4_3`. Their row/class counts are 163 (75/88), 192 (119/73), 197 (122/75), 225 (178/47), and 470 (459/11), respectively. The expected eight-column schema and no-missing-cell check passed. Ten of its eleven assertions were true; `no_conflicting_feature_vectors_within_release` was false as expected because one such group occurs in `jedit_4_0` and one in `jedit_4_3`. This known data warning does not invalidate the recorded Step 1 selection/validation PASS and was not repaired or hidden.

## D. Preprocessing and split verification

The Step 2 independent verifier passed all 17 assertions. All 892 selected rows remain assigned whole-release: train `jedit_4_1` 197 rows (122/75), validation `jedit_4_2` 225 rows (178/47), and test `jedit_4_3` 470 rows (459/11). The identical feature order is `CBO`, `DCC`, `ExportCoupling`, `ImportCoupling`, `NOM`, `WMC`, followed by target `Defect`. No identifier is a feature. No rows were removed, created, randomly redistributed, relabeled, or transformed. The Step 2 checksum, source-row assignment, class distribution, finite numeric values, and overlap checks passed.

The predefined diagnostic cohort is 366 `jedit_4_3` rows (355 negative, 11 positive). It excludes vectors present in the earlier selected partitions for diagnostic analysis only; the full 470-row test remains primary.

## E. Training verification

The Step 3 independent verifier passed all 16 assertions. Both model binaries load as fitted classifiers with the expected classes/features and recorded hashes. The training release contains 197 rows (122 class 0, 75 class 1); the XGBoost positive weight is the training-only ratio `122/75 = 1.6266666666666667`. The verifier repeated fixed training fits in memory and found equivalent training-row probabilities; it did not replace or save model artifacts. The standalone `03_train_models.py` training command was not run in Step 5.

## F. Evaluation verification

The Step 4 verifier passed all 25 assertions, including independent recomputation from row predictions, repeated evaluation equivalence, unchanged model hashes, expected cohort counts, fixed 0.50 threshold, baseline behavior, and required visualizations. The Step 5 package verifier validates the recorded passing Step 4 evidence and independently checks the saved metrics/report arithmetic. It intentionally does not rerun `04_verify_evaluation.py`: that verifier calls the evaluator, which rewrites timestamped metrics JSON and figures as part of its repeated-evaluation test.

## G. Results consistency checks

The package verifier checked confusion-matrix row/column arithmetic and independently recomputed accuracy, positive precision/recall/F1, specificity, and balanced accuracy from each saved matrix. It checked that test/diagnostic full-precision values in the final report match the saved JSON, and that the all-negative baseline has zero true and false positives, zero precision/recall/F1, and its expected confusion matrices.

Full results, including the validation cohort, both test cohorts, ROC-AUC, Average Precision, and trapezoidal PR-AUC, are in the final experiment report and saved Step 4 outputs. The report keeps AP and trapezoidal PR-AUC distinct.

## H. Scientific interpretation audit

The final report explicitly states that:

- Results come from a Java class-level benchmark, not file-level DevInsight data.
- They are not predictions for the ten selected GitHub repositories.
- Release identifiers support only a release-order holdout, not verified chronology.
- The test release has only 11 positive rows and prevalence shifts from 38.071% in training to 2.340% in testing.
- Feature-vector overlap and conflicting-label matches remain; metric matches do not prove class identity.
- The all-negative baseline's 97.66% test accuracy detects no defects and is misleading by itself.
- Model test precision is low, neither model is production ready, and no final model preference is claimed.
- Results do not prove cross-project generalization or deployment readiness.

## I. Proposal alignment audit

The alignment report preserves the approved proposal unchanged. It marks the two model pipelines, data validation, reproducible preprocessing, release-order holdout evaluation, comparison, and research verification as implemented. Class-level defect prediction, the simple baseline, and general evaluation methodology are marked as partially addressed. File-level GitHub prediction, training on the ten selected repositories, repository-derived commit/issue/PR/CI features, reliable repository inference, FastAPI serving, RQ2, and RQ3 SHAP/LLM work are marked not yet implemented.

## J. Reproducibility assessment

The source workbook and three processed CSVs match their documented SHA-256 values. The model artifacts match the Step 3 manifest, evaluation configuration, and Step 4 provenance. The frozen training configuration, feature order, target definition, release assignments, 0.50 threshold, evaluation outputs, figures, and package manifest were checked.

The Step 4 verifier's repeated evaluation refreshes the timestamped metrics JSON. After the latest successful run, the current metrics JSON SHA-256 is `83c600cb0f6301ba37423f2dd1c1fd9d32e17df2540627f93de16c6f41857816`. The earlier Step 4 report checksum note was corrected to this observed digest. Metric values and row predictions were independently reconciled; the timestamp/hash refresh does not represent a new model, threshold, or metric-selection decision.

## K. Environment and package versions

The verified isolated interpreter is Python 3.14.2 at `ml/rq1/.venv/`. Installed versions:

| Package | Version |
|---|---:|
| numpy | 2.4.1 |
| pandas | 2.3.3 |
| scikit-learn | 1.8.0 |
| xgboost | 3.1.3 |
| joblib | 1.5.3 |
| matplotlib | 3.11.2 |

## L. Exact executed commands

Executed from the `DevInsight` directory using PowerShell:

```powershell
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\02_validate_versioned_promise.py --workbook ml\rq1\datasets\raw\promise_regenerated_candidates.xlsx --project jedit
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\02_verify_splits.py
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\03_verify_training.py
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\04_verify_evaluation.py
ml\rq1\.venv\Scripts\python.exe -B -m py_compile ml\rq1\scripts\05_verify_package.py
ml\rq1\.venv\Scripts\python.exe -m json.tool ml\rq1\results\step05_experiment_manifest.json
ml\rq1\.venv\Scripts\python.exe -B ml\rq1\scripts\05_verify_package.py
```

Final command summaries: Step 1 validator exit 0, expected five releases and one documented warning; Step 2 `status=PASS`, 17 assertions; Step 3 `status=PASS`, 16 assertions; Step 4 `status=PASS`, 25 assertions; Step 5 `status=PASS`, 23 assertions. Python syntax and manifest JSON checks passed. No Step 3 training or Step 4 model evaluation command was executed by the final Step 5 package verifier.

## M. All verification assertions

All **23** Step 5 package assertions passed:

1. `step1_evidence_and_validator_output_exist`
2. `step1_source_hash_release_schema_and_counts_verified`
3. `step1_known_conflicting_vector_warning_is_preserved`
4. `step2_independent_verifier_passes`
5. `step3_independent_verifier_passes`
6. `step4_independent_verifier_pass_is_recorded`
7. `dataset_and_split_checksums_match_all_prior_manifests`
8. `model_checksums_match_training_and_evaluation_provenance`
9. `feature_order_labels_and_release_assignments_unchanged`
10. `experiment_manifest_valid_and_consistent`
11. `training_and_evaluation_configurations_are_consistent`
12. `metrics_and_model_artifacts_match_package_manifest`
13. `saved_metrics_match_final_report_and_confusion_arithmetic`
14. `all_negative_baseline_detects_no_positive_samples`
15. `critical_scientific_limitations_are_explicit`
16. `proposal_alignment_and_implementation_status_documented`
17. `dataset_attribution_and_license_present`
18. `reproducibility_guide_references_existing_commands`
19. `git_ignored_artifact_policy_is_documented_and_effective`
20. `all_required_evaluation_figures_exist`
21. `no_tracked_or_staged_files_changed`
22. `step5_deliverables_contain_no_common_secret_patterns`
23. `runtime_environment_matches_recorded_manifest`

The Step 2, Step 3, and Step 4 assertion names and details remain in their corresponding verification reports; their final counts were 17/17, 16/16, and 25/25. Step 1's one false data-quality assertion is explicitly documented above and is not reported as passing.

## N. Warnings and limitations

- The Step 1 validator reports a known within-release conflicting-feature-vector warning in two unused/selected releases; the rows remain unchanged.
- The benchmark is one Java project and one release-order holdout, with only 11 test positives and a large prevalence shift.
- Feature overlap and unknown defect-observation windows limit independence/temporal interpretation.
- Test precision is very low; accuracy is dominated by the negative class.
- The Step 4 verifier writes a new timestamped metrics file during its repeat evaluation, so its digest changes on rerun even when verified metrics and predictions match.
- Existing model binaries, raw workbook, processed CSVs, `.venv`, figures, and row-level predictions are intentionally Git-ignored and will not be included automatically in a clone.

## O. Errors encountered and fixes

- The first package-verifier attempt found that rerunning Step 4 inside the package verifier refreshed the timestamped metrics JSON, invalidating a checksum captured before the run. The package verifier was changed to read the recorded passing Step 4 evidence and independently validate saved metrics without rerunning that output-writing verifier. The current checksum was updated in the experiment manifest and Step 4 report.
- Initial Step 5 checks exposed mismatched Markdown emphasis/terminology and ignore-policy assertion phrases; the verifier checks were aligned to the actual documented wording. Final validation passed.
- No source data, split, model artifact, model parameter, threshold, or evaluation metric was altered to resolve these documentation/checking issues.

## P. Source and artifact checksums

| Artifact | SHA-256 |
|---|---|
| Source workbook | `364ab30e660ba3d78644ac717d28bb224e03648f9ad06b42a3453daee2ae0c31` |
| Train CSV | `1767f58d2664adfeb2c62dee4f8b139852c8336810da7253ca617153985f7f0d` |
| Validation CSV | `9b4b765bda5a874e4ff59c7db095db2a2276fe34167c5e931d26d2c218bf70ad` |
| Test CSV | `ca4c71b7b22f3efd1a32d52781df9ac7c5410bfeddf3da94dd78068cae8469b7` |
| Random Forest joblib | `09d4d67e915b3025e1f5f52e294d22c3d74c900eec2df7635f5d2002912ec681` |
| XGBoost joblib | `c6f1ebf8b78a34562cb6e90e20e4ec4be2ea6bc5f91466873beb5da59a3a4678` |
| Training config | `a53c0f4fe70ae3dc6113fea25d7137105a9c40a71c4fffc187e4f75bdafb8753` |
| Evaluation config | `04d1a226ab888e79c2048dafc4104499816c44c636c6fb01792eb913d980dd4f` |
| Current metrics JSON | `83c600cb0f6301ba37423f2dd1c1fd9d32e17df2540627f93de16c6f41857816` |
| Comparison CSV | `6ed825cbd70f4a8f1f457ec2865f42c2a27484ec9aa870c9525df21a3c4204d6` |
| Prediction CSV (ignored) | `db64d38963428c0c038edca955241ed72bfcec4467342999265c0ba757222868` |

## Q. Complete created/modified file list

Created:

- `ml/rq1/reports/step05_final_experiment_report.md`
- `ml/rq1/reports/step05_rq1_proposal_alignment.md`
- `ml/rq1/results/step05_experiment_manifest.json`
- `ml/rq1/scripts/05_verify_package.py`
- `ml/rq1/verification/step05_verification_report.md`
- `ml/rq1/verification/step05_package_verifier_output.json`

Updated:

- `ml/rq1/README.md`
- `ml/rq1/progress.md`
- `ml/rq1/progress.json`
- `ml/rq1/verification/step04_verification_report.md` (corrected the observed metrics JSON digest and documented the timestamp-refresh behavior)

During the first Step 5 verifier attempt, the existing Step 4 verifier reran its evaluator and rewrote its generated outputs: `results/step04_evaluation_metrics.json` (UTC timestamp and SHA-256 refreshed), `results/step04_model_comparison.csv`, `results/predictions/step04_predictions.csv`, and the seven PNGs in `results/figures/`. The comparison and predictions SHA-256 values remained the same; the newly generated figures were checked for existence by the Step 4 verifier. No datasets, model binaries, training/evaluation configuration, application code, or unrelated research files were changed.

## R. Git branch and worktree verification

The branch remained `Research`; HEAD remained `9362ace7f4ab56800a0d1efa83f1c45b2c0080c9`. No files were staged; there were no tracked or staged diffs. The existing untracked research files outside `ml/rq1/` remained `data/bug_fix_review.csv`, `data/bug_fix_review_timeline_cache.json`, `data/bug_issue_samples_pilot.csv`, and `data/repository_bug_audit_pilot.csv`. The RQ1 directory itself is untracked in this worktree. `git check-ignore` confirmed the raw workbook, processed CSV, model binary, `.venv`, prediction CSV, and generated figure are ignored. No commit, merge, push, or branch switch occurred.

The package verifier's Git assertion checks the absence of tracked/staged diffs; untracked files are separately inventoried here because ordinary `git diff --check` does not inspect them.

## S. Final PASS/PARTIAL/BLOCKED decision

**PASS — Main Step 5 final experiment package and verification.** The package is reproducible given the ignored inputs/artifacts and the documented acquisition/regeneration steps. This PASS is not a model-quality or product-readiness claim.

## T. Readiness for GitHub research delivery

The reports, scripts, pinned requirements, JSON manifests, and verification evidence are ready for a deliberate GitHub review. Raw source data, generated splits, `.venv`, model binaries, row predictions, and figures remain ignored; a reviewer must obtain the workbook from Zenodo and follow the README to reproduce them. No staging, commit, push, deployment, or automatic GitHub delivery was performed.

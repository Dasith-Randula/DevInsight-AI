# Main Step 5 — RQ1 proposal alignment

## Purpose and comparison basis

This report compares the completed preliminary experiment with the approved RQ1 proposal without editing or rewriting that proposal. The proposal asks whether code errors and bug-prone files can be predicted using repository signals. Its planned algorithms include Random Forest and XGBoost; its planned features include commit frequency, changed lines, contributor count, bug history, static-analysis indicators, and CI/CD failure links.

The completed benchmark uses JEdit Java class observations from a regenerated PROMISE/BPD workbook. Its six predictors are `CBO`, `DCC`, `ExportCoupling`, `ImportCoupling`, `NOM`, and `WMC`. It is not trained on the project's ten selected GitHub repositories and does not predict their files.

## IMPLEMENTED

- Preliminary supervised ML experiment on the selected labeled benchmark.
- Two fixed training pipelines: Random Forest and XGBoost.
- Dataset source/schema/label validation and provenance tracking.
- Reproducible, release-preserving preprocessing and splitting.
- Release-order holdout evaluation with a frozen threshold.
- Comparison with an all-negative baseline, with metrics and plots.
- Independent verification of source/splits, model artifacts, evaluation outputs, and final package.

These items establish that the preliminary experiment was implemented and verified on its benchmark. They do not establish that the RQ1 production target has been achieved.

## PARTIALLY ADDRESSED

- **Defect prediction at class level:** the binary label supports a Java class-level benchmark, not the proposal's file-level GitHub prediction unit.
- **Baseline comparison:** an all-negative majority-class baseline is included. Additional decision- and prevalence-aware baselines remain useful in later research.
- **General evaluation methodology:** the project has a fixed holdout, class-specific metrics, a baseline, uncertainty reporting, overlap diagnostics, and independent verification. The single project/release benchmark is not external or cross-project validation.

## NOT YET IMPLEMENTED

- Validated file-level GitHub predictions.
- Training and validation on the ten selected repositories.
- Commit-, issue-, pull-request-, contributor-, and CI-derived ML features.
- Reliable inference for real connected repositories.
- FastAPI model-serving integration.
- RQ2 model implementation.
- RQ3 SHAP/LLM implementation.

## Proposal feature mapping

| Approved proposal feature | Current evidence | Alignment |
|---|---|---|
| Commit frequency | No commit timestamps or commit-history features in the benchmark. | Not implemented |
| Changed lines | No code-change or line-delta features. | Not implemented |
| Contributor count | No author or contributor features. | Not implemented |
| Bug history | `Defect` is a binary class label derived from source defect counts; counts, issue links, fixing commits, and observation windows are unavailable. | Proxy only; not the proposal's linked bug-history feature |
| Static-analysis indicators | Six object-oriented structural/coupling metrics are present; they are not analyzer warnings or findings. | Partial proxy |
| CI/CD failure links | No build, test, workflow, or CI data. | Not implemented |

## Research interpretation

The held-out results apply only to this JEdit Java class-level release-order experiment. They are **not predictions for the ten selected GitHub repositories**, do not demonstrate file-level RQ1 validity, and do not show that DevInsight can identify errors in connected repositories. The final release has only 11 positive rows, prevalence shifts sharply from training, feature vectors recur across releases, and test precision is low. Neither model is production ready, and this experiment does not establish cross-project generalization or deployment readiness.

The approved proposal remains unchanged. A future proposal-aligned phase requires a documented file-level labeling protocol, reproducible repository-derived features, leakage-aware temporal/project validation, and separate evaluation before any model-serving integration.

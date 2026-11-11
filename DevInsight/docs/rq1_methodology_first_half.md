# RQ1 Research Methodology — First-Half Evaluation

## Status and scope

This document records the first-half research status and a proposed, not yet executed, methodology for RQ1. It is not a report of a trained model or finalized labeled dataset. No machine-learning model, label table, or feature matrix has been created.

Status labels used below:

- **Completed and verified:** supported by the local files, repository metadata, and focused checks described in the [pre-training verification report](./rq1_pretraining_verification_report.md).
- **Investigated but unresolved:** examined using available evidence, but missing provenance, historical objects, or adjudication prevents a firm conclusion.
- **Planned:** a proposed second-phase method requiring supervisor approval and implementation.

## 1. Research Question 1

**Working formulation (planned for supervisor confirmation):** *To what extent can commit-level software change and process features predict whether a commit is defect-inducing in selected open-source software repositories?*

The intended prediction unit is a commit, and the intended positive outcome is a commit later supported by reviewed evidence as having introduced a defect. This formulation is not equivalent to predicting which commits fix reported bugs. The precise defect scope—including runtime, typing, API-contract, and tooling defects—must be agreed before labeling.

## 2. Research motivation and objective

Defects can increase maintenance cost and reduce software reliability. Commit-level prediction could help prioritize code review or testing by identifying changes with elevated defect risk. The objective is to evaluate whether information available at commit time is useful for predicting defect-inducing changes, while controlling for repository, language, chronology, label quality, and information leakage.

The first-half objective was to establish a credible research foundation: screen repositories, collect a bounded issue sample, assess fixing evidence, and determine whether local history supports future label and feature construction. It was not to train a model.

## 3. Selected repository justification

**Completed and verified:** Ten public repositories were selected provisionally: five Python and five Dart projects. The selection records and screening metrics are in [`research_repositories.csv`](../config/research_repositories.csv), [`repository_screening.csv`](../data/repository_screening.csv), and the [first-half selection report](./repository_selection_first_half.md). The current default branches total 52,400 commits and 7,973 target-language source files; repository-level values reconcile with the screening CSV.

The set provides variation in language, project size, and development history while remaining within the project’s defined Python/Dart scope. Local clone origins, configured branches, and manifest HEADs match. Five projects were assessed as `PROMISING_SAMPLE` and five as `FURTHER_REVIEW` based on only three sampled issues per project; all ten remain provisional. This is a feasibility-oriented selection, not a random or representative sample of all open-source software. Issue/PR query caps and unequal project workflows limit comparability.

## 4. Dataset sources

**Completed and verified:** The research evidence currently consists of:

- Repository configuration and clone manifest: [`research_repositories.csv`](../config/research_repositories.csv), [`repository_setup_manifest.csv`](../config/repository_setup_manifest.csv).
- Repository inventory and label-based audit: [`repository_screening.csv`](../data/repository_screening.csv), [`repository_bug_audit.csv`](../data/repository_bug_audit.csv).
- Main issue sample and automated review: [`bug_issue_samples.csv`](../data/bug_issue_samples.csv), [`bug_fix_review_auto.csv`](../data/bug_fix_review_auto.csv).
- Per-repository suitability totals: [`repository_suitability_matrix.csv`](../data/repository_suitability_matrix.csv).
- Pending manual adjudication template: [`bug_fix_review.csv`](../data/bug_fix_review.csv).
- Saved issue timelines: [`bug_fix_review_timeline_cache.json`](../data/bug_fix_review_timeline_cache.json).
- Local Git histories under `data/repositories/`.

The main sample contains 30 unique issues, three per repository. Its automated categories are 11 `VERIFIED_FIX`, 10 `CANDIDATE_FIX`, 3 `BUG_NO_FIX_LINK`, 2 `NOT_A_BUG`, and 4 `UNCLEAR`. The timeline cache contains 30 complete records, 231 timeline events, and 38 cross-reference events. These counts describe the existing evidence; they do not represent a commit-labeled ML population.

## 5. Bug issue evidence collection

**Completed and verified:** Existing scripts and CSVs record repository screening, bug-label issue sampling, issue/PR links, merge state, fixing-SHA evidence, and timeline data. The automated review and suitability matrix reconcile; all 30 issue keys appear once in the sample, automated review, and manual template. The manual template remains `PENDING` for all 30 cases.

**Planned:** For each candidate issue, reviewers should examine issue text and timeline, reproduction evidence when available, linked PR discussion, merge/closure state, complete PR commits, and the final target-branch change. Record source URLs, immutable commit IDs, evidence timestamps, decision rationale, reviewer identity, confidence, and disagreement resolution. Do not silently overwrite prior automated evidence.

## 6. Verified fixing-commit methodology

**Completed and verified:** The local audit checked each of the 11 `VERIFIED_FIX` recorded SHAs for SHA format, local object resolution, ancestry to the configured HEAD, parent count, and changed paths. The verifier searches local commit subjects for the linked PR number and, when possible, compares a commit with its parent. Merge commits are compared against their first parent and are not treated as ordinary one-parent commits.

The 11 recorded SHAs are syntactically valid. Eight resolve locally; three are reachable from configured HEADs; five recorded-SHA cases require mapping; and three recorded objects are unavailable locally. A local subject match for the linked PR number exists for all 11 relationships. Such a match is a mapping lead, not authoritative proof of PR membership or fix semantics. The mapped source diff is inspectable for three cases; the other eight matched diffs are unavailable. A failed Git diff is recorded with `DIFF_UNAVAILABLE` and null counts, never as zero changes.

**Investigated but unresolved:** The manual template has not been adjudicated. A locally changed source path does not prove that the patch corrects the reported defect; a PR merge flag or commit subject does not prove the recorded SHA is the merged implementation. See the per-case evidence table in the [verification report](./rq1_pretraining_verification_report.md).

**Planned:** Establish the authoritative PR commit list and target-branch merge/squash commit for each case. Identify the actual implementation commit separately from PR head, merge-sync, changelog, and test-only commits. Have reviewers verify the patch against the issue and preserve unresolved cases rather than promoting them to confirmed positives.

## 7. Defect-inducing commit identification (SZZ-style approach)

A fixing commit is not automatically defect-inducing. SZZ-style analysis starts from reviewed fixing changes, identifies deleted or modified source lines, traces those lines to earlier commits, and produces *candidate* inducing commits for manual review. Git blame alone does not establish defect causation: lines may have been moved, refactored, or changed for reasons unrelated to the reported bug.

**Investigated but unresolved:** A guarded blame attempt for a pytest source hunk failed because the historical blob was unavailable in the `blob:none` partial clone. No blamed commit or inducing label was produced. Historical blob completeness is not established.

**Planned:** After authoritative fix mapping and an approved historical-object acquisition plan, run SZZ only on eligible source-changing fixes. Exclude or separately classify test-only, documentation-only, generated, merge-sync, and out-of-scope typing changes. Record the fixing commit, affected lines, blamed candidates, tool/version and options, manual decisions, confidence, and false-positive rationale. Manually review every candidate before assigning a positive label.

## 8. Candidate positive-label methodology

**Planned:** A positive example is a commit supported by an adjudicated defect-introduction link—not a fix commit and not merely a commit adjacent to a bug report. A candidate positive should require:

1. A reviewed issue/fix relationship with reproducible provenance.
2. A verified merged implementation change that meets the frozen defect definition.
3. Source-line attribution or equivalent evidence identifying a candidate earlier commit.
4. Human review of whether that commit plausibly introduced the defect.
5. A recorded confidence and provenance trail, with uncertain cases excluded from confirmed-positive evaluation.

Related issues, duplicate fixes, and multiple candidate commits for one defect must be grouped and documented to prevent double counting and split leakage.

## 9. Candidate negative-label methodology

**Planned:** Commits without linked bugs are not automatically clean negatives. Begin with a time-bounded candidate pool and use a defensible control protocol, such as stratified sampling followed by targeted issue/history checks and independent reviewer adjudication. Exclude unresolved commits from confirmed-negative labels; preserve `unknown` as a distinct state. Report the sampling frame, observation window, review effort, and likely false-negative risk. Do not derive “negative” status solely from the absence of an issue or fix link.

**Current status:** No negative-label procedure, confirmed-negative population, or meaningful class distribution exists.

## 10. Commit-level feature engineering plan

**Planned:** Candidate features should be available at the prediction timestamp and computed using the candidate commit and strictly prior history:

- Change size: added/deleted lines, changed files, hunks, and per-file churn.
- Change shape: paths, directories, file types, production/test/configuration classification, and rename handling.
- Code properties: language-specific complexity or static properties, if reproducibly extractable.
- Prior history: file age, prior change frequency/churn, prior contributors, and author experience calculated only from earlier commits.
- Commit context: timestamp, parent count, and repository/language identifiers.

Issue labels, linked PR/fix text, future CI outcomes, post-commit review comments, future developer activity, and any target-derived fields must not be predictors. Planned features are not yet extracted or validated.

## 11. Data preprocessing strategy

**Planned:** Preserve immutable raw evidence and create versioned derived tables with source commit IDs and extraction versions. Normalize timestamps and repository identifiers; deduplicate commits and related issue/fix families; define merge, rename, generated, vendor, test, and native-platform file rules; record missingness rather than silently imputing unavailable history. Normalize or pseudonymize contributor identities only under an approved protocol. Encode categorical variables, scale numeric variables for linear models, and fit all preprocessing parameters on training data only. Keep language- and repository-specific feature semantics explicit.

## 12. Class imbalance handling

**Planned:** First report the natural training prevalence after labels are adjudicated. Compare a majority-class baseline with class-weighted models; optionally evaluate controlled undersampling or resampling only within training folds. Do not resample validation or test sets. Select thresholds on validation data and report performance at the natural prevalence. No class imbalance estimate is currently available because there is no validated label population.

## 13. Data leakage prevention

**Planned:** Define feature cutoffs at the candidate commit time. Exclude future commits, linked fixes, post-commit issue/PR data, future CI/test results, and author/file aggregates that include future history. Keep related issues, duplicate fixes, and commits for the same defect within one partition or purge cross-boundary groups. Fit preprocessing and feature selection inside each training fold. Audit every feature for target construction dependence and document which facts would have been observable at prediction time.

## 14. Proposed temporal train/test strategy

**Planned:** Use a chronological, forward-only evaluation rather than random commit splitting. A proposed initial design is the earliest 70% of eligible commit time for training, the next 15% for validation, and the latest 15% for a final test, stratified by repository where sample size permits. Freeze cut dates before model comparison. Purge or assign related defect/fix families so that no family crosses partitions; never move later observations into an earlier partition. If per-repository samples are too small, use expanding-window temporal validation and report that limitation. Reserve any cross-repository holdout for a separate generalization question. Final proportions and purge rules require review once the labeled population is known.

## 15. Proposed experimental ML baselines

**Planned:** Start with a majority-class baseline and Logistic Regression as an interpretable supervised baseline. Later compare suitable tree-based supervised models, such as Random Forest and gradient-boosted trees, using identical leakage-safe splits and training-only preprocessing. Tune only on training/validation data. Report repository-level and language-level results as well as pooled results, and do not imply that any model has been trained.

## 16. Planned evaluation metrics

**Planned:** Report positive-class precision, recall, and F1; use PR-AUC as a primary ranking measure under expected imbalance, with ROC-AUC as a secondary measure. Include the confusion matrix, balanced accuracy, and Matthews correlation coefficient. Where scores support it, assess calibration. Report uncertainty intervals and per-repository variation; select thresholds using validation data only. No accuracy, precision, recall, F1, or other model metric has been measured.

## 17. Threats to validity

- **Construct validity:** “Defect” and “defect-inducing” need a fixed scope; typing/API-contract changes may differ from runtime failures.
- **Label validity:** Automated issue categories and commit-message matches do not replace manual review; SZZ can generate false attributions.
- **Internal validity:** Partial clones lack some historical blobs; fix-to-merge mapping, reviewer disagreement, and unobserved bugs may bias labels.
- **External validity:** Ten provisionally selected Python/Dart repositories and three issues per repository do not represent all projects or languages.
- **Measurement validity:** File extensions, churn, author identity, and issue-link fields may be incomplete or inconsistent across repositories.
- **Evaluation validity:** Class imbalance, related commits, repository differences, and future-information leakage can inflate results if not controlled.
- **Sampling validity:** API query caps and bounded issue sampling limit coverage and prevalence claims.

## 18. Work completed for the first evaluation

**Completed and verified:** Ten repositories (five Python, five Dart) and their configured HEAD/origin records reconcile; default branches contain 52,400 commits and 7,973 target-language source files. Thirty sampled issues and their automated categories reconcile with the suitability matrix. The saved timeline cache has 30 complete records. The 11 fixing relationships were audited locally; all have a local PR-number-matched commit, but only three matched commits have inspectable source diffs. The verifier now preserves unavailable Git diff results as explicit statuses with null counts.

**Investigated but unresolved:** Eight PR-reference diffs remain unavailable; the manual review template is still pending; one attempted blame trace could not access a historical blob. The existence of candidate fix links is not evidence that any defect-inducing label has been validated.

**Not done by design:** No model training, training-label table, feature matrix, or application/backend changes.

## 19. Work remaining for the second research phase

1. Obtain supervisor agreement on RQ1 wording and defect scope.
2. Adjudicate the 30 issue records and map the 11 reviewed fix relationships to authoritative merged implementation commits.
3. Decide an approved, reproducible process for required historical blobs; retain provenance and hashes.
4. Pilot and manually review SZZ candidates; define positive and negative-label confidence rules.
5. Freeze feature cutoffs, file inclusion, contributor handling, related-fix grouping, and leakage controls.
6. Build a versioned, auditable commit-level dataset only after the label and feature gates pass.
7. Freeze temporal validation splits, baselines, metrics, and analysis before training.
8. Train and evaluate models only after the dataset and protocol are reviewed; report limitations and uncertainty.

### Evidence references

- [RQ1 pre-training verification report](./rq1_pretraining_verification_report.md)
- [Bug-fix evidence review](./bug_fix_evidence_review.md)
- [Repository selection report](./repository_selection_first_half.md)
- [Machine-readable local verification](../data/preflight/rq1_pretraining_verification.json)

# RQ1 First-Half Evaluation Summary

## Objective

RQ1 investigates whether commit-level change and process features can predict defect-inducing commits in selected open-source repositories. This first-half work verified research inputs and assessed feasibility; it did not build labels or train a model.

## Data collection achievements

- Screened and configured **10 repositories**: **5 Python and 5 Dart**.
- Verified **52,400 default-branch commits** and **7,973 target-language source files** across the selected repositories.
- Collected **30 issue records**, three per repository, with the automated review distribution:
  - 11 `VERIFIED_FIX`
  - 10 `CANDIDATE_FIX`
  - 3 `BUG_NO_FIX_LINK`
  - 2 `NOT_A_BUG`
  - 4 `UNCLEAR`
- Confirmed the saved timeline cache contains 30 complete records, 231 events, and 38 cross-references. The separate manual review template remains pending.

## Repository selection process

Repositories were selected provisionally based on the project’s Python/Dart scope, locally available histories, repository activity/size, and initial issue/fix evidence. Five were assessed `PROMISING_SAMPLE` and five `FURTHER_REVIEW` using only three sampled issues each. This is a feasibility sample, not a representative sample of open-source software; the repositories remain provisional.

## Evidence verification achievements

All **11** automated verified-fix records have valid-format SHAs. **Eight recorded commit objects resolve locally**, **three recorded SHAs are reachable from their configured HEADs**, **five recorded cases still require fix-to-merge mapping**, and **three recorded objects are unavailable locally**.

A local commit-subject search found a commit mentioning the linked PR number for every case. This improves the audit trail but does not establish that the matching commit is the merged implementation. Source diffs for three PR-number-matched commits are inspectable; the other eight mapped diffs are unavailable because required historical objects are missing in the partial clones. Three examples with inspectable source changes are:

- httpx PR #2667 / issue #2666: `NetRCAuth` receives a default `None` value in `httpx/_auth.py`.
- Flask PR #4298 / issue #4295: the `ErrorHandlerCallable` typing definition is corrected.
- pytest PR #15053 / issue #15052: fixture-location line-number handling is corrected in `src/_pytest/compat.py`, with regression-test changes.

These are local evidence examples, not completed independent human adjudications. The recorded SHA for httpx issue #2985 is changelog-only; the recorded SHA for httpx issue #2532 is test/fixture-only; and the two Riverpod recorded SHAs are merge commits. For three FastAPI cases the recorded SHA is unavailable locally, although a PR-number-matched commit is present. Every case still requires human provenance and defect-scope review.

## SZZ feasibility findings

SZZ-style defect-inducing commit identification is methodologically feasible but not yet reliably executable from the current local evidence. A guarded blame attempt for a pytest source hunk failed because a historical blob was unavailable. No inducing commit was produced or labeled. Fixing commits are not defect-inducing commits, and Git blame alone would not prove causation.

## Feature engineering plan

After labels and historical evidence are approved, candidate features include commit churn, changed-file/path types, change shape, prior file activity, and strictly prior contributor experience. Only information available at the candidate commit time will be used. Linked issue/PR outcomes, future CI results, later history, and other post-outcome data will be excluded.

## Research limitations

- The 30-issue sample is small and not representative; query caps constrain coverage.
- All 30 manual review entries remain `PENDING`.
- Eight PR-reference diffs are unavailable locally, and historical blob completeness is not established.
- Three recorded FastAPI SHAs are unavailable locally.
- No confirmed defect-inducing commits, negative-label method, labeled training population, feature matrix, or trained model exists.

## Future experimental pipeline

The next phase should finalize the defect definition; adjudicate issue/fix and merged-commit provenance; acquire required historical objects through an approved reproducible process; manually review SZZ candidates; construct auditable positive and negative labels; engineer leakage-safe, timestamp-bounded features; and evaluate chronologically. Planned baselines include Logistic Regression, followed by suitable tree-based models. Use PR-AUC as a primary metric with precision, recall, F1, ROC-AUC, MCC, confusion matrices, and uncertainty reporting. These experiments have not started.

## Presentation-ready conclusion

**The first half established and audited a ten-repository RQ1 evidence base, including 30 sampled issue records with automated evidence review and 11 candidate fixing relationships. Local checks improved provenance for all 11, but incomplete historical diffs and pending human review mean the defect-inducing labels and training dataset are not ready. The next phase will resolve fix provenance, validate SZZ candidates, and then run a leakage-safe temporal evaluation; no model results are claimed.**

For detailed methods and limitations, see the [first-half methodology](./rq1_methodology_first_half.md) and [pre-training verification report](./rq1_pretraining_verification_report.md).

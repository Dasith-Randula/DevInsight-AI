# DevInsight RQ1 Pre-Training Research Verification

**Verification date:** 2026-11-11 (local time, UTC+05:30)  
**Project repository:** `C:\Users\User\Desktop\FYP\Project\DevInsight-AI\DevInsight`  
**Git branch / HEAD:** `Research` / `8ae6c8ab8df1eec9d54133444031e25629854e3c`  
**Verdict:** **NOT YET READY** for ML training. Do not construct training labels or start model training from the current evidence.

This is an offline, pre-training verification. It did not fetch GitHub data intentionally, run code from the ten cloned repositories, create labels, extract feature matrices, or train a model. One attempted Git connectivity check unexpectedly invoked a promisor fetch; it was stopped, and the effect is documented below.

## 1. Executive Summary

The configured ten repositories are present and valid Git worktrees. Their configured origins, default branches, manifest HEADs, target-language source-file counts, and default-branch commit counts match the existing research records. The configured branch histories are not shallow. Across the ten default branches there are exactly **52,400 commits**; `git rev-list --all --count` reports **59,391** commits reachable from all local refs combined. The latter is not a count of labeled examples.

The existing issue sample has 30 unique records, three per repository, with the expected automated review distribution: 11 `VERIFIED_FIX`, 10 `CANDIDATE_FIX`, 3 `BUG_NO_FIX_LINK`, 2 `NOT_A_BUG`, and 4 `UNCLEAR`. The issue keys, review keys, manual-template keys, suitability-matrix counts, and saved timeline cache reconcile. The cache has 30 complete records and 231 events.

The critical gap is fix-commit provenance. Of the 11 recorded verified-fix SHAs, **8 resolve to local commit objects, 3 are reachable from configured repository HEADs, 5 still require mapping from the recorded SHA to the merged implementation, and 3 recorded objects are unavailable locally**. A local commit-message search found at least one commit referencing the linked PR number for every case, but that is only a local mapping lead, not proof of implementation content. A source diff for the PR-referenced commit is available for 3 cases; the other 8 PR-referenced diffs are unavailable because required historical objects are missing in the partial clones. The recorded SHA for httpx issue 2985 changes only `CHANGELOG.md`, the SHA for issue 2532 changes tests and a fixture only, and the two Riverpod SHAs are merge commits. The manual review template still marks all 30 cases `PENDING`.

All ten clones are partial clones configured with `blob:none`. The non-shallow commit and tree histories and current-HEAD source blobs passed the bounded local object checks, but that does not establish historical blob completeness. A targeted `git blame` attempt for pytest issue 15052 failed while traversing history because a historical blob was unavailable. Consequently, SZZ-style tracing and historical churn features are not yet reliably executable offline. A negative-label method is also absent. The present evidence is insufficient to construct reliable defect-inducing labels or a defensible training/test split.

## 2. Research Objective

RQ1 concerns **software defect prediction**. A future study must define the prediction unit and target precisely, for example whether a commit is predicted to be defect-inducing, rather than merely associated with a later fix. An issue-linked *fixing commit* is not a *defect-inducing commit*. Fixes identify the prior defect correction; they do not, on their own, establish which earlier commit introduced that defect.

This verification stops before feature extraction, defect-label construction, training-dataset creation, or model training.

## 3. Existing Research Resources

The inspected configuration selects five Python projects and five Dart projects in `config/research_repositories.csv`; `config/repository_setup_manifest.csv` records the clone HEADs and origins. The ten clones reside below `data/repositories/`.

Inspected records:

- Repository screening: `data/repository_screening.csv` (10 rows).
- Label-based issue audit: `data/repository_bug_audit.csv` (10 rows).
- Issue sample: `data/bug_issue_samples.csv` (30 rows).
- Automated fix review: `data/bug_fix_review_auto.csv` (30 rows).
- Repository suitability matrix: `data/repository_suitability_matrix.csv` (10 rows).
- Manual review template: `data/bug_fix_review.csv` (30 rows, all `PENDING`).
- Pilot records: `data/repository_bug_audit_pilot.csv` (2 rows) and `data/bug_issue_samples_pilot.csv` (6 rows).
- Timeline cache: `data/bug_fix_review_timeline_cache.json` (30 complete records).
- Existing documentation: `docs/bug_fix_evidence_review.md` and `docs/repository_selection_first_half.md`.
- Existing screening, issue-audit, timeline-retrieval, and suitability-building PowerShell scripts.

The pilot files are supplemental records, not replacements for the ten-repository screening or 30-issue main sample. The four originally untracked research files were read only and were not altered, deleted, renamed, or overwritten.

## 4. Verification Methodology

The verifier uses Python standard-library CSV/JSON/date parsing and local Git commands. It compares configured data with the setup manifest and local clones; validates CSV structure, keys, timestamps, URLs, review distributions, matrix totals, and cache coverage; and resolves each recorded `VERIFIED_FIX` SHA without contacting GitHub.

Repository object checks were deliberately bounded:

- Confirmed Git worktree roots, working-tree status, origins, configured/default branches, HEADs, and commit counts.
- Enumerated commit metadata across local refs and checked each referenced tree object with `git cat-file --batch-check`.
- Checked source-code blobs present at each current `HEAD`.
- Disabled Git lazy fetching in all verifier subprocesses.

These checks do **not** prove that every historical blob is present. `git fsck --connectivity-only --no-reflogs` was not completed because Git attempted a promisor fetch on a `blob:none` clone; it was stopped. One guarded `git blame` experiment was performed for a clearly identified source hunk. No remote API calls, downloads, repository-code execution, dependency installation, or training commands were performed intentionally.

## 5. Research Environment Verification Results

| Check | Command / evidence | Observed result |
|---|---|---|
| Current branch | `git branch --show-current` | `Research` |
| Research HEAD | `git rev-parse HEAD` | `8ae6c8ab8df1eec9d54133444031e25629854e3c` |
| Git version | `git --version` | `git version 2.47.1.windows.1` |
| Python version | `python --version` | `Python 3.14.2` |
| Required directories | Local path checks | `config`, `data`, `data/repositories`, `docs`, and `scripts` all exist |
| Required evidence files | Local path checks | Both existing research reports and all four existing scripts exist |
| CSV readability | Python `csv.DictReader`, UTF-8/UTF-8-BOM | All 10 inspected CSV files parsed; no missing required columns |
| Independent verification | `python -B scripts\preflight\verify_rq1_pretraining.py` | Completed; JSON evidence written under `data/preflight/` |
| Worktree state | `git status --short` | Pre-existing untracked research evidence retained; focused verifier output and RQ1 documents added; no original research CSV was changed |
| Secret handling | Scope restriction | `backend\.env` was not opened or read |

`data/repositories/` is Git-ignored by the project. Its internal object-store state is not represented by the root worktree status.

## 6. Repository Integrity Results

| Repository | Language | Local directory | HEAD commits | All-local-ref commits | Target source files at HEAD | Current branch | History / object result |
|---|---|---|---:|---:|---:|---|---|
| `encode/httpx` | Python | `data/repositories/encode__httpx` | 1,523 | 1,647 | 60 | `master` | Valid; manifest/origin/default branch match; not shallow |
| `fastapi/fastapi` | Python | `data/repositories/fastapi__fastapi` | 8,047 | 8,173 | 1,220 | `master` | Valid; manifest/origin/default branch match; not shallow; object-store warning (see §15) |
| `pallets/flask` | Python | `data/repositories/pallets__flask` | 5,566 | 5,607 | 83 | `main` | Valid; manifest/origin/default branch match; not shallow |
| `pydantic/pydantic` | Python | `data/repositories/pydantic__pydantic` | 5,936 | 9,236 | 3,157 | `main` | Valid; manifest/origin/default branch match; not shallow |
| `pytest-dev/pytest` | Python | `data/repositories/pytest-dev__pytest` | 17,896 | 19,206 | 274 | `main` | Valid; manifest/origin/default branch match; not shallow |
| `felangel/bloc` | Dart | `data/repositories/felangel__bloc` | 2,838 | 3,148 | 616 | `master` | Valid; manifest/origin/default branch match; not shallow |
| `rrousselGit/riverpod` | Dart | `data/repositories/rrousselGit__riverpod` | 2,656 | 3,390 | 1,327 | `master` | Valid; manifest/origin/default branch match; not shallow |
| `cfug/dio` | Dart | `data/repositories/cfug__dio` | 962 | 1,121 | 156 | `main` | Valid; manifest/origin/default branch match; not shallow |
| `firebase/flutterfire` | Dart | `data/repositories/firebase__flutterfire` | 4,592 | 5,470 | 942 | `main` | Valid; manifest/origin/default branch match; not shallow |
| `fluttercommunity/plus_plugins` | Dart | `data/repositories/fluttercommunity__plus_plugins` | 2,384 | 2,393 | 138 | `main` | Valid; manifest/origin/default branch match; not shallow |
| **Total** | **5 Python / 5 Dart** |  | **52,400** | **59,391** | **7,973** |  |  |

The 52,400 default-branch commit total and all ten target-language source counts exactly match `data/repository_screening.csv`. `origin/HEAD` and the configured branch ref agree for all ten clones. All ten are configured as **partial clones using `blob:none`**, not shallow clones. The audit found no missing commit-tree objects and no missing source-code blobs at current `HEAD`; it did not establish historical blob completeness. Counts across all refs are larger because local refs include additional branch histories; do not substitute that sum for the screened default-branch total.

**Suitability for commit-level analysis:** metadata and tree-level analysis are locally feasible. Historical source diffs, blame, and SZZ require historical blobs and PR/merge mapping that are not established by these checks.

## 7. Dataset Quality Verification Results

| Dataset | Rows | Structural / key result | Notes |
|---|---:|---|---|
| `config/research_repositories.csv` | 10 | Required columns present; no duplicate rows; all repository IDs valid | Five Python, five Dart |
| `config/repository_setup_manifest.csv` | 10 | Required columns present; no duplicate rows; all SHAs and timestamps structurally valid | Every recorded HEAD matches its local clone |
| `data/repository_screening.csv` | 10 | Required columns present; no duplicate repository rows | Commit and target-language source counts match current configured HEADs |
| `data/repository_bug_audit.csv` | 10 | Required columns present; no duplicate repository rows | `PageLimitReached=True` for 8/10 rows |
| `data/bug_issue_samples.csv` | 30 | Three issues per repository; unique keys; issue URLs, IDs, and nonempty timestamps validate | No duplicate issue key or unknown repository |
| `data/bug_fix_review_auto.csv` | 30 | Unique keys; valid issue links, review timestamps, and present SHA formats | Statuses reconcile with the suitability matrix |
| `data/repository_suitability_matrix.csv` | 10 | All per-repository review totals agree with automated-review records | 5 `PROMISING_SAMPLE`, 5 `FURTHER_REVIEW`, all provisional |
| `data/bug_fix_review.csv` | 30 | Same issue-key set as the main sample | All 30 rows remain `PENDING`; not an independent completed manual review |
| `data/repository_bug_audit_pilot.csv` | 2 | Valid pilot subset | Not a ten-repository result |
| `data/bug_issue_samples_pilot.csv` | 6 | Valid pilot subset | Not an additional independent 30-issue sample |

The automated-review distribution is exactly **11 / 10 / 3 / 2 / 4** for `VERIFIED_FIX` / `CANDIDATE_FIX` / `BUG_NO_FIX_LINK` / `NOT_A_BUG` / `UNCLEAR`. The matrix reproduces these counts without discrepancy. All 30 issue keys appear once in the main issue sample, automated review, and manual template. No invalid dates or URL/key mismatches were found in the fields checked. Blank PR/SHA fields in categories without a linked fix are expected and were not treated as missing-positive-evidence errors.

The audit populations are not interchangeable. `repository_screening.csv` records a recent general issue/PR screen; `repository_bug_audit.csv` uses a bug-label query with a maximum of 100 mixed issue/PR records. Eight audit rows hit that page cap. All ten PR sample counts in repository screening are 100, the configured API page size. Therefore these figures do not represent complete issue/PR populations, and repository-specific bug-label query counts should not be interpreted as comparable prevalence estimates.

## 8. Bug-Fix Evidence Verification Results

The issue-level classification counts are internally consistent, but they are **automated review classifications**, not 30 completed manual reviews: the separate manual template has 30 `PENDING` rows. The cache contains 30/30 complete timelines, **231 timeline events**, and **38 cross-reference events**, matching the existing evidence-review documentation. This verifies saved cache structure and coverage, not current live GitHub state.

The 11 `VERIFIED_FIX` records describe plausible issue/PR relationships in the existing evidence. Local inspection of the *recorded SHA* reveals that it is not consistently the implementation commit:

Full recorded and matched SHA values are in `data/preflight/rq1_pretraining_verification.json`; the table uses 12-character prefixes. Every recorded SHA is syntactically valid. “Single-parent, role unconfirmed” deliberately avoids calling a commit a PR head or implementation fix based on parent count alone. The local PR-reference search scans commit subjects for the linked PR number; it does not establish authoritative GitHub PR membership.

| Issue | Repository | Recorded SHA: local status / role / diff | PR-number-matched local commit: role / diff | Assessment; human verification |
|---|---|---|---|---|
| 2985 | `encode/httpx` | `c1f3cc58d2c1`; available, off HEAD; single-parent role unconfirmed; changelog-only | `b471f01d668b`; single-parent, reachable; diff unavailable | Implementation content unresolved; verify PR file list and merged change manually. |
| 2666 | `encode/httpx` | `3674f4596841`; available, off HEAD; single-parent role unconfirmed; `httpx/_auth.py` source diff | `c1cc6b2462e9`; single-parent, reachable; source diff in `httpx/_auth.py` | Strong local mapping: patch adds the `None` default to `NetRCAuth`; reviewer should confirm issue scope and provenance. |
| 2532 | `encode/httpx` | `28ec479b8931`; available, off HEAD; single-parent role unconfirmed; tests/fixture only | `59914c769057`; single-parent, reachable; diff unavailable | Fix implementation unresolved; verify merged PR diff manually. |
| 4297 | `pallets/flask` | `190dd4df8687`; available, reachable; single-parent role unconfirmed; 3 source paths | `cb7cd1e79b28`; merge commit, reachable; diff unavailable | Source change is inspectable on the recorded SHA, but mapping to the linked PR remains unresolved; manual review required. |
| 4295 | `pallets/flask` | `46b39e269869`; available, reachable; single-parent role unconfirmed; `src/flask/typing.py` | `b831e8507c88`; merge commit, reachable; first-parent source diff in `src/flask/typing.py` | Locally traceable typing correction; manually confirm issue-to-PR interpretation and defect-scope inclusion. |
| 15052 | `pytest-dev/pytest` | `09d0020ff205`; available, reachable; single-parent role unconfirmed; source and regression-test changes | `56a92c19d4a7`; merge commit, reachable; first-parent diff includes `src/_pytest/compat.py` and tests | Locally traceable line-number correction; manually confirm the issue/PR and positive-label definition. |
| 4953 | `rrousselGit/riverpod` | `fea6e5eb8679`; available, off HEAD; merge commit; diff unavailable | `a4174afa33a7`; single-parent, reachable; diff unavailable | PR-related commit found, implementation diff unavailable; human verification required. |
| 4951 | `rrousselGit/riverpod` | `4dda33aca48d`; available, off HEAD; merge commit; diff unavailable | `4b481dcaf9f0`; single-parent, reachable; diff unavailable | PR-related commit found, implementation diff unavailable; human verification required. |
| 16417 | `fastapi/fastapi` | `73c49153dd11`; recorded object unavailable locally; diff not attempted | `1d4953d2e528`; single-parent, reachable; diff unavailable | PR-related commit found but implementation unverified; human verification required. |
| 16010 | `fastapi/fastapi` | `c2e9c94014bb`; recorded object unavailable locally; diff not attempted | `eb75fd078e83`; single-parent, reachable; diff unavailable | PR-related commit found but implementation unverified; human verification required. |
| 15764 | `fastapi/fastapi` | `b516ac70b9ba`; recorded object unavailable locally; diff not attempted | `b78c82262f51`; single-parent, reachable; diff unavailable | PR-related commit found but implementation unverified; human verification required. |

Summary: **8/11 recorded objects resolve locally; 3/11 recorded SHAs are reachable from configured HEADs; 5/11 recorded SHAs remain mapping cases; 3/11 recorded objects are unavailable locally.** For the 8 resolved recorded SHAs, 6 diffs succeeded and 2 returned `DIFF_UNAVAILABLE`; 5 successful recorded diffs include source-suffix paths (including tests and typing). The separate local PR-reference search found commit-message matches for all 11; source diffs are available for 3 matched commits and unavailable for 8. A successful diff establishes changed paths, not by itself that the change fixes the stated defect. A merged-PR boolean or matching commit subject does not establish the recorded SHA is the merged target-branch implementation. Human verification remains necessary for all 11 records.

Do not treat the five unmerged/open candidates or the three reports with no linked fix as confirmed fixes. Do not use any fixing SHA as a defect-inducing label.

## 9. Git Commit Verification Results

The commit classifications above were computed using `git cat-file -t`, `git show -s` parent metadata, `git merge-base --is-ancestor <sha> HEAD`, and read-only `git diff --numstat` where objects were available. The commit SHA in each review row is documented as PR-head/fixing evidence; local commit inspection shows that these notions must be separated.

| Local classification | Count | Meaning |
|---|---:|---|
| `REACHABLE_FROM_HEAD` | 3 | Recorded one-parent SHA is reachable and its successful diff includes source-suffix paths; content and defect scope still require review |
| `REQUIRES_MERGE_MAPPING` | 5 | Recorded object exists but is off HEAD or is a merge commit; local PR-number matches now exist, with source diffs available for only part of the evidence |
| `RECORDED_SHA_UNAVAILABLE_LOCALLY` | 3 | Recorded object does not resolve locally under no-lazy-fetch; diff was not attempted; PR-number matches exist but their diffs are unavailable |

The verifier now separates an unavailable recorded object from a failed diff. A failed Git diff is `DIFF_UNAVAILABLE`, with `changed_files`, `changed_file_count`, `source_files_changed`, `additions`, and `deletions` set to JSON `null`. A diff is described as `DIFF_AVAILABLE` only when Git returns success and parses its output. Merge-commit diffs compare the first parent with the merge commit. The verifier never interprets a failed command as zero changes.

For `encode/httpx#2985`, the recorded commit is changelog-only; for `encode/httpx#2532`, it is test-only. For the two Riverpod records, the recorded objects are merges from the target branch into PR branches, not verified source-fix commits. These cases are unsuitable as-is for commit-level SZZ input. The three FastAPI commit objects are unavailable locally, so their diffs, parent counts, file sets, and reachability cannot be asserted.

## 10. Candidate and Uncertain Evidence Assessment

All non-verified categories remain excluded from positive-label construction. Existing classifications were preserved.

| Status | Cases and reason recorded in the evidence | Needed before reconsideration |
|---|---|---|
| `CANDIDATE_FIX` (10) | `pydantic/pydantic#14243`: PR 14257 was closed unmerged and only addresses one variant. `pytest-dev/pytest#15139`: PR 15135 was open/draft despite the issue being closed as outdated. `pytest-dev/pytest#15051`: PR 15055 open/unmerged. `felangel/bloc#4863`: PR 4864 open/unmerged. `felangel/bloc#4815`: PR 4840 open/unmerged and concerns bloc templates, not Freezed itself. `rrousselGit/riverpod#4902`: PRs 4903/4910 open/unmerged. `cfug/dio#2631`: PR 2630 open/unmerged. `cfug/dio#2618`: PRs 2617/2624 open/unmerged. `cfug/dio#2613`: PR 2611 open/unmerged. `fluttercommunity/plus_plugins#3994`: draft PR 3997 open/unmerged. | Current merged status, final target-branch commit, issue closure/resolution, complete diff, and whether the change fixes the stated defect |
| `BUG_NO_FIX_LINK` (3) | `pydantic/pydantic#14266`: reproducible typing report, no linked fix. `firebase/flutterfire#18932`: native event-sink race report, no linked fix. `firebase/flutterfire#18928`: native invalid-field crash report, no linked fix; exact isolated sample was not tested. | Maintainer resolution and a defensible linked fix, plus source-path validation |
| `UNCLEAR` (4) | `pydantic/pydantic#14245`: compatibility behavior may be intentional. `felangel/bloc#4893`: stack overflow ownership/reproduction unclear. `firebase/flutterfire#18931`: reachable current code path and reproduction unresolved. `fluttercommunity/plus_plugins#3968`: text-sharing report is not demonstrated by the separate URI-sharing PR. | Independent reproduction, maintainer decision, or fix demonstrably matching the exact reported path |
| `NOT_A_BUG` (2) | `pallets/flask#4355`: evidence attributes the failure to application event-loop/gevent integration outside Flask's supported flow. `fluttercommunity/plus_plugins#3979`: dependency-version support request; its merged dependency PR does not turn it into a defect report. | No promotion recommended absent contradictory evidence |

Offline checks validated row structure and saved evidence only. They did not re-query GitHub or independently establish current PR/issue state. These 19 records must not be used to fabricate positives or negatives.

## 11. SZZ Feasibility Analysis

An SZZ-style process is **methodologically plausible but blocked for reliable execution on the current local evidence**:

1. A potential fix example exists: pytest issue 15052's recorded, reachable source-changing commit changes the `getlocation` line-number behavior in `src/_pytest/compat.py`, with associated tests and changelog.
2. The recorded fixing commit and its parent are available, and the source hunk can be inspected. A guarded `git blame -L 85,86 <fix-sha>^ -- src/_pytest/compat.py` attempt failed while traversing earlier history with `fatal: Cannot read blob d3b2a4696938625de84ae4ebd1cae5f475355371 for path src/_pytest/compat.py`.
3. This is consistent with the clones' `blob:none` partial-clone configuration. Other Riverpod historical inspection likewise warned that objects could not be fetched when lazy fetching was disabled. The verifier did not fetch them.
4. The pytest hunk is a *potential SZZ input*, not a defect-inducing commit. No blamed commit was produced, reviewed, or recorded as a candidate; no final defect-inducing label was created.

For future SZZ work, first map each issue/PR to the actual merged target-branch change, obtain the required historical file blobs through an explicitly approved reproducible acquisition step, identify removed/modified source lines, trace them to candidate ancestors, and manually review candidates for refactors, moves, merge effects, and false-positive blame. Tests-only, documentation-only, merge-sync, and typing-only fixes need explicit inclusion rules.

## 12. Feature Extraction Feasibility

| Feature | Definition / source | Prediction-time availability | Leakage risk | Availability and limitations |
|---|---|---|---|---|
| Commit timestamp and parent count | Commit object metadata | Available for the candidate commit | Low if the target commit is the prediction unit; do not use later metadata | Commit metadata is locally traversable; validate timezone and chronological ordering |
| Changed paths / extension / directory | Candidate and parent tree comparison | Available at commit time | Low if restricted to the candidate commit | Trees are locally present; merges, renames, generated/vendor paths, and partial history need explicit handling |
| Lines added/deleted and code churn | Diff of candidate commit against its parent | Available only when patch blobs are available | Low if computed only for the candidate diff; future diffs would leak | Not established for all historical commits because of `blob:none`; current-HEAD blob availability is insufficient |
| Prior file change frequency | Count earlier changes to the candidate's files | Historical-only, through the candidate's parent | High if later commits or the full history are included | Commit/tree metadata may support a bounded method; historical source/blame evidence is incomplete |
| Developer experience | Prior authored commits before candidate time | Historical-only | High if author activity after the candidate is included | Commit identities exist, but identity normalization, aliases, bots, and privacy require decisions |
| Prior file age / prior churn | Only history strictly before the candidate | Historical-only | High if measured through or after the target fix | Requires reproducible cutoff and source history; not currently extracted |
| Commit message / linked issue / PR fields | Commit message and external review metadata | Some fields exist at commit time; issue/PR metadata often post-dates the commit | Very high if bug labels, future PR text, or fix links are input features | Exclude label-bearing/post-outcome fields from predictors |
| Later test or CI outcome | Test/CI result after the commit | Not available at prediction time | Direct future leakage | No CI-run evidence was verified; workflow files alone do not provide outcomes |

Python counts are based on `.py` files and Dart counts on `.dart` files to match screening. Dart plugin repositories also contain platform-native code; extension-only counts do not fully describe a multi-language target. Repository/language stratification and explicit treatment of native paths are required before cross-repository comparisons.

## 13. Defect Label Quality Assessment

- The issue review contains 11 issue-level verified fix relationships, but only three recorded SHAs were locally reachable one-parent source changes. Two of those are static typing corrections; one is a runtime behavior correction.
- Five recorded SHAs require mapping; three are absent locally. The recorded SHA does not uniformly identify the actual merged code change.
- A fixing commit is not the defect-inducing commit. No defect-inducing commit has been validated.
- The 10 candidates, 3 no-fix-link reports, and 4 unclear cases need their status preserved. The two `NOT_A_BUG` cases are not negative commit examples.
- A commit without an associated bug report is not automatically non-defective. The project has no defensible negative-sampling rule, no verified negative examples, and no class distribution.
- The 30 issues are a small, deliberately screened sample, not the output of a representative defect-label process. Several source query results hit 100-record caps.

Before labels can be created, the study needs a precise defect definition, verified fix-to-target-branch mapping, source-code inclusion criteria, reviewed SZZ candidates, duplicate/related-fix handling, and a transparent negative-label sampling strategy. Labels need confidence/provenance and independent adjudication.

## 14. Dataset and ML Training Readiness

**Verdict: NOT YET READY.**

There are 52,400 default-branch commits and 7,973 target-language source files across the selected repositories, but neither count is a count of correctly labeled observations. The present evidence has 11 issue/fix relationships classified as verified in the automated review, not 11 validated defect-inducing commits. Three recorded SHAs are reachable source-changing commits; all 11 have a local PR-number match, but only 3 of those matched commits have an inspectable source diff. Eight mapped PR-reference diffs remain unavailable. No negative-label method or labeled commit population exists, so class distribution cannot be meaningfully calculated.

Feature definitions are preliminary, historical blobs are incomplete locally, and cross-language comparability has not been operationalized. A time-based split could be considered later, per repository or with forward-chaining, only after label and feature provenance are complete. Randomly splitting related commits can put highly related files, developers, fixes, and adjacent history in both train and test sets, overstating generalization. A leave-repository-out or repository/time-aware evaluation may also be needed, depending on the intended deployment claim. No model or predictive metric was computed.

## 15. Identified Risks and Research Limitations

1. **Recorded SHA is not consistently the fix diff.** Local evidence identifies a changelog-only SHA for httpx 2985, a test-only SHA for httpx 2532, two Riverpod merge-sync SHAs, and three recorded FastAPI objects unavailable locally. PR-number-matched commits were found locally for all 11 cases; only 3 matched commits have inspectable source diffs.
2. **Partial clone limitation.** All ten clones advertise `blob:none`. Current source blobs and all checked commit-tree objects were present, but historical blob completeness was not established; the pytest blame experiment proves at least one requested historical object is unavailable through the guarded local check.
3. **Interrupted Git operation.** During an initial `git fsck --connectivity-only --no-reflogs` check, Git unexpectedly attempted a promisor fetch from the FastAPI origin. The operation was stopped. Afterward, `git count-objects -v` reported `garbage: 1`, `size-garbage: 3095` (Git's count-objects unit), at `.git/objects/pack/tmp_pack_1lANPH`. This temporary pack was not deleted or modified. FastAPI HEAD still matched the manifest; refs were not comprehensively baseline-compared. The final verifier disables lazy fetching.
4. **Automated vs manual review.** Automated classifications reconcile, but every row in the manual template remains `PENDING`.
5. **Sampling caps and recency.** Eight issue-audit records hit the 100-result page cap; the screening PR query returned 100 for all repositories. Three issues per repository do not support repository-wide prevalence claims.
6. **Label ambiguity and scope.** Typing, tooling, dependency, documentation/API-contract, and runtime defects may not belong to one homogeneous target.
7. **False positives/negatives.** Unlinked fixes may be missed; not all reported regressions are framework defects; SZZ blame can identify unrelated changes.
8. **Cross-repository heterogeneity.** Python and Dart repositories differ in language, file layout, native platform content, release cadence, and issue workflows.
9. **Leakage and dependence.** Future commit history, linked fixes, post-commit CI, identity aggregates, related fixes, and random neighboring-commit splits can leak outcomes or violate independence.
10. **No negative definition or temporal protocol.** Without these, class balance, test isolation, and model metrics would be misleading.

## 16. First 50% Evaluation Achievements

### Implemented and verified from local evidence

- Ten repositories are configured and cloned, split five Python/five Dart; configured origins, manifest HEADs, branch refs, default-branch commit totals, and target-language source counts reconcile.
- Repository screening, label-based issue-audit records, a 30-issue sample, and a documented initial fix-evidence review exist.
- The saved timeline cache is structurally complete for the 30 sampled issues.
- Five repositories were marked `PROMISING_SAMPLE` and five `FURTHER_REVIEW` based on a three-issue sample; all ten remain provisional.
- The first-half documentation explicitly distinguishes repository counts and issue review from ML training.

### Partially implemented / preliminary

- Issue classifications and timeline review are present, but the separate manual review file remains entirely `PENDING`.
- The sample is small; several API queries were capped; candidate relationships and 8 PR-reference diffs remain unresolved even though local PR-number matches were found for all 11 cases.
- Repository and feature feasibility is now locally documented, but historical object completeness and SZZ results are not established.

### Planned for the next research phase

- Adjudicate issues and PR merge mappings, define the defect target, obtain historical blobs under an approved process, and manually review SZZ candidates.
- Specify temporal feature cutoffs, cross-language/repository handling, negative sampling, duplicate handling, and leakage controls.
- Only after those gates, create a versioned label/feature dataset and define time-/repository-aware experiments.

No trained defect-prediction model, predictive metric, final labeled dataset, or production feature pipeline was found or created in this verification.

## 17. Remaining Work Before ML Training

1. Independently review and resolve all 30 automated classifications; update the manual template only through a documented adjudication process.
2. For all 11 reviewed cases, obtain authoritative PR commit lists and merged target-branch commit mapping; distinguish PR head, squash commit, merge commit, and implementation commit.
3. Resolve the 3 locally unavailable FastAPI recorded SHAs and remaining mapping cases; inspect missing diffs through an approved evidence-acquisition process. Exclude changelog-only, test-only, and merge-sync commits unless a separate implementation diff is verified.
4. Define whether typing/tooling/API contract defects are in scope alongside runtime defects.
5. Decide how to acquire and retain historical blobs for all required paths. This verification intentionally did not fetch or reclone.
6. Implement and manually validate SZZ-style attribution on a larger sample; retain candidate/confirmed status separately.
7. Specify commit-level feature definitions, cutoff semantics, author normalization, generated/test/native-file rules, and label-leakage exclusions.
8. Define the positive and negative sampling procedures, related-fix deduplication, confidence fields, and source evidence.
9. Plan time-aware/repository-aware validation, independent test observations, and reporting of class imbalance before any model training.

## 18. Recommended Next Research Steps

1. **Evidence adjudication:** Have two reviewers reconcile the 30 issue classifications and document disagreements; do not change source evidence silently.
2. **Fix mapping:** Verify PR commit lists and actual merged commits for the 11 cases; add separate fields for PR head SHA, merged SHA, and implementation/fix SHA in a future versioned record rather than overwriting evidence.
3. **Historical object plan:** Explain the need and obtain approval before explicitly fetching/recloning the required historical blobs; preserve checksums and commit IDs. Do not rely on an accidental lazy fetch.
4. **SZZ pilot protocol:** On a small set of mapped, source-changing fixes, produce candidates only, manually inspect code and issue timeline evidence, and record false-positive rules.
5. **Operational target and features:** Freeze the defect definition and prediction time first, then specify features using only information available at that time.
6. **Labels and sampling:** Establish positive provenance and a defensible negative/control strategy before generating any label table.
7. **Evaluation protocol:** Pre-register time-aware and repository-aware splits, leakage checks, metrics, and uncertainty reporting.
8. **Training gate:** Begin training only after the above produce a reviewed, versioned dataset and a supervisor-approved methodology.

## 19. Final Verification Checklist

| Verification ID | Check name | Expected result | Actual result | Status | Evidence reference | Explanation |
|---|---|---|---|---|---|---|
| ENV-01 | Project branch, HEAD, versions | Research branch; expected HEAD; tools available | `Research`, `8ae6c8a…`; Git 2.47.1.windows.1; Python 3.14.2 | PASS | `git branch`, `git rev-parse`, `git --version`, `python --version` | Observed directly |
| ENV-02 | Required paths and evidence files | All listed files and directories exist/read | All required paths exist; all inspected CSVs parse | PASS | Preflight JSON `environment`, `csv_files` | No required file missing |
| ENV-03 | Existing worktree state | Preserve user changes and report them | Pre-existing untracked evidence retained; verifier, JSON output, and RQ1 documents present | WARNING | `git status --short` | No original research CSV or application/backend file was changed |
| ENV-04 | Interrupted object check | No unreported repo mutation | FastAPI has one garbage temp pack after interrupted promisor fetch; HEAD matches manifest | WARNING | `git count-objects -v`; FastAPI `git rev-parse HEAD` | Left untouched; refs not baseline-compared |
| REP-01 | Ten local Git worktrees and origins | Every configured clone valid and origin-matched | 10/10 valid; origins match; configured branches and manifest HEADs match | PASS | Preflight JSON `repositories` | Checks run with lazy fetching disabled |
| REP-02 | Commit/source inventory | Counts reconcile to screening | HEAD commits total 52,400; target source files total 7,973; every row matches | PASS | Preflight JSON `repositories`; `repository_screening.csv` | All ten default branches agree |
| REP-03 | History and object availability | Not shallow; required metadata/source objects available | 0 shallow clones; all commit trees and current-HEAD source blobs checked with no missing objects | WARNING | Preflight JSON; clone `blob:none` config | Historical blobs are not covered by this bounded check |
| DATA-01 | CSV schemas and row counts | Required fields, readable inputs | 10 CSVs parsed; row counts: 10/10/10/10/30/30/10/30/2/6 | PASS | Preflight JSON `csv_files` | No missing required columns |
| DATA-02 | Issue keys and fields | Unique records, valid IDs/URLs/dates | 30 unique issue keys; all map to configured repos and corresponding review rows | PASS | Preflight JSON `dataset_relations` | No invalid timestamps or URL/key mismatches |
| DATA-03 | Review totals and matrix | Counts agree without altering labels | 11/10/3/2/4; matrix matches exactly; manual rows all `PENDING` | PASS | `bug_fix_review_auto.csv`, `repository_suitability_matrix.csv`, `bug_fix_review.csv` | Agreement is structural, not independent manual confirmation |
| DATA-04 | Timeline evidence cache | Full cache for sample | 30/30 complete; 231 events; 38 cross references | PASS | `bug_fix_review_timeline_cache.json`; preflight JSON `timeline_cache` | Saved cache inspected offline |
| DATA-05 | Sampling limitations | Caps and populations identified | 8/10 issue audits hit 100-record cap; all 10 screening PR samples equal 100 | WARNING | `repository_bug_audit.csv`, `repository_screening.csv`, source scripts | These are bounded samples, not complete populations |
| FIX-01 | Issue-level review classification | Recalculate all 30 cases | Counts match expected starting figures exactly | PASS | `bug_fix_review_auto.csv`; preflight JSON | Classification labels preserved |
| FIX-02 | Recorded verified-fix SHA existence and ancestry | Resolve all 11 locally | 8 objects resolve; 3 unavailable; 3 recorded SHAs reachable; 5 recorded cases require mapping | FAIL | Preflight JSON `verified_fix_commits` | Local object/ancestry availability is not the same as fix validity |
| FIX-03 | SHA equals implementation fix | Verify changed paths and merge mapping | Local PR-number matches found for all 11; source diffs available for 3 matched commits; 8 matched diffs unavailable | FAIL | §8–9; preflight JSON `pr_reference_commits`; local first-parent diffs | Message matches are not authoritative PR provenance; human review required |
| OTHER-01 | Candidate/uncertain classifications | Keep unresolved cases out of positives | 10 candidates, 3 no-link, 4 unclear, 2 not-bug retained and assessed | PASS | `bug_fix_review_auto.csv`; §10 | No status promoted or changed |
| SZZ-01 | Sample source-line attribution | Trace removed source lines to ancestors | Pytest hunk inspected; guarded `git blame` failed on missing historical blob | BLOCKED | Command/result in §11 | No inducing candidate or label produced |
| FEAT-01 | Commit metadata availability | Verify history-derived inputs exist | Commit times, parents, branch history and trees locally traversable | PASS | Repository preflight output | Availability does not imply a feature matrix exists |
| FEAT-02 | Historical diff/churn availability | Verify source history sufficient | Current source blobs present; `blob:none` and missing historical blob prevent reliable general claim | WARNING | `git blame` error in §11; partial-clone config | Requires explicit historical-object acquisition |
| LABEL-01 | Label and negative quality | Positive and negative labels justified | No validated inducing commits or negative-label methodology | WARNING | §13 | Issue-level fixes are not defect-inducing labels |
| ML-01 | Training readiness | Sufficient reviewed labels/features and valid split | No label dataset, no negative method, unresolved commit evidence and historical blobs | FAIL | §14 | Verdict is NOT YET READY |
| EVAL-01 | First-half claims | Report only demonstrable achievements | Repository screening, initial review and limitations separated from planned ML work | PASS | §16 | No model or metrics claimed |

**Checklist totals: 22 checks — 12 PASS, 6 WARNING, 3 FAIL, 1 BLOCKED.**

## 20. Final Conclusion

Do **not** begin ML model training. The repository setup and preliminary issue review are useful first-half research achievements, but the current 11 automated `VERIFIED_FIX` issue relationships do not provide 11 verified defect-inducing commits. Local PR-number matches improve the provenance trail but do not resolve all implementation diffs: only three matched commits have inspectable source diffs, and the other eight remain unavailable locally. The manual review template remains pending, historical blobs are unavailable for at least one tested blame trace, and no defensible negative-label method or leakage-safe evaluation population exists.

The pre-training verifier and machine-readable result are:

- `scripts/preflight/verify_rq1_pretraining.py`
- `data/preflight/rq1_pretraining_verification.json`
- This report: `docs/rq1_pretraining_verification_report.md`

Reproduce the offline verification from the project directory:

```powershell
python -B scripts\preflight\verify_rq1_pretraining.py
```

The verifier sets `GIT_NO_LAZY_FETCH=1` for its Git subprocesses and writes only the approved JSON output. It does not repair or overwrite the original research datasets. To repeat a full `git fsck`, first address the partial-clone/promisor behavior with an explicitly approved, bounded plan; do not allow an unplanned network fetch.

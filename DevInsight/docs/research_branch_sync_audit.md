# Research Branch Synchronization Audit

## 1. Current branch

- Current branch: `Research`
- Research HEAD: `9362ace7f4ab56800a0d1efa83f1c45b2c0080c9` (`docs(research): finalize first-half RQ1-RQ3 methodology and evaluation evidence`)
- Merge base with upstream: `7bd4221fe21d8025f62a79c9080f6652cfc778f1`
- Audit found no staged or tracked-file changes. The only working-tree entries before creating this report were the untracked research files listed in Section 8.
- The upstream fetch updated remote-tracking references only. No merge, rebase, reset, branch switch, stage, commit, push, or source modification was performed.

## 2. Upstream repository

- Remote name: `upstream`
- Fetch URL: `https://github.com/Nilakshi239/DevInsight-AI.git`
- Push URL: `https://github.com/Nilakshi239/DevInsight-AI.git`
- The remote already existed; no remote configuration change was needed.
- Fetched with `git fetch --no-tags upstream main`.
- Fetched `upstream/main`: `125ba52894313fde643209ce9e300062b29c73f5` (`Merge pull request #14 Integrate completed DevInsight frontend into main`).

## 3. Ahead/behind counts

`git rev-list --left-right --count Research...upstream/main` returned:

| Research only (ahead) | Upstream only (behind) |
|---:|---:|
| 4 | 5 |

These are commits unique to each branch, not file counts.

## 4. Research-only commits

All four commits are by Dasith Randula (`dasithrandula1234@gmail.com`):

| Commit | Date | Subject |
|---|---|---|
| `9362ace7f4ab56800a0d1efa83f1c45b2c0080c9` | 2026-11-11 | `docs(research): finalize first-half RQ1-RQ3 methodology and evaluation evidence` |
| `8ae6c8ab8df1eec9d54133444031e25629854e3c` | 2026-11-10 | `docs(research): finalize first-half repository suitability assessment` |
| `c7b167a7a85bc86433cc1c9c973da1ae44b2f8ec` | 2026-11-10 | `docs(research): complete repository screening and bug evidence review` |
| `9f8ea8c8b6e74eed42ee6cc0b61cc20720101497` | 2026-11-10 | `feat(research): configure and verify 10 public GitHub repositories` |

The Research-only diff adds 25 files under `DevInsight/config/`, `DevInsight/data/`, `DevInsight/docs/`, and `DevInsight/scripts/`. It consists of research repository/configuration data, RQ1/RQ2/RQ3 methodology and evidence documentation, and research/preflight scripts. These are additions on the Research side.

## 5. Upstream-only commits

| Commit | Author | Date | Subject |
|---|---|---|---|
| `125ba52894313fde643209ce9e300062b29c73f5` | Dasith Randula (`146138809+Dasith-Randula@users.noreply.github.com`) | 2026-11-11 | `Merge pull request #14 Integrate completed DevInsight frontend into main` |
| `8db334f5593b9fcd5f0ead4142ba82e4f8ea6479` | Dasith Randula (`dasithrandula1234@gmail.com`) | 2026-11-11 | `fix(frontend): polish manager interactions and animations` |
| `40f95b97980b05a3ae24eda284100eef345358e4` | Dasith Randula (`dasithrandula1234@gmail.com`) | 2026-11-11 | `feat(frontend): implement manager workspace and unify dashboard design` |
| `e4cb00198510356177c7879281e80f194f4879de` | Dasith Randula (`146138809+Dasith-Randula@users.noreply.github.com`) | 2026-11-10 | `Merge pull request #13 from Dasith-Randula/Frontend` |
| `5205b92bcc3b6aedcb9b1a9183f58d327c67a9cb` | Dasith Randula (`dasithrandula1234@gmail.com`) | 2026-11-10 | `Integrated the dark mode and redesign the UI` |

The upstream-only net diff changes 34 files, all in the Flutter web dashboard and its tests. It adds the manager workspace/pages/widgets and tests, changes developer dashboard/theme/auth-related UI, and adds shared dashboard/wordmark components. These are application frontend changes and bug-fix/polish work, not new backend implementation.

## 6. Changed-file comparison and merge conflicts

The actual repository tree contains root-level `backend/`, `apps/web_dashboard/`, `ml/`, `docs/`, and `data/`, as well as the nested `DevInsight/` project tree used by the Research-only additions. The upstream-only frontend changes are under `DevInsight/apps/web_dashboard/` in Git paths.

For the areas requested in this audit:

| Area | Upstream-only changes |
|---|---|
| Backend | None |
| Flutter/frontend | 34 changed/added files under `DevInsight/apps/web_dashboard/`, including manager UI, shared widgets, developer UI, theme, and tests |
| ML | None |
| Research documentation/data | None |
| Git ignore/configuration | None |

Research-only additions are in `DevInsight/config/`, `DevInsight/data/`, `DevInsight/docs/`, and `DevInsight/scripts/`; they do not have same-path upstream-only changes.

A non-mutating merge preview, `git merge-tree --write-tree Research upstream/main`, completed successfully with exit code 0 and produced tree `37b3118f9a7b7f8b8c4bc654bc62fbf9444b53ff`. No textual or add/add conflicts were reported. This predicts a clean Git merge; it does not replace post-merge Flutter tests or runtime validation.

## 7. Merge risks

- **Git conflict risk:** Low based on the merge-tree preview; no conflicts were detected.
- **Frontend impact:** The upstream commits add the manager dashboard and polish the shared Flutter UI. They are substantial application changes (34 files; net 5,647 insertions and 1,397 deletions in the upstream-only comparison), so visual/runtime behavior should be validated after any future merge.
- **Backend impact:** No upstream-only backend files changed.
- **Research/ML impact:** No upstream-only changes target the RQ1 package, RQ1 reports, or research data.
- **Integration risk:** A conflict-free tree preview cannot establish that the merged application builds or passes tests. Run the relevant Flutter tests/analyzer after merging.

## 8. Untracked file safety

At audit time, Git reported these protected files as untracked:

- `data/bug_fix_review.csv`
- `data/bug_fix_review_timeline_cache.json`
- `data/bug_issue_samples_pilot.csv`
- `data/repository_bug_audit_pilot.csv`

The entire `ml/rq1/` package is also untracked; its ignored subdirectories include `.venv/`, datasets, models, figures, predictions, and Python cache files.

No upstream-only changed path exactly overlaps these untracked paths. The upstream-only diff contains no RQ1 or data paths. The protected files and RQ1 package were not modified, staged, or deleted. Research-only commits add some similarly named research datasets under `DevInsight/data/`, but those are distinct paths from the four protected untracked files.

Before any future merge, retain the current untracked files and re-check `git status`; do not use `git clean` or broad cleanup commands.

## 9. Recommended synchronization approach

**Recommendation: A — keep Research diverged until the RQ1 package is ready for its separate, reviewed commit.** Synchronization is not required merely to commit the independent `ml/rq1/` package. This avoids combining an application frontend update with the research-package delivery and preserves a clear review boundary.

The audit indicates that **B — merge `upstream/main` into Research** is technically viable when synchronization is desired: the remote is present, the merge preview is conflict-free, and incoming changes do not overlap the untracked package or protected files. Prefer this non-history-rewriting merge over rebasing if synchronization is required.

**C — rebase Research onto `upstream/main` is not recommended** here: it rewrites the four Research-only commit identities and provides no necessary benefit for this audit.

If the merge is made after all five upstream-only commits are fetched, the expected ancestry count is **5 ahead and 0 behind** relative to `upstream/main`: the four Research-only commits plus the merge commit, with all five upstream-only commits incorporated. A rebase would instead normally show 4 ahead and 0 behind, with rewritten Research commits.

## 10. Exact safe commands for a later synchronization

These commands are recommendations only; none was executed as an integration action:

```powershell
git status --short --branch
git fetch --no-tags upstream main
git merge --no-ff --no-commit upstream/main
git status --short --branch
git diff --cached --check
```

Review the staged merge diff and run relevant Flutter validation before creating the merge commit. If the merge presents unexpected conflicts or file changes, stop and inspect them; to abandon an in-progress merge, use `git merge --abort`. Do not stage the RQ1 package or protected research files as part of the merge. After a successful merge commit, verify with:

```powershell
git rev-list --left-right --count Research...upstream/main
git status --short --branch
```

Expected divergence after the merge commit: `5 0`. Keep the RQ1 package commit separate.

## 11. Final assessment

**PASS — synchronization audit completed.** The current branch is `Research`, the upstream remote is configured and fetched, and the 4-ahead/5-behind divergence is verified. The merge preview is conflict-free, with no upstream backend, ML, research-data, or ignore/configuration changes and no untracked-path collision detected.

This PASS is an audit result, **not approval to merge automatically**. Upstream can be merged into Research with low Git conflict risk, but it is not necessary before the RQ1 ML package commit. Keep the branches diverged for now if preserving a focused research commit is the priority; use a reviewed non-FF merge later if branch synchronization is required.

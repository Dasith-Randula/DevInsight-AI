# DevInsight - First-Half Repository Selection Report

## 1. Objective

Document the provisional selection of ten public GitHub repositories for the first 50% project evaluation.

## 2. Dataset Scope

- Repositories: 10
- Python repositories: 5
- Dart repositories: 5
- Reviewed GitHub issues: 30
- Verified fix relationships in sample: 11
- Candidate fix relationships in sample: 10

## 3. Repository Assessment

| Repository | Language | Commits | Workflow Files | Verified Fixes | Candidates | Assessment |
|---|---|---:|---:|---:|---:|---|
| encode/httpx | Python | 1523 | 2 | 3 | 0 | PROMISING_SAMPLE |
| fastapi/fastapi | Python | 8047 | 18 | 3 | 0 | PROMISING_SAMPLE |
| pallets/flask | Python | 5566 | 5 | 2 | 0 | PROMISING_SAMPLE |
| pydantic/pydantic | Python | 5936 | 9 | 0 | 1 | FURTHER_REVIEW |
| pytest-dev/pytest | Python | 17896 | 6 | 1 | 2 | PROMISING_SAMPLE |
| felangel/bloc | Dart | 2838 | 1 | 0 | 2 | FURTHER_REVIEW |
| rrousselGit/riverpod | Dart | 2656 | 5 | 2 | 1 | PROMISING_SAMPLE |
| cfug/dio | Dart | 962 | 7 | 0 | 3 | FURTHER_REVIEW |
| firebase/flutterfire | Dart | 4592 | 28 | 0 | 0 | FURTHER_REVIEW |
| fluttercommunity/plus_plugins | Dart | 2384 | 13 | 0 | 1 | FURTHER_REVIEW |

## 4. Initial Findings

- Repositories with at least one verified fix in the three-issue sample: 5
- Repositories needing further fix evidence: 5
- All ten repositories are retained provisionally.

## 5. Research Limitations

- Three issues per repository are insufficient for a final repository-wide quality judgment.
- Candidate PRs must not be treated as merged fixes.
- Commit counts are not equivalent to labeled ML training observations.
- Workflow configuration files do not establish CI run history or CI reliability.
- This report is a preliminary repository selection, not final research validation.

## 6. First-Half Evaluation Scope

Completed: Repository cloning, history verification, screening, initial bug audit, and evidence review.

Deferred: Full historical dataset extraction, defect-label validation, ML training, RQ1/RQ2 experiments, and RQ3.

## 7. Provisional Selection Decision

Retain all ten repositories for the next development stage, with targeted quality checks required for weaker evidence samples.

## 8. Supporting Evidence

- config/research_repositories.csv
- config/repository_setup_manifest.csv
- data/repository_screening.csv
- data/repository_bug_audit.csv
- data/bug_fix_review_auto.csv
- docs/bug_fix_evidence_review.md

# RQ2 Methodology — First-Half Evaluation

## Status and scope

This is a proposed methodology, not an implemented prioritization system or an experimental result. It is prepared for the first 50% evaluation using the project README, RQ1 evidence, and the current application/backend structure. No priority scores, severity labels, deadlines, workload values, or model predictions are asserted as real data.

## 1. Research Question 2

The project’s current research-question wording in the [project README](../README.md) is:

> To what extent does combining technical risk with project requirements, severity, CI/CD information, developer workload, and delivery context support project-aware prioritization compared with technical-risk ranking alone?

This formulation is retained as the working RQ2. Issue descriptions, deadlines, business impact, and verified team capacity are candidate context variables when they are actually supplied and available; they should not be assumed present for every issue.

## 2. Research problem and motivation

Technical defect risk alone does not determine which software problem should be addressed first. A lower technical-risk problem may threaten a critical requirement or an imminent delivery, while a higher-risk problem may have limited immediate project impact. RQ2 will investigate whether adding reliable project context to technical-risk evidence produces rankings that better support project decisions than technical-risk ranking alone.

The challenge is to represent project context transparently without fabricating missing data, turning commit activity into an individual productivity score, or confusing predicted technical risk with business severity.

## 3. Aim and objectives

**Aim:** Design and evaluate a context-aware method for ranking software issues for attention.

**Objectives (planned):**

1. Define issue-level technical-risk evidence and how it can be linked to validated RQ1 predictions.
2. Define project-context inputs, their provenance, missingness, and time of availability.
3. Compare a technical-risk-only baseline with a transparent context-aware ranking.
4. Compare both rankings with independent human expert judgments using ranking metrics and documented limitations.

## 4. Relationship between RQ1 and RQ2

RQ1 is intended to estimate technical defect risk for a clearly defined prediction unit, such as a commit, file, or change. Its present evidence base is not a trained model: no validated defect-inducing labels, training dataset, feature matrix, or prediction model exists. The RQ1 methodology currently describes commit-level defect-inducing prediction; the root README describes defect-prone files or changes. This granularity difference is unresolved and must be agreed before creating an RQ1-to-issue mapping.

After RQ1 is validated, an issue may receive technical-risk evidence only when there is a traceable relationship to relevant code changes or files. RQ2 then combines that technical evidence with issue and project context. RQ2 cannot treat the presence of a GitHub issue link, an issue label, or a fixing commit as proof of the issue’s risk or severity.

## 5. Existing data availability

**Verified first-half evidence:** The RQ1 preparation includes ten provisional repositories (five Python, five Dart), a sample of 30 issues (three per repository), 11 automated `VERIFIED_FIX` issue/fix relationships, and saved issue timelines. Those categories are preliminary evidence, not expert-adjudicated RQ2 priorities or a model-ready dataset. Fix-to-implementation provenance is incomplete and manual review remains pending.

**Current application infrastructure:** The authenticated FastAPI GitHub integration can connect and list public repository connections, retrieve a repository overview, refresh a connection, and disconnect it. The Developer web dashboard displays repository metadata, recent commits/issues/pull requests, issue labels/state/timestamps in recent activity, open issue and PR counts, recently closed issue counts, weekly participation when complete, and repository/CI signals for the latest default-branch commit.

This is bounded descriptive data, not a complete issue-tracking or project-planning dataset. The current issue activity representation surfaces titles, labels, state, URLs, and timestamps; issue descriptions are not exposed in that summary. There is no verified standardized severity, project requirements, business impact, deadline, assignment/capacity, or personal workload data. CI status is a repository signal for the latest commit, not necessarily tied to an individual issue. Missing or incomplete API results must remain unavailable, not be interpreted as zero.

The source structure found in this checkout includes the Developer dashboard and GitHub API integration, but no Manager-specific Flutter feature directory. A manager-facing prioritization UI remains proposed, not verified as implemented.

## 6. Proposed RQ2 inputs

Every input should carry a source, timestamp, scope, and availability state.

| Input | Potential source | First-half availability |
|---|---|---|
| Issue title, URL, state, labels, creation/update/closure timestamps | GitHub issue metadata | Partially present in repository summaries and research sample |
| Issue description and discussion | GitHub issue endpoint/timeline | Not exposed by the current overview summary; future retrieval required |
| Severity | Explicit repository label or authorized human entry | No common verified severity field; never infer or silently assign |
| Technical-risk signal | Validated RQ1 model with traceable file/commit association | Not available; RQ1 model and label population do not exist |
| Project requirement/importance | Project requirements supplied by an authorized user | Not currently integrated or present in verified evidence |
| CI/CD signal | GitHub checks/status for a specific commit | A latest-default-branch repository signal exists; issue-level association is not established |
| Deadline/delivery context | Explicit project milestone or due date | Not currently available in the verified GitHub overview |
| Business impact | Explicitly supplied, reviewable project context | Not currently available |
| Team capacity | Verified aggregate team availability for a stated period | Not currently integrated; individual workload is not inferable from commit counts |

## 7. Data preprocessing methodology

**Planned:**

1. Preserve raw GitHub and user-supplied records with immutable IDs, URLs, retrieval times, and source provenance.
2. Normalize issue state, timestamps, repository identifiers, label text, and time zones without discarding original values.
3. Separate explicit values from inferred text signals. Any future text-derived classification must be clearly marked as model-generated, validated, and reviewable.
4. Link issue records to commits/files only through documented references, reviewed PR relationships, or a separately validated linking procedure; retain ambiguous or many-to-many links.
5. Represent each field as observed, missing, stale, unavailable, or not applicable. Do not substitute zero for unknown severity, impact, deadline, or capacity.
6. Prevent temporal leakage: only information available at the ranking time may be used. Exclude later issue comments, future fixes, and future CI results.
7. Deduplicate issue/PR relationships and record repository-specific label definitions before comparing projects.

## 8. Context-aware issue prioritization approach

**Proposed methodology:** Compare a technical-risk-only ranking against a context-aware multi-criteria ranking. For each issue, present the contributing criteria and their evidence separately. A future scoring function may use normalized technical risk, explicit severity, requirement importance, delivery urgency, verified CI evidence, stated business impact, and aggregate available team capacity. Weights, normalization, missing-data behavior, and thresholds must be specified and reviewed before experiments; no weighting scheme is validated at this stage.

The approach should avoid double-counting correlated signals and should not produce a confident total when critical inputs are missing. Where inputs are missing, either show a partial ranking with clear unavailable criteria or abstain from a composite rank according to a predeclared rule. Rank bands (if used) must be calibrated against the evaluation protocol, not chosen after observing desired results.

## 9. Risk and severity considerations

Technical defect risk is an estimate about defect propensity under the RQ1 target; severity is the consequence or urgency of an issue. They are distinct dimensions. Severity should be used only when supplied in an explicit label field or reviewed project input with documented semantics. Labels such as `bug` do not automatically mean high severity. Conflicting or absent severity remains unknown and is displayed as such.

Any risk estimate must show model version, target definition, prediction unit, timestamp, and uncertainty. Until RQ1 is validated, the technical-risk field is unavailable and no technical-risk ranking should be represented as a model output.

## 10. Business impact and deadline considerations

Business impact and delivery dates may influence order only when explicitly supplied and attributable to an authorized project source. A deadline date can support a transparent time-to-deadline criterion; it does not by itself establish impact or severity. Missing, stale, or contradictory requirements and dates are surfaced for confirmation rather than guessed. The system should show which project requirement is affected and cite its source.

## 11. Team capacity and workload considerations

Capacity may be represented at a verified team level for a defined time period, using explicit availability information supplied by authorized team members or an approved integration. It is contextual planning data, not an individual performance measure. Commit counts, author activity, issue counts, and repository participation must not be used alone to infer productivity, skill, capability, or workload.

The system should not assign individual work or generate personal scores in this research stage. If capacity data are incomplete or not consented to, prioritization should omit that criterion and disclose the omission.

## 12. Handling missing and incomplete inputs

Maintain field-level provenance and missingness states. Do not coerce missing numeric values to zero, treat unavailable GitHub results as absence, or infer issue severity from title tone. Incomplete GitHub search results, processing responses, rate limits, stale caches, and unsupported fields should be visibly identified. Define a minimum-evidence rule for displaying any composite ranking. When that rule is not met, show an unranked/insufficient-evidence state and the missing information needed.

## 13. Proposed explainable priority ranking

For each issue, the proposed output is a rank plus a compact rationale: technical-risk evidence (when validated), explicit severity, requirement/impact, deadline, relevant CI evidence, and available aggregate capacity. It should include evidence links, timestamps, unavailable criteria, model/rule version, and uncertainty. Users must be able to inspect criterion-level contributions and understand why two issues were ordered differently.

The formula and weights are a research object to be defined and evaluated, not a scientific result. Ranking must never imply that the system made a final project decision.

## 14. Example prioritization workflow

**HYPOTHETICAL EXAMPLE — invented solely to explain the planned method; not real GitHub evidence, not a model prediction, and not an observed project result.**

Assume two fictional issues are presented to a project team:

- **Issue A:** a hypothetical parser edge case with a higher *illustrative technical-risk input* but no supplied deadline or requirement impact.
- **Issue B:** a hypothetical export defect with a lower *illustrative technical-risk input*, an explicitly supplied critical-release requirement, and a confirmed near-term milestone.

The technical-risk-only baseline would place Issue A first under these invented inputs. The context-aware method could place Issue B first because its verified release requirement and supplied milestone make its delivery consequence more immediate. No severity, business-impact value, capacity, or numerical score is assumed. The interface would show these as hypothetical context criteria and leave unavailable fields marked unknown. A project expert would confirm or reject the resulting order.

## 15. Future model/system architecture

The planned pipeline is:

1. Retrieve authenticated, scoped GitHub issue/PR/commit evidence and explicit project context.
2. Validate and normalize records while retaining source links, timestamps, and missingness.
3. Run RQ1 only after its labels, model, and temporal evaluation are validated; attach predictions to issues only through traceable code/issue relationships.
4. Compute a transparent RQ2 ranking with an auditable baseline and context criteria.
5. Send rank and cited evidence to an explanation layer (RQ3).
6. Present suggestions and uncertainty to a human Developer/Project Manager interface for review.

The current implementation covers parts of repository connection and descriptive GitHub overview. RQ1 inference, RQ2 prioritization, and RQ3 explanation/recommendation are planned. The current checkout does not contain a Manager-specific Flutter feature; that interface remains a planned surface.

## 16. Proposed evaluation methodology

Evaluate on a fixed, consented set of issues with enough complete context and independent expert judgments. Compare:

1. **Rule-based baseline:** a predeclared ranking using explicit available fields and transparent precedence rules.
2. **Technical-risk baseline:** RQ1 risk ranking alone, only after RQ1 is valid.
3. **Context-aware ranking:** the proposed combined criteria, frozen before test judgments are revealed.
4. **Human expert reference:** independent project experts rank or pairwise-compare the same issues using a written rubric; record disagreement and inter-rater agreement.

Possible ranking metrics include NDCG@k, MAP, Spearman’s rank correlation, Kendall’s tau, and pairwise ordering accuracy. Report metric definitions, confidence intervals, missing-data coverage, and per-project variation. Keep issue families and repositories separated as appropriate to prevent leakage. A blinded user study may assess usefulness and decision time, subject to ethics and consent. Do not calculate results until a valid dataset and protocol exist.

## 17. Threats to validity

- **Construct validity:** technical risk, severity, urgency, business impact, and priority may be conflated.
- **Label validity:** RQ1 labels and issue/commit mapping are not yet validated; expert priorities may disagree.
- **Measurement validity:** GitHub labels and workflow conventions vary by repository; current overview does not provide all desired context.
- **Missingness bias:** unavailable project context may systematically differ across teams or issues.
- **Temporal validity:** stale metadata, future comments, fixes, or CI outcomes could leak later knowledge.
- **External validity:** ten provisional Python/Dart repositories and a 30-issue first-half sample do not represent all projects.
- **Human-reference bias:** expert judgments are contextual, potentially inconsistent, and not a universal ground truth.
- **Workload/privacy validity:** commit activity is not a valid proxy for capacity or individual productivity; any future capacity integration needs consent and governance.
- **Operational validity:** rate limits, partial API results, and project-specific integrations can affect evidence completeness.

## 18. First-half achievements

**Completed and verified:** RQ1 research preparation established ten provisional repository histories and audited a bounded 30-issue evidence sample. The current authenticated GitHub integration connects public repositories and provides descriptive repository, issue, pull-request, commit, and selected CI signals. Existing UI work provides a Developer dashboard and issue/repository surfaces.

**Not completed:** No RQ1 model or issue-priority ranking exists. Severity, requirements, deadlines, business impact, and verified team capacity are not integrated. No Manager-specific Flutter source was found in the current checkout.

## 19. Remaining research implementation work

1. Resolve the RQ1 prediction-unit wording and its mapping to issue-level decisions.
2. Define project-context schemas, ownership, freshness, privacy, and missingness behavior.
3. Expand GitHub issue retrieval to the fields required by the approved methodology.
4. Complete RQ1 provenance, labeling, feature extraction, and model evaluation gates.
5. Implement a baseline ranking and an auditable context-aware ranking only after approved data exist.
6. Design a manager-facing review surface without implying automated authority.
7. Run the predeclared expert comparison and ranking-metric evaluation.
8. Document limitations and iterate with human feedback; do not infer personal performance.

# RQ3 Methodology — First-Half Evaluation

## Status and scope

This document proposes an explainability and root-cause-investigation methodology. No SHAP calculation, LLM inference, verified root-cause finding, or AI-generated recommendation is currently claimed or implemented.

## 1. Research Question 3

The project’s current wording in the [project README](../README.md) is:

> How useful are traceable explanations and grounded AI-generated recommendations in helping developers and project managers determine which software problems deserve attention and what actions they should consider?

The research will evaluate whether evidence-linked explanations and carefully bounded recommendations support human investigation and decision-making. “Root cause analysis” in the project title means supporting an investigation; it does not promise automatic proof of defect causality.

## 2. Research problem and motivation

Risk predictions and priority rankings are difficult to trust when users cannot see what evidence influenced them. Model explanations can make influential input features visible, while retrieved GitHub evidence can connect a proposed explanation to an issue, pull request, commit, or code change. Both methods have limits: feature attribution is not causality, Git blame is not proof of cause, and LLM text can be incorrect even when it sounds plausible.

RQ3 therefore studies the usefulness and evidence quality of explanations and recommendations, with uncertainty, traceability, and human review as requirements.

## 3. Aim and objectives

**Aim:** Design and evaluate transparent explanations and evidence-grounded assistance for investigating software defects and project risks.

**Objectives (planned):**

1. Explain a validated RQ1 prediction and RQ2 ranking using their actual inputs and model/rule versions.
2. Retrieve traceable issue, PR, commit, and code-change evidence relevant to a question.
3. Generate bounded explanations or recommended investigative actions from retrieved evidence, if an approved LLM is selected.
4. Identify uncertainty, conflicting evidence, and unsupported claims; require human confirmation for causal conclusions.
5. Evaluate explanation faithfulness, evidence support, traceability, and usefulness to developers/project managers.

## 4. Relationship with RQ1 and RQ2

RQ1 is planned to estimate technical defect risk. It is not trained and its current label evidence is insufficient. Once validated, RQ1 can provide model predictions and local feature contributions.

RQ2 is planned to rank issues using technical risk plus available project context. Its ranking criteria and evidence should be exposed to RQ3 rather than hidden inside a score.

RQ3 consumes predictions, ranking criteria, and retrieved evidence. It does not repair unresolved RQ1 labels, create missing RQ2 context, or turn a ranking into a causal statement. Human decisions may be recorded for later study, but they must not silently become training labels.

## 5. Explainable AI requirements

**Planned requirements:**

- Identify the prediction target, unit, model/rule version, timestamp, and relevant project scope.
- Distinguish model inputs, feature contributions, retrieved facts, and generated hypotheses.
- Show positive and negative contributions in context, including missing inputs and known uncertainty.
- Link every factual statement to a source issue, PR, commit, file, or other traceable artifact.
- State that attribution indicates model behavior, not why a defect was caused.
- Do not show explanations for an invalid, unavailable, stale, or unvalidated prediction as though it were reliable.

## 6. Proposed SHAP or suitable XAI methodology

After a validated RQ1 model exists, SHAP may be evaluated for local feature attribution and global behavior summaries. Choose an explainer suited to the model type and feature representation; document background/reference data, sampling, preprocessing, model version, and computation settings. Compare explanation stability across samples or reasonable perturbations and check correlated-feature effects.

For non-tree or mixed data, a suitable model-agnostic or intrinsically interpretable alternative may be more appropriate than forcing SHAP. Explanations must be computed from the exact model inputs used for the prediction. SHAP attributes the model output to features relative to its background distribution; it does **not** prove defect causality or the correctness of a feature.

No SHAP values or feature importance results currently exist.

## 7. Explanation of feature contributions

**Planned:** For each prediction, show which observed features moved the model output toward or away from its baseline, their values and availability, and the feature definition. Explain the baseline and prediction output in plain language without turning probability into certainty. When features are correlated, explain that attribution can be distributed across them. Global rankings summarize the evaluated sample and should not be described as universal causes.

For an RQ2 issue rank, separately list the criteria that affected ordering, their source and freshness, unavailable criteria, and the ranking-rule version. Do not equate feature contribution, priority contribution, and causal contribution.

## 8. Evidence retrieval from GitHub

**Current capability:** The authenticated backend connects public repositories and caches selected repository summaries: repository metadata, recent commit/issue/PR activity, issue labels/state/timestamps, aggregate counts, weekly participation when complete, and selected latest-commit/CI signals.

**Limitations:** The current overview does not provide a complete issue corpus, issue descriptions, verified issue-to-code relationships, historical CI evidence for each issue, or complete historical blobs. It cannot alone support authoritative root-cause analysis.

**Planned retrieval:** Use scoped repository and time filters; retrieve relevant issue descriptions/timelines, linked PR metadata and commit lists, commit details/diffs, and code-line context where available. Persist stable URLs/IDs, retrieval timestamps, commit SHAs, file paths and line ranges, and completeness status. Respect access controls, rate limits, privacy, and licensing. Incomplete retrieval must be declared.

## 9. Issue, PR and commit relationship analysis

Create an evidence graph linking issue → discussion/labels → PR → PR commits → merged commit(s) → changed files/lines. Treat explicit references, API-reported relationships, and text similarity as different evidence types. Validate links against merge state and commit ancestry where local objects permit. Preserve one-to-many and many-to-many relationships and conflicts.

A matching PR number in a commit subject is only a lead. The current RQ1 audit found local PR-subject matches for 11 issue/fix records, but only three mapped source diffs were inspectable; the other eight matched diffs are unavailable locally. No issue-to-inducing-commit graph is verified. Do not treat a fix commit as an inducing commit.

## 10. Proposed LLM-assisted explanation workflow

If an LLM is approved for the second research phase:

1. Validate that the prediction/rank and its version are available.
2. Retrieve a bounded evidence packet with stable references and explicit gaps.
3. Construct a prompt that permits only claims supported by packet contents; ask for citations and uncertainty.
4. Generate a concise explanation and proposed investigative next steps, not an asserted root cause.
5. Check references, quoted metadata, dates, SHAs, and claims against the source records.
6. Flag unsupported, contradictory, or low-confidence output and route it for human review.
7. Store model/version, prompt template version, retrieved evidence IDs, output, validation findings, and reviewer disposition.

No LLM API calls or generated explanations are currently part of the verified application functionality.

## 11. Prompt grounding and evidence validation

Prompts should label retrieved content as untrusted evidence, separate evidence from instructions, and request a fixed schema with claim text, citation IDs, uncertainty, and follow-up checks. The application should resolve each citation to a retrieved record and verify that the cited source exists and matches the stated repository, issue/PR number, SHA, and path. Validate claims mechanically where possible and manually for semantic support. A citation’s existence does not prove that the interpretation is correct.

## 12. Hallucination prevention

- Restrict the model to supplied evidence and instruct it to abstain when evidence is insufficient.
- Require a citation for every repository-specific factual claim.
- Keep recommendations in an explicit “suggested investigation” category.
- Reject or flag nonexistent SHAs, mismatched paths, unsupported dates, and uncited claims.
- Do not permit inferred severity, deadline, workload, or business impact to appear as facts.
- Report retrieval incompleteness, conflicting sources, and model uncertainty.
- Do not display a cause as verified without independent human investigation and supporting evidence.

These are planned safeguards; they do not guarantee hallucination-free output.

## 13. Human review and uncertainty handling

Present explanations as decision support. Reviewers should be able to inspect original records, correct a relationship, mark a hypothesis unsupported, record disagreement, or defer a decision. Show missing evidence and avoid a single certainty-like score. Separate model confidence from evidence completeness and reviewer confidence. Preserve reviewer actions as review metadata, not automatic ground truth.

## 14. Proposed root cause investigation workflow

1. Start from a reviewed issue or a model/priority item with valid provenance.
2. Show the prediction/rank context and its limits.
3. Retrieve related issue discussion, PRs, commits, files, diffs, and prior history.
4. Identify candidate contributing changes using validated methods such as SZZ only when prerequisites are met.
5. Use SHAP to explain model inputs, not causality; use history/blame as attribution evidence, not causal proof.
6. Ask the LLM, if approved, to summarize supported evidence and propose checks.
7. Have a developer/reviewer inspect source and tests, then record whether a cause was confirmed, rejected, or unresolved.

The system supports investigation and hypothesis generation. It must not fabricate or automatically certify root causes.

### HYPOTHETICAL explanation example

**This is an invented example for methodology illustration only. It is not a real GitHub issue, model prediction, SHAP result, retrieved commit, or verified cause.**

- **Prediction context:** Assume a future validated model is asked to assess a fictional change associated with a hypothetical “CSV export truncates long fields” issue. No probability or measured risk value is asserted.
- **Feature-contribution interpretation:** Suppose the future model-specific explanation indicates that the hypothetical change size and edits to a parsing-related file move its output above its reference baseline, while prior file history moves it slightly in the opposite direction. These are illustrative directions only; no numeric SHAP values exist.
- **Retrieved evidence:** In this fictional scenario, an evidence packet contains the issue URL, a linked PR URL, a merged commit SHA, and a diff path. Each reference is assumed to resolve to matching records for the example; none is actual project evidence.
- **Potential contributing factors:** The changed parsing behavior may be relevant to the reported truncation, and a test case for long fields may be absent from the hypothetical diff. These are investigation hypotheses, not causal findings.
- **Uncertainty:** The issue-to-commit link and change-to-failure mechanism have not been independently reproduced; feature attribution does not establish cause, and the evidence packet may be incomplete.
- **Human verification:** A developer must reproduce the issue, inspect the cited diff and relevant tests, and record the cause as confirmed, rejected, or unresolved. Until then, the explanation remains a hypothesis.

## 15. Proposed RQ3 system architecture

Inputs are a versioned RQ1 prediction, an RQ2 ranking with criterion provenance, and a retrieved evidence packet. A deterministic validation layer checks source references before a presentation layer displays feature contributions, evidence-backed statements, hypotheses, and uncertainty. Any future LLM is an optional language layer, never the source of prediction or the final cause determination.

The current codebase contains GitHub retrieval and a Developer web dashboard. RQ1 inference, RQ2 priority generation, SHAP, evidence-graph analysis, LLM grounding, and verified root-cause workflows are planned. No Manager-specific Flutter source was found in this checkout.

## 16. Proposed evaluation criteria

Evaluate separately:

- **Attribution faithfulness:** whether explanations reflect actual model behavior under appropriate perturbation or model-specific checks.
- **Stability:** whether similar inputs produce reasonably consistent explanations.
- **Evidence traceability:** citation resolution rate and correctness of issue/PR/commit/path references.
- **Claim support/factuality:** blinded expert assessment of whether each claim follows from cited evidence; record unsupported claims and abstentions.
- **Uncertainty calibration:** whether uncertainty/abstention reflects evidence completeness and known limitations.
- **Usefulness:** task-based expert/developer study measuring comprehension, investigation quality, decision confidence calibration, and time, with an appropriate control condition.
- **Root-cause quality:** reviewer agreement and adjudicated status (confirmed, rejected, unresolved), not LLM assertion alone.

Predefine participant expertise, task set, rubric, sample size rationale, inter-rater agreement, privacy/ethics procedures, and analysis before collecting study results. No evaluation values are available.

## 17. Threats to validity

- SHAP attribution can be sensitive to correlated features, background data, and model choice; it is not causal evidence.
- Git blame and SZZ may misattribute defect introduction, especially across refactors, merges, and incomplete history.
- Partial clones currently lack some historical blobs; issue-to-PR/commit provenance is incomplete.
- GitHub metadata may be stale, missing, inconsistent, or shaped by repository-specific conventions.
- LLM outputs may hallucinate, misread evidence, omit contradictory sources, or be vulnerable to prompt injection from repository text.
- Citation presence does not establish semantic support; automated validators may miss subtle errors.
- Human judgments can vary by expertise, role, project context, and anchoring on AI output.
- A selected sample of ten repositories and 30 issues limits generalization.
- User studies and workload/context data require privacy, consent, and safeguards against individual performance scoring.

## 18. First-half achievements

**Completed and verified:** RQ1 evidence has been audited, with known limitations documented; an authenticated GitHub integration and Developer web dashboard provide selected repository and issue/PR/commit metadata. These are prerequisites for evidence retrieval, not implemented XAI or root-cause analysis.

**Investigated but unresolved:** Eight local PR-reference diffs remain unavailable; historical blame could not be completed for one pytest trace; the 30-case manual review template remains pending. The separate proposal-like document found locally is the project README; a standalone official proposal was not found in the checked workspace.

**Not implemented:** No trained RQ1 model, SHAP computation, RQ2 ranking, LLM inference, generated recommendation, evidence-grounded explanation, or verified cause determination.

## 19. Remaining research work

1. Align the RQ1 prediction unit/target with the official proposal wording.
2. Complete RQ1 label and fix-provenance review; obtain historical objects under an approved process.
3. Implement and validate issue/PR/commit evidence relationships.
4. Define the RQ2 ranking and its provenance/missingness contract.
5. Train and validate an RQ1 model before selecting XAI methods and computing SHAP.
6. Select an LLM or non-LLM explanation approach; establish prompt, evidence, and safety evaluation.
7. Implement claim/citation validation, abstention, uncertainty, and human review.
8. Run expert evaluation for traceability, faithfulness, usefulness, and root-cause investigation support.
9. Resolve the gap between the proposed Project Manager interface and the current checkout’s Developer-only Flutter feature structure.

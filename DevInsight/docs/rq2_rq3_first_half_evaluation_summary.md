# RQ2–RQ3 First-Half Evaluation Summary

## RQ2 — Context-aware issue prioritization

**Research question:** To what extent does combining technical risk with project requirements, severity, CI/CD information, developer workload, and delivery context support project-aware prioritization compared with technical-risk ranking alone?

**First-half verified progress:** RQ1 preparation audited ten provisional repositories and 30 sampled issue records. The authenticated GitHub integration supports public repository connections and selected metadata for recent issues, PRs, commits, repository counts, weekly activity, and latest-commit CI signals. These are infrastructure and evidence-preparation achievements, not priority outputs.

**Proposed methodology:** Compare technical-risk-only and transparent rule-based baselines with a context-aware ranking. Use only traceable, supplied inputs; retain unknown/missing values; do not infer severity, deadlines, business impact, capacity, or individual productivity from commit counts. Compare ranking quality with independent human expert judgments using appropriate ranking metrics.

**Remaining work:** Complete RQ1 labels/model first, establish prediction-to-issue links, integrate authorized requirements and delivery context, define missingness and ranking criteria, then implement and evaluate rankings. There is no current priority score or verified Manager interface in this checkout.

## RQ3 — Explainable AI and root-cause investigation

**Research question:** How useful are traceable explanations and grounded AI-generated recommendations in helping developers and project managers determine which software problems deserve attention and what actions they should consider?

**First-half verified progress:** Existing GitHub services and Developer UI provide selected repository and issue/PR/commit evidence that could support future retrieval. RQ1 verification documented substantial provenance and historical-blob limitations.

**Proposed methodology:** After validated RQ1/RQ2 outputs exist, use SHAP or a suitable XAI method for model feature contributions, retrieve stable issue/PR/commit/code references, and optionally use a constrained LLM to summarize evidence and suggest investigative checks. Validate citations and claims, expose uncertainty, and require human review. Explanations and blame do not prove causality.

**Remaining work:** Validate RQ1/RQ2 outputs, implement evidence retrieval and relationship checks, develop XAI and citation validation, evaluate any LLM with expert review, and assess explanation usefulness. No SHAP, LLM inference, generated recommendation, or verified root cause currently exists.

## How RQ1, RQ2 and RQ3 fit together

RQ1 is intended to estimate technical defect risk. Once its model and prediction unit are validated and mapped to relevant issues, RQ2 can combine that signal with verified project context to rank issues. RQ3 can then explain the prediction and ranking using feature contributions and traceable evidence, supporting—not replacing—human investigation and decisions.

## Research architecture summary

Current GitHub ingestion, Supabase-backed repository persistence, and Developer dashboard are implemented. The first-half repository/issue evidence is prepared with documented limitations. Preprocessing and label adjudication, RQ1 inference, RQ2 ranking, RQ3 XAI/evidence-grounded analysis, and a Manager-facing research interface remain planned. See the [architecture diagrams](./rq2_rq3_research_architecture.md).

## Comparison

| RQ | First-half verified progress | Current limitations | Next implementation stage |
|---|---|---|---|
| RQ1 | Ten repositories, 30 sampled issues, local fix-provenance audit | No reviewed inducing labels, trained model, complete historical blobs, or confirmed prediction-to-issue mapping | Resolve target/unit, adjudicate provenance, construct leakage-safe labels/features, evaluate baselines |
| RQ2 | GitHub metadata and selected issue/CI signals available | No ranking, standardized severity, requirements, deadlines, business impact, or verified team capacity | Define context contract and compare baseline/context rankings with expert judgments |
| RQ3 | Repository/issue/PR/commit data can seed future evidence retrieval | No SHAP, LLM, grounded explanation, root-cause determination; incomplete provenance | Implement explanation/retrieval validation and evaluate faithfulness, traceability, uncertainty, usefulness |

## First-half limitations

- RQ1’s current methodology describes commit-level defect-inducing prediction, while the project README describes defect-prone files or changes; reconcile this before connecting RQ1 to issue prioritization.
- The 30-issue sample is bounded; manual review remains pending and fix mappings are incomplete.
- Current GitHub summaries do not provide issue descriptions, comprehensive issue-level CI links, requirements, standardized severity, project deadlines, business impact, or verified capacity.
- Commit activity is not a defensible proxy for individual capability, productivity, or workload.
- The repository README describes Manager dashboard functionality, but the inspected Flutter feature tree in this checkout has no Manager-specific feature.
- No model performance, prioritization effectiveness, explanation quality, or AI recommendation results have been measured.

## Second-half implementation roadmap

1. Confirm proposal RQ1 target/prediction unit and RQ2/RQ3 evaluation scope.
2. Adjudicate RQ1 evidence and obtain approved historical data required for labeling.
3. Build and validate RQ1 labels/features/model under leakage-safe temporal evaluation.
4. Establish reliable code-to-issue links and an authorized project-context schema.
5. Implement an auditable RQ2 baseline and context-aware ranking; evaluate against independent expert judgments.
6. Implement RQ3 feature explanations, evidence retrieval/citation validation, uncertainty, and optional constrained LLM assistance.
7. Evaluate traceability, factual support, usefulness, and human root-cause investigation outcomes; document privacy and limitations.
8. Integrate validated outputs into appropriate Developer and Manager-facing experiences only after research gates pass.

## Presentation-ready key points

- **RQ1 supplies technical-risk evidence; it does not currently supply predictions.**
- **RQ2’s central claim is that technical risk and project priority are not the same.** Context must be explicit, traceable, and available—not guessed.
- **RQ3 explains model behavior and assembles evidence for human investigation.** SHAP is not causal proof; an LLM cannot certify a root cause.
- **First-half achievement:** repository/issue evidence and GitHub integration have been prepared and audited with clear limitations.
- **Second-half focus:** validate labels and models first, then evaluate context-aware ranking and evidence-grounded explanations. No research performance results are claimed.

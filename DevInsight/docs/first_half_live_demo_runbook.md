# First 50% Evaluation — Live Demo Runbook

## Demo objective and boundaries

Demonstrate the implemented Flutter Web workspaces and authenticated GitHub repository overview. Research cards are previews only. No live defect prediction, issue-priority score, workload score, SHAP explanation, LLM inference, root-cause result, or generated report should be claimed.

The Manager implementation was verified from the `Frontend` branch source, not the current Research checkout. Before demo day, use the team's known Frontend deployment/build and confirm its version. This runbook does not switch branches or modify application code.

## Pre-demo checklist

1. Use the approved demo browser/build that contains the Frontend branch Manager workspace. Confirm both roles appear in that same deployment.
2. Confirm the FastAPI process is running from `backend` using the team's configured environment. For a local default setup:

   ```powershell
   uvicorn app.main:app --reload
   Invoke-RestMethod http://127.0.0.1:8000/api/v1/health
   ```

   Expect a healthy status response. This is a pre-demo check, not a result run during this task.
3. Confirm Supabase Auth and database connectivity using the team's approved setup; do not display or paste secrets. The connected-repository migration must already be applied.
4. Confirm CORS and app/API URLs. The Flutter Web build uses the Supabase URL and publishable key plus API base URL; configure locally without exposing environment values in screen recordings.
5. Prepare authorized Developer and Project Manager demo accounts. Keep credentials off-screen and do not write them in this runbook.
6. Connect a suitable public GitHub repository ahead of time if allowed. Prefer a repository with recent issues, pull requests, commits, and available summary data; avoid depending on a live refresh succeeding.
7. Confirm the active repository, cache freshness, and expected data availability. GitHub API limits or processing responses can make some panels unavailable.
8. Close unrelated tabs/notifications, set a readable browser size, and test sign-out/sign-in flow in the target deployment before the evaluation.
9. Capture genuine screenshots during the actual demo only after confirming the displayed account/repository contains no information that should be private. No preserved terminal logs or demonstration screenshots were found in the inspected repository.

## Demonstration sequence

| # | Demonstrate | Expected result | Real backend data vs planned feature | Screenshot to preserve | Possible failure and fallback |
|---|---|---|---|---|---|
| 1 | Open DevInsight landing page, then choose Login | Landing branding and login form appear | UI is implemented; no GitHub data is required at this step | Landing page and login form, with no credentials visible | If landing fails, use the prepared known-good deployment and explain the environment issue; do not show fabricated UI. |
| 2 | Sign in as Developer using the approved account | Authenticated profile resolves to Developer role and routes to Developer workspace | Supabase Auth/profile role is intended live integration; previous sign-in result is user-reported | Successful Developer landing state, with user identity minimized if needed | If auth/backend unavailable, stop and show a genuine previously captured screenshot only if one exists; state that live auth could not be demonstrated. Do not bypass auth or fake a response. |
| 3 | Open Developer dashboard Home | Home shows selected repository context or a clear connect/select state | Repository metadata/summary is actual GitHub-backed data when loaded; interface is implemented | Home with repository name and freshness/error state visible | If no repo is connected, connect an approved public repo if time and rate limits permit; otherwise explain that the feature requires a connection. |
| 4 | Show repository connection, repository overview, and refresh | Connect/select an authorized public repository; overview loads; refresh updates or reports throttling/error clearly | Connection, metadata, cached summary, and refresh are live backend/GitHub operations; previous connect/refresh result is user-reported | Connected repository summary and successful refresh timestamp/status; avoid capturing tokens | If GitHub rate-limits or fails, show the existing cached overview with its stale/error state. Do not claim refresh succeeded. |
| 5 | Show Developer Issues, Pull Requests, and Analytics | Views display recent activity and available aggregate signals | Recent issue/PR/commit data and selected analytics are descriptive GitHub responses; bounded and potentially incomplete | One screenshot each of Issues, Pull Requests, and Analytics | If an activity list is empty or partial, show its empty/unavailable state and explain the bounded query; do not interpret missing data as zero. |
| 6 | Show research feature previews (AI Insights and any quality/research preview) | Preview text clearly labels ML workflows as future research directions | The cards are UI previews; current operational values, if any, are descriptive repository signals only | AI Insights preview showing the research/not-operational disclaimer | If the page is unavailable, explain the feature boundary verbally using the integration report; do not substitute a mock prediction. |
| 7 | Sign out Developer | Session is cleared and login/landing state is shown | Supabase local sign-out integration | Signed-out state; do not capture account details | If sign-out stalls, do not switch users in the same authenticated session; reload only after confirming the session was cleared. |
| 8 | Sign in as Project Manager | Profile role routes to the Manager workspace | Role routing and Manager page exist in Frontend source; live sign-in is user-reported | Manager Home with role/workspace label visible | If Manager role routes incorrectly, stop before presenting pages. Explain deployment/profile mismatch; do not manually navigate around role authorization. |
| 9 | Open Manager dashboard and Projects; show repository selection | Manager Home uses active project; Projects lists connected repositories and allows selection/connection | Repository list/overview is backend data; selection is persisted per user in browser preferences; user-reported manual verification | Home and Projects with selected repository highlight | If list is empty, connect an approved public repo or explain required setup; preserve previous connections and do not invent entries. |
| 10 | Visit **Issues & Priorities** | Recent GitHub issue sample appears, with an explicit notice that AI prioritization is planned/not active | Issue titles/labels/state/timestamps are GitHub-backed where returned; priority ranking is planned | Page showing issue records and “planned, not active” notice | If issue sample is unavailable, show its empty/loading/error state. Do not assign severity or a priority score. |
| 11 | Visit **Team & Workload** | Observed authors/activity may be shown with a limitation that this is not workload/capacity or performance scoring | Activity names/events are returned repository data; workload intelligence is planned and unavailable | Page showing descriptive activity and workload caveat | If no contributor data exists, use the empty state. Do not calculate workload from commits or rank developers. |
| 12 | Visit **Project Analytics** | Available repository health, activity, and CI signals are shown with scope/freshness caveats | Repository-level GitHub signals; not project-risk predictions | Analytics page with data freshness and CI context | If signals are missing/stale, show unavailable status. Do not call detected tests passing tests or infer issue-specific CI. |
| 13 | Show **Reports** preview | Report preview summarizes available repository data and states that PDF/CSV generation is not active | Values are sourced from cached overview where present; export/generation and forecasts are planned | Report preview including no-export/planned-risk disclaimer | If no repository is selected, show the genuine empty state; do not create or present an offline mock report as generated output. |
| 14 | Sign out Project Manager | Session returns to signed-out state | Supabase local sign-out integration | Signed-out state | If session remains, do not leave the authenticated account open on a public screen; use the approved session-clear procedure. |

## Suggested narration

- “These panels show selected GitHub repository data retrieved by our authenticated backend; they are descriptive and may be bounded or stale.”
- “RQ1 evidence preparation is complete for the first evaluation, but there is no trained or live prediction model.”
- “RQ2 priority generation is planned. The Issues & Priorities screen displays issue context, not an AI ranking.”
- “Team activity does not measure individual productivity or capacity.”
- “RQ3 will provide evidence-grounded explanations after valid research outputs exist. SHAP and LLM inference are not live here, and any future cause remains subject to human review.”

## Evidence capture after the demo

Preserve genuine dated screenshots or a short recording for the major role transitions and data-backed pages. Preserve backend and Flutter command logs with branch/commit IDs and exact commands if formal validation evidence is needed. Redact personal account details and never include `.env`, tokens, session cookies, or service-role credentials. Label any screenshot from a prior run with its actual date/build; do not present it as a live test from November 13 if it was captured earlier.

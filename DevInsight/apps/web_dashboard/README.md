# web_dashboard

Flutter Web dashboard for DevInsight.

## Local authentication setup

Run the API from `DevInsight/backend` with its existing server-side `.env`.
Run the web app with the Supabase project URL and **publishable** key (never a
secret/service-role key):

```powershell
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

`API_BASE_URL` defaults to `http://127.0.0.1:8000`. Configure Supabase Auth's
site URL and redirect allow list to include the web app origin used for local
development and deployment; an optional `AUTH_REDIRECT_URL` build define can
select a specific confirmation/reset redirect.

For production, set `CORS_ALLOWED_ORIGINS` in the backend environment to a
comma-separated list of exact frontend origins. The backend separately permits
loopback (`localhost` and `127.0.0.1`) development origins on any port.

Onboarding screens are still the existing prototype UI and do not yet persist
their form data through the onboarding endpoints. The authenticated Developer
Home follows the approved analytics dashboard layout and uses the saved
authenticated profile for user identity. Developers can connect multiple
public GitHub repositories; the backend verifies the session, retrieves GitHub
data, and persists each per-user connection and cached summary in Supabase.
The Developer Home repository manager switches the active repository,
disconnects individual repositories, and remembers the active choice in
browser storage for that signed-in user. Run
`../../database/migrations/20261108_connected_repositories.sql` in the
Supabase SQL Editor before using this feature. The migration is not applied
automatically by the app.

The authenticated backend routes are `POST /api/v1/github/connections`,
`GET /api/v1/github/connections`,
`GET /api/v1/github/connections/{connection_id}/overview`, and
`POST /api/v1/github/connections/{connection_id}/refresh`,
`DELETE /api/v1/github/connections/{connection_id}`.

The dashboard displays repository metadata, recent commits/issues/pull
requests, language composition, open issue and PR totals, and closed issue
totals for the last 30 days where GitHub's search response is complete. It also
shows eight weeks of GitHub participation data when complete, repository
activity and PR-age signals, default-branch CI status, the head commit SHA, and
README/license/test-file presence. Processing or incomplete weekly statistics
are shown as unavailable rather than as zero. These are descriptive GitHub
signals: detected test files do not mean tests pass, and the dashboard does not
calculate coverage, code-quality scores, project risk, or AI predictions.
Personal assignment and productivity features remain unavailable until those
integrations are implemented. The Project Manager route remains separate.

The backend accepts an optional server-side `GITHUB_TOKEN` for API rate-limit
headroom. It is never sent to the Flutter app. `GITHUB_CACHE_MINUTES` accepts a
10-15 minute cache window and defaults to 15.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

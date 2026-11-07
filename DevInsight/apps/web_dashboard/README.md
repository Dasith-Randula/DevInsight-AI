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
authenticated profile for user identity. Repository-dependent metrics, charts,
AI insights, activity, and reminders display clear empty states until real
project data is connected. The Project Manager route remains separate.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

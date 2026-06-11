# Moradabad News

Hindi-first Flutter and Firebase news application for Moradabad, Rampur, Sambhal, Amroha, Bareilly, and nearby districts.

## What Is Included

- Flutter Material 3 mobile app
- Firebase Authentication with Google Sign-In
- Firestore-backed news feed, bookmarks, notifications, scripts, and admin records
- Firebase Cloud Messaging topic subscriptions
- Firebase Cloud Functions for hourly news fetching, OpenAI Hindi summaries, daily digest notifications, and daily AI video script generation
- NewsAPI and GNews API integration
- Weather section for Moradabad using Open-Meteo
- Admin screen for article review, duplicate deletion, notification sending, and basic counts
- Firebase rules, indexes, setup docs, APK instructions, and Play Store deployment guide

## Local Setup

Install Flutter stable, Firebase CLI, Node.js 20, and a JDK compatible with Android builds.

```powershell
flutter create . --platforms=android
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

The generated `lib/firebase_options.dart` should replace the placeholder currently in this repo.

Copy Firebase project config:

```powershell
Copy-Item .firebaserc.example .firebaserc
```

Edit `.firebaserc` with your Firebase project id.

Install Cloud Functions dependencies:

```powershell
cd functions
npm install
Copy-Item .env.example .env
```

Add API keys in `functions/.env`.

```text
OPENAI_API_KEY=...
NEWSAPI_KEY=...
GNEWS_API_KEY=...
OPENAI_MODEL=gpt-4o-mini
```

Run locally:

```powershell
flutter run
```

Deploy Firebase backend:

```powershell
firebase deploy --only firestore,functions
```

## Firebase Admin Setup

Create an admin document manually:

```text
admins/{uid}
  role: "admin"
  created_at: server timestamp
```

Only users listed in `admins` can delete news, send notifications, or manage admin-only data.

## Build APK

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

For Play Store, prefer:

```powershell
flutter build appbundle --release
```

## Important Notes

- News API keys and OpenAI keys are only used inside Cloud Functions, never in the Flutter app.
- Firestore composite indexes are included in `firestore.indexes.json`.
- FCM topics used by the app are `breaking-news`, `daily-digest`, and `weather-alerts`.
- Hourly fetching runs in `asia-south1` every 60 minutes.
- Daily digest runs at 8 AM Asia/Kolkata.

See the `docs/` folder for full setup, schema, API, and deployment details.

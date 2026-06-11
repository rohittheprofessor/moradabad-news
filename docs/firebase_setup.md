# Firebase Setup Guide

## 1. Create Project

1. Open Firebase Console.
2. Create a project named `Moradabad News`.
3. Enable Google Analytics if you want app analytics and Play Store campaign tracking.

## 2. Add Android App

Use a package name such as:

```text
com.moradabadnews.app
```

Download `google-services.json` and place it at:

```text
android/app/google-services.json
```

Run:

```powershell
flutterfire configure --project=<your-project-id>
```

## 3. Enable Authentication

Firebase Console:

```text
Authentication > Sign-in method > Google > Enable
```

For release builds, add your SHA-1 and SHA-256 certificates:

```powershell
cd android
./gradlew signingReport
```

## 4. Enable Firestore

Create Firestore in production mode, then deploy rules and indexes:

```powershell
firebase deploy --only firestore
```

## 5. Enable Cloud Messaging

Cloud Messaging works after Firebase is configured. The app subscribes users to:

```text
breaking-news
daily-digest
weather-alerts
```

## 6. Configure Cloud Functions Secrets

For production, use Firebase secrets instead of plain `.env`:

```powershell
firebase functions:secrets:set OPENAI_API_KEY
firebase functions:secrets:set NEWSAPI_KEY
firebase functions:secrets:set GNEWS_API_KEY
```

The current functions also read `.env` for local development.

## 7. Deploy Functions

```powershell
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions
```

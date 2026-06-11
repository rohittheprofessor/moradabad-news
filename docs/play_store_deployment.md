# Google Play Store Deployment Guide

## 1. Prepare App Identity

Set package name during Android project creation:

```text
com.moradabadnews.app
```

Update app label in Android resources after running `flutter create .`.

## 2. Configure Signing

Create an upload keystore:

```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=../upload-keystore.jks
```

Configure signing in `android/app/build.gradle` using Flutter's official release signing instructions.

## 3. Build App Bundle

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

Upload:

```text
build/app/outputs/bundle/release/app-release.aab
```

## 4. Play Console Checklist

- App name: Moradabad News
- Default language: Hindi
- Category: News & Magazines
- Privacy policy URL
- Data safety form for Firebase Auth, Firestore, Cloud Messaging, and analytics
- Content rating questionnaire
- Screenshots for phone form factor
- Production release notes in Hindi and English

## 5. Production Validation

Before rollout:

```powershell
flutter test
flutter analyze
firebase deploy --only firestore,functions
```

Verify:

```text
Google login works on release SHA keys
Firestore rules block non-admin writes
Hourly news function writes articles
OpenAI summaries are Hindi
FCM test notification reaches device
Bookmarks persist across app restarts
```

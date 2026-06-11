# Push Notification Implementation

## Topics

The app subscribes every user to:

```text
breaking-news
daily-digest
weather-alerts
```

Code:

```text
lib/features/notifications/data/notification_service.dart
```

## Scheduled Digest

Cloud Function:

```text
sendDailyDigest
```

Schedule:

```text
8:00 AM every day, Asia/Kolkata
```

## Admin Notifications

Callable Function:

```text
sendBreakingNotification
```

Only users with `admins/{uid}` can call it.

## Weather Alerts

The app already subscribes to `weather-alerts`. To send automated weather alerts, add another scheduled function that checks weather data and sends to this topic when thresholds are crossed.

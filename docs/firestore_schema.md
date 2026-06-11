# Firestore Schema

## `users/{uid}`

```json
{
  "uid": "firebase-auth-uid",
  "name": "User name",
  "email": "user@example.com",
  "photo_url": "https://...",
  "bookmarks": ["articleId"],
  "updated_at": "serverTimestamp"
}
```

## `news/{articleId}`

```json
{
  "id": "sha256-url-id",
  "title": "Headline",
  "image": "https://...",
  "source": "GNews",
  "category": "Local",
  "city": "Moradabad",
  "summary": "2-line Hindi summary",
  "summary_50_words": "50-word Hindi summary",
  "voice_script": "1-minute Hindi voice news script",
  "article_url": "https://...",
  "published_at": "timestamp",
  "is_breaking": false,
  "created_at": "serverTimestamp"
}
```

Supported categories:

```text
Local, Crime, Education, Politics, Sports, Weather, Jobs
```

## `notifications/{notificationId}`

```json
{
  "title": "Notification title",
  "message": "Notification body",
  "topic": "breaking-news",
  "timestamp": "serverTimestamp"
}
```

## `daily_video_scripts/{yyyy-mm-dd}`

```json
{
  "id": "2026-06-03",
  "script": "Hindi video script",
  "article_ids": ["articleId"],
  "created_at": "serverTimestamp"
}
```

## `admins/{uid}`

```json
{
  "role": "admin",
  "created_at": "serverTimestamp"
}
```

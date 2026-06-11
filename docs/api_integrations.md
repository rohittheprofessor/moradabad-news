# API Integration Notes

## News Sources

Cloud Function:

```text
fetchNewsHourly
```

Schedule:

```text
every 60 minutes, Asia/Kolkata
```

Search keywords:

```text
Moradabad, मुरादाबाद, Rampur, रामपुर, Sambhal, संभल, Amroha, अमरोहा, Bareilly, बरेली
```

Sources:

```text
NewsAPI everything endpoint
GNews search endpoint
```

The function deduplicates by article URL hash before writing to Firestore.

## OpenAI Summarization

Each article is converted into:

```text
summary            2-line Hindi summary
summary_50_words   50-word Hindi summary
voice_script       1-minute Hindi voice-news script
```

The model is configured by:

```text
OPENAI_MODEL=gpt-4o-mini
```

## Daily AI News Video Endpoint

HTTP function:

```text
generateDailyVideoScript
```

Behavior:

```text
Reads latest 10 articles
Generates a 3-4 minute Hindi video script
Stores it in daily_video_scripts/{yyyy-mm-dd}
Returns JSON with id and script
```

This endpoint is intentionally script-only so a future video rendering service can consume the Firestore document.

## Weather

The Flutter app reads current Moradabad weather from Open-Meteo:

```text
temperature
humidity
daily high
daily low
```

No weather API key is required for the current implementation.

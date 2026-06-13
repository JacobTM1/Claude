# Resonance Backend — Journey of Souls conversational guide

A small Node/TypeScript service that powers the **interactive** Journey of Souls
experience. It holds the API keys (never shipped in the app) and exposes two
endpoints to the iOS app:

- `POST /journey/turn` — the conversational hypnotherapist. Given the session
  state and whatever the user just said aloud, it returns the next few spoken
  lines (with pauses), the current phase, whether to listen for a reply, and
  whether the session is complete. Powered by **Claude Opus 4.8**
  (`claude-opus-4-8`) with a hard safety system prompt and JSON structured
  output.
- `POST /tts` — turns a line of text into a warm, human-sounding voice via a
  premium TTS provider (ElevenLabs by default) and streams back the audio.

The app does speech-to-text on-device (Apple's Speech framework) and sends only
the transcript here, so no audio ever leaves the phone except the synthesized
guide voice coming back.

## Why a backend at all

API keys for Claude and the voice provider **cannot** live in a shipped app —
they would be extracted and abused within hours. This service is the vault: the
app authenticates to it with a shared secret, and the real keys stay here.

## Endpoints

### `POST /journey/turn`
Header: `x-app-secret: <APP_SHARED_SECRET>`
Body:
```json
{
  "theme": "A Journey Inward",
  "minutes": 20,
  "history": [{ "role": "assistant", "text": "..." }, { "role": "user", "text": "I feel calm" }],
  "userSpeech": "I think I see a doorway"
}
```
Returns:
```json
{
  "speech": [{ "text": "Good. Let yourself drift toward it.", "pauseMsAfter": 7000 }],
  "phase": "journey",
  "awaitingResponse": true,
  "sessionComplete": false
}
```

### `POST /tts`
Header: `x-app-secret: <APP_SHARED_SECRET>`
Body: `{ "text": "Breathe in, slowly." }`
Returns: `audio/mpeg` bytes.

## Configuration (environment variables)

| Var | Required | Notes |
|---|---|---|
| `ANTHROPIC_API_KEY` | yes | Your Claude API key (console.anthropic.com) |
| `ELEVENLABS_API_KEY` | for real voice | ElevenLabs key; omit to disable `/tts` |
| `ELEVENLABS_VOICE_ID` | no | Defaults to a calm preset; override with your chosen voice |
| `APP_SHARED_SECRET` | yes | A long random string; the app must send it |
| `PORT` | no | Defaults to 8080 |

## Run locally

```bash
cd backend
npm install
cp .env.example .env   # then fill in the keys
npm run dev
```

## Deploy (Render, one click-ish)

This folder includes `render.yaml`. Push the repo, create a new Render Web
Service from it, set the environment variables above in the Render dashboard,
and Render builds and hosts it at a public HTTPS URL. That URL is what the iOS
app will call. A `Dockerfile` is also included for any other host (Railway,
Fly.io, your own server).

import express, { type Request, type Response, type NextFunction } from "express";
import Anthropic from "@anthropic-ai/sdk";

const PORT = Number(process.env.PORT ?? 8080);
const APP_SHARED_SECRET = process.env.APP_SHARED_SECRET ?? "";
const ELEVENLABS_API_KEY = process.env.ELEVENLABS_API_KEY ?? "";
// Defaults to the voice you selected; override with ELEVENLABS_VOICE_ID to swap.
const ELEVENLABS_VOICE_ID = process.env.ELEVENLABS_VOICE_ID ?? "VU16byTywsWv5JpI8rbc";

const anthropic = new Anthropic(); // reads ANTHROPIC_API_KEY from the environment

const app = express();
app.use(express.json({ limit: "1mb" }));

// --- Shared-secret gate so random callers can't run up the bill ---------------
function requireSecret(req: Request, res: Response, next: NextFunction) {
  if (!APP_SHARED_SECRET) {
    return res.status(500).json({ error: "server missing APP_SHARED_SECRET" });
  }
  if (req.get("x-app-secret") !== APP_SHARED_SECRET) {
    return res.status(401).json({ error: "unauthorized" });
  }
  next();
}

app.get("/", (_req, res) => res.json({ ok: true, service: "resonance-backend" }));

// --- Temporary diagnostics: open in a browser to see why voice may fail -------
// Reports which keys are set (booleans only — never the values) and runs one
// tiny ElevenLabs test so we can read the exact status/error.
app.get("/diag", async (_req, res) => {
  const result: Record<string, unknown> = {
    anthropicKeySet: !!process.env.ANTHROPIC_API_KEY,
    elevenKeySet: !!ELEVENLABS_API_KEY,
    sharedSecretSet: !!APP_SHARED_SECRET,
    voiceId: ELEVENLABS_VOICE_ID,
  };
  if (ELEVENLABS_API_KEY) {
    try {
      const r = await fetch(
        `https://api.elevenlabs.io/v1/text-to-speech/${ELEVENLABS_VOICE_ID}`,
        {
          method: "POST",
          headers: {
            "xi-api-key": ELEVENLABS_API_KEY,
            "content-type": "application/json",
            accept: "audio/mpeg",
          },
          body: JSON.stringify({ text: "test", model_id: "eleven_multilingual_v2" }),
        },
      );
      const tts: Record<string, unknown> = {
        status: r.status,
        contentType: r.headers.get("content-type") ?? "",
      };
      if (r.ok) {
        tts.audioBytes = (await r.arrayBuffer()).byteLength;
      } else {
        tts.body = (await r.text()).slice(0, 500);
      }
      result.tts = tts;
    } catch (e) {
      result.tts = { error: String(e).slice(0, 300) };
    }
  } else {
    result.tts = { skipped: "ELEVENLABS_API_KEY not set" };
  }
  res.json(result);
});

// --- The conversational guide --------------------------------------------------

/// Hard rules + a real hypnotherapy structure. Framing, wellbeing, and the
/// always-ground-before-ending guarantee are enforced here. `language` makes
/// the guide speak entirely in the chosen language.
function buildSystemPrompt(language: string): string {
  return `
You are the voice of "Journey of Souls", a calm, guided inner-visualization
experience inspired by Michael Newton's between-lives hypnotherapy. You speak
as a warm, skilled hypnotherapist guiding ONE person who has their eyes closed,
listening through headphones. Speak entirely in ${language}.

HARD RULES — never violate:
- This is contemplative inner imagery and reflection ONLY. Never claim the
  person is retrieving a real past life, a literal soul record, or a factual
  afterlife. Frame everything as imagination: "imagine", "you may sense",
  "notice what arises — or notice nothing; both are fine". Never assert that
  what they experience is literally true.
- Never give medical, psychological, or diagnostic advice. Not therapy. If they
  describe real crisis or self-harm, begin RETURN and, in reflection, suggest a
  qualified professional or emergency services.
- Safety overrides everything. If they say "bring me back", "stop", "I want to
  come back", or sound distressed, immediately move to RETURN and guide them
  fully and gently back. Never leave someone deep.

THIS IS HYPNOTHERAPY, NOT NARRATION. Your job is to actually induce a relaxed,
absorbed, trance-like state BEFORE any journey imagery — then guide and ask,
responding to what they say.

ARC AND TIME BUDGET (you have about {{MINUTES}} minutes total — pace to fit):
1. intro (brief): settle the body, eyes closed, permission to let go.
2. induction (spend real time): progressive relaxation head to toe — scalp,
   face, jaw, shoulders, arms, chest, belly, legs, feet. Slow breathing.
   Suggestions of heaviness, warmth, sinking, drifting. This is where depth
   begins; do not rush it.
3. deepening (spend real time): a slow deepening — count down from ten to one,
   or descend an imagined staircase/elevator, each step "twice as deep, twice
   as calm". Reinforce that they are safe, and going deeper.
4. journey: ONLY once they are deeply relaxed, open the chosen theme's imagery.
5. interlife / the meeting: the heart of it. When a soul, guide, scene, or
   figure may be present, ASK vivid, specific, open questions and then LISTEN
   (set awaitingResponse true): "What do you notice first?" "What do they look
   like?" "How do you feel as you look at them?" "Is there something they want
   you to know?" Build the next moment FROM their answer.
6. integration: let what arose settle.
7. returning: ALWAYS run before ending — count up, return to the body and the
   room, become awake and present. Never skip.
8. reflection: a few grounding words once they are back.

CRAFT RULES:
- Never repeat a line or idea you've already said. Always move the session
  FORWARD. If they were silent, reassure briefly and continue — do not re-ask
  the same thing.
- Reach the deep journey and return them within the time. Budget roughly: a
  third for induction+deepening, the middle for the journey+meeting, and always
  reserve the last ~2 minutes for returning.
- PACING: keep it flowing. Use SHORT pauses — pauseMsAfter mostly 1500–4500 ms;
  only reach 6000–7000 ms at the very deepest, most spacious moments. Long dead
  air feels generic; gentle momentum feels guided.
- 1–4 short lines per turn. Warm, simple, present-tense, unhurried but moving.

CHECKPOINTS: ask one open question and set awaitingResponse true when you want
their spoken reply (especially in the meeting). Otherwise keep guiding with
awaitingResponse false. Respond naturally to whatever they say.

COMPLETION: set sessionComplete true ONLY on the final reflection line, and ONLY
after returning has run. Never while still deep.

Return ONLY the structured object the schema defines.
`.trim();
}

const RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    speech: {
      type: "array",
      items: {
        type: "object",
        properties: {
          text: { type: "string" },
          pauseMsAfter: { type: "integer" },
        },
        required: ["text", "pauseMsAfter"],
        additionalProperties: false,
      },
    },
    phase: {
      type: "string",
      enum: [
        "intro", "induction", "deepening", "journey",
        "interlife", "integration", "returning", "reflection",
      ],
    },
    awaitingResponse: { type: "boolean" },
    sessionComplete: { type: "boolean" },
  },
  required: ["speech", "phase", "awaitingResponse", "sessionComplete"],
  additionalProperties: false,
} as const;

interface TurnBody {
  theme?: string;
  minutes?: number;
  history?: { role: "user" | "assistant"; text: string }[];
  userSpeech?: string;
  language?: string;
  goal?: string;
}

app.post("/journey/turn", requireSecret, async (req: Request, res: Response) => {
  const body = req.body as TurnBody;
  const theme = (body.theme ?? "A Journey Inward").slice(0, 120);
  const minutes = Math.min(Math.max(Number(body.minutes ?? 20), 5), 30);
  const language = (body.language ?? "English").slice(0, 40);
  const goal = (body.goal ?? "").slice(0, 400);
  const history = Array.isArray(body.history) ? body.history.slice(-40) : [];

  // Build the conversation. The opening user turn frames the session; each
  // subsequent user turn carries what the person said aloud (or a marker that
  // they were silent / the guide should simply continue).
  const messages: Anthropic.MessageParam[] = [];
  if (history.length === 0) {
    messages.push({
      role: "user",
      content:
        `Begin a Journey of Souls session. Theme/intention: "${theme}". ` +
        `Target length: about ${minutes} minutes. ` +
        (goal ? `What this person is seeking: "${goal}". Gently let this shape the journey. ` : "") +
        `Start with the intro phase, then take real time in induction and deepening before any journey imagery.`,
    });
  } else {
    for (const h of history) {
      messages.push({ role: h.role, content: h.text });
    }
    messages.push({
      role: "user",
      content: body.userSpeech?.trim()
        ? `The person said softly: "${body.userSpeech.trim().slice(0, 600)}"`
        : `The person was quiet. Reassure them gently that silence is fine and continue guiding.`,
    });
  }

  try {
    // Params are built as a plain object and passed through the official SDK.
    // `output_config` (structured outputs + effort) is newer than some SDK
    // type definitions, so we keep the params loosely typed to stay compatible
    // across SDK versions; the SDK still sends them in the request body.
    const params = {
      model: "claude-opus-4-8",
      max_tokens: 1200,
      system: buildSystemPrompt(language).replace("{{MINUTES}}", String(minutes)),
      output_config: {
        effort: "low", // a guide reply is short; keep latency down
        format: { type: "json_schema", schema: RESPONSE_SCHEMA },
      },
      messages,
    };
    const response = (await anthropic.messages.create(params as never)) as Anthropic.Message;

    if (response.stop_reason === "refusal") {
      // Safety classifier declined. Fail safe: send the user gently back.
      return res.json(groundingFallback());
    }

    const textBlock = response.content.find((b) => b.type === "text");
    if (!textBlock || textBlock.type !== "text") {
      return res.json(groundingFallback());
    }
    return res.json(JSON.parse(textBlock.text));
  } catch (err) {
    console.error("journey/turn error:", err);
    // Never strand the listener — return a gentle grounding step on any error.
    return res.json(groundingFallback());
  }
});

/// A safe, self-contained RETURN step used whenever the model is unavailable or
/// declines — so a session can always bring the listener back.
function groundingFallback() {
  return {
    speech: [
      { text: "Let's gently begin to come back now.", pauseMsAfter: 5000 },
      { text: "Feel the surface beneath you, and the weight of your body resting on it.", pauseMsAfter: 5000 },
      { text: "Take a fuller breath, and when you're ready, let your eyes open. Welcome back.", pauseMsAfter: 4000 },
    ],
    phase: "returning",
    awaitingResponse: false,
    sessionComplete: true,
  };
}

// --- Voice (text-to-speech) proxy ----------------------------------------------

app.post("/tts", requireSecret, async (req: Request, res: Response) => {
  const text = String((req.body as { text?: string }).text ?? "").slice(0, 1200);
  if (!text.trim()) return res.status(400).json({ error: "text required" });
  if (!ELEVENLABS_API_KEY) {
    return res.status(503).json({ error: "tts not configured (set ELEVENLABS_API_KEY)" });
  }

  try {
    const upstream = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${ELEVENLABS_VOICE_ID}`,
      {
        method: "POST",
        headers: {
          "xi-api-key": ELEVENLABS_API_KEY,
          "content-type": "application/json",
          accept: "audio/mpeg",
        },
        body: JSON.stringify({
          text,
          model_id: "eleven_multilingual_v2",
          // Calm, steady delivery: high stability, gentle style.
          voice_settings: { stability: 0.7, similarity_boost: 0.75, style: 0.0 },
        }),
      },
    );

    if (!upstream.ok || !upstream.body) {
      const detail = await upstream.text().catch(() => "");
      console.error("tts upstream error:", upstream.status, detail);
      return res.status(502).json({ error: "tts upstream failed" });
    }

    res.setHeader("content-type", "audio/mpeg");
    // Stream the audio straight through to the app.
    const reader = upstream.body.getReader();
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      res.write(Buffer.from(value));
    }
    res.end();
  } catch (err) {
    console.error("tts error:", err);
    res.status(502).json({ error: "tts failed" });
  }
});

app.listen(PORT, () => {
  console.log(`resonance-backend listening on :${PORT}`);
});

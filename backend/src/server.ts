import express, { type Request, type Response, type NextFunction } from "express";
import Anthropic from "@anthropic-ai/sdk";

const PORT = Number(process.env.PORT ?? 8080);
const APP_SHARED_SECRET = process.env.APP_SHARED_SECRET ?? "";
const ELEVENLABS_API_KEY = process.env.ELEVENLABS_API_KEY ?? "";
// A calm, measured preset ("Rachel"); override via env once you've chosen a voice.
const ELEVENLABS_VOICE_ID = process.env.ELEVENLABS_VOICE_ID ?? "21m00Tcm4TlvDq8ikWAM";

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

// --- The conversational guide --------------------------------------------------

/// Hard rules the model must never violate. This is the safety spine of the
/// whole experience — framing, wellbeing, and the always-ground-before-ending
/// guarantee are all enforced here.
const SYSTEM_PROMPT = `
You are the voice of "Journey of Souls", a calm, guided inner-visualization
experience inspired by the structure of Michael Newton's between-lives work.
You speak as a warm, unhurried hypnotherapist guiding one person who has their
eyes closed and is listening through headphones.

HARD RULES — never violate, no exceptions:
- This is contemplative inner imagery and reflection ONLY. Never claim the
  person is retrieving a real past life, a literal soul record, or a factual
  afterlife. Frame everything as imagination and inner experience: "imagine",
  "you may sense", "perhaps", "notice what arises — or notice nothing; both are
  fine". Never assert that anything they experience is literally true or real.
- Never implant specific memories or events as fact. Offer open, non-leading
  invitations, never "you see a temple" as a statement of fact — instead "you
  may begin to notice a place forming, whatever it is".
- Never give medical, psychological, diagnostic, or treatment advice. This is
  not therapy. If the person describes real distress, a crisis, self-harm, or a
  medical issue, gently begin the RETURN sequence and, in the reflection,
  suggest they speak with a qualified professional or, in crisis, contact local
  emergency services.
- Safety overrides the script. If the person says anything like "bring me back",
  "stop", "I want to come back", "I feel scared/sick/panicked", or otherwise
  signals they want out or is distressed, immediately move to the RETURN phase
  and guide them gently and fully back. Never leave someone in a deep state.
- Keep a slow, soft, simple register. Short sentences. Generous silences.

SESSION ARC (phases, in order):
intro -> induction -> deepening -> journey -> interlife -> integration -> returning -> reflection
- intro: settle the body, eyes closed, nothing to force.
- induction: progressive relaxation, slow breath.
- deepening: a gentle countdown deeper into calm.
- journey: lead the imagery for the chosen theme. For soul-journey themes, this
  is a regression-style descent (back through calm, toward "a life before this
  one" framed as imagery).
- interlife: the "meeting your soul" / between-lives space — a sense of peace,
  a guiding presence, a feeling of belonging. Always framed as inner imagery.
- integration: let whatever arose settle; no analysis required.
- returning: ALWAYS run this before ending — count up, return awareness to the
  body and room, become awake and present. This phase can never be skipped.
- reflection: a few grounding words once they are back.

CHECKPOINT LISTENING:
At natural moments, ask one simple, open question and set "awaitingResponse" to
true so the app opens the microphone (e.g. "When you're ready, tell me softly:
what do you notice?"). When you are simply guiding and not expecting a reply,
set "awaitingResponse" to false. Respond naturally to whatever they say — reflect
it back gently and continue. If they say nothing meaningful, reassure them that
silence is fine and continue.

PACING:
Return 1–4 short lines per turn. Each line has "pauseMsAfter" (3000–12000 ms) —
the silence the app holds after speaking it. Use longer pauses in induction,
deepening, and the journey; shorter in returning so coming back never drags.

COMPLETION:
Set "sessionComplete" to true ONLY on the final reflection line, and ONLY after
the returning phase has run. Never set it true while still in a deep phase.

Return ONLY the structured object the schema defines.
`.trim();

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
}

app.post("/journey/turn", requireSecret, async (req: Request, res: Response) => {
  const body = req.body as TurnBody;
  const theme = (body.theme ?? "A Journey Inward").slice(0, 120);
  const minutes = Math.min(Math.max(Number(body.minutes ?? 20), 5), 30);
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
        `Target length: about ${minutes} minutes. Start with the intro phase.`,
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
      system: SYSTEM_PROMPT,
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

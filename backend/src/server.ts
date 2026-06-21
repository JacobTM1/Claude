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
experience inspired by Michael Newton's between-lives hypnotherapy. You are a
warm, skilled hypnotherapist guiding ONE person who is lying down, eyes closed,
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

═══════════════════════════════════════════════════════════════════════════
THE ONE THING THAT MATTERS MOST: you DRAW the journey OUT of them. You do NOT
narrate a pre-written scene. This is what makes it real instead of generic.

Michael Newton's actual method is a CONVERSATION. The therapist asks short,
specific, sensory questions and then goes quiet and listens. The subject
reports what they perceive. The therapist takes the subject's OWN words and
deepens into exactly that — never overriding it with invented scenery.

So from the moment the journey opens, you are mostly ASKING, not telling:
  "What do you become aware of first?"
  "Look down — what's on your feet?"
  "Someone is here with you. What do they look like?"
  "What are they wearing?"  "Are they young, or old?"
  "How do you feel as you stand near them?"
  "Is there something they want you to understand?"
And then you SET awaitingResponse=true and STOP. When they answer, your very
next lines must echo or paraphrase THEIR actual words and build the next moment
from exactly what they described. If they said "a warm light and an old man",
you say "Yes... that warm light. Let your eyes rest on the old man. Notice his
face now — what do you see in his eyes?" You never replace their image with one
of your own.
═══════════════════════════════════════════════════════════════════════════

THE ARC (you have about {{MINUTES}} minutes — pacing context is given to you
each turn; trust it):
1. intro (brief, ~30–60s): settle, eyes closed, permission to let everything go.
2. induction (REAL hypnotic induction, the largest early block): progressive
   relaxation head to toe — scalp, brow, jaw, throat, shoulders, arms, hands,
   chest, belly, hips, legs, feet. Tie relaxation to the OUT-breath ("with each
   breath out, twice as heavy"). Use convincers/ratifications: "your hands may
   feel pleasantly heavy now", "your eyelids so relaxed they don't want to
   open". This is where trance actually forms — do not rush it. Occasionally ask
   for a tiny signal ("when that warmth reaches your feet, you might let out one
   slow breath") to involve them.
3. deepening: count DOWN slowly from ten to one, OR descend a staircase/elevator
   into soft light, each step "twice as deep, twice as calm, completely safe".
   Use fractionation if you like ("drifting down... and down").
4. journey: ONLY once they are deeply relaxed, open the chosen theme's doorway —
   then immediately begin DRAWING IT OUT (ask, don't narrate).
5. interlife / the meeting: the heart. A soul, guide, or figure may be present.
   This whole phase is question → listen → deepen into their answer, repeatedly.
6. integration: let what arose settle; one quiet reflective question is fine.
7. returning: ALWAYS run before ending — count UP, restore weight and warmth to
   the body, the room around them, awake, clear, present. Never skip.
8. reflection: a few grounding words once they are fully back.

CRAFT RULES:
- ASK OFTEN. From the journey phase onward, MOST turns should end in one open,
  specific, sensory question with awaitingResponse=true. A turn that just
  narrates scenery at them in the journey is a failure.
- ONE question at a time. Keep questions short and concrete (look, listen, feel,
  who, what, where) — never abstract or analytical.
- BUILD ON THEIR WORDS. After any answer, reference what they actually said.
  Never contradict or overwrite their imagery. If they go somewhere unexpected,
  follow THEM.
- NEVER REPEAT a line, image, or question you've already used. Always move
  FORWARD. If they were silent, reassure in one short breath ("that's perfectly
  fine — whatever comes, or doesn't, is right") and gently offer a softer,
  different doorway in — do not re-ask the identical question.
- PACING by the clock context you're given: if you're behind, get them deep and
  into the meeting sooner; if time is short, begin RETURN now. Always reserve
  the last ~2 minutes for returning. Never get caught deep at time's end.
- PAUSES: pauseMsAfter mostly 1800–4500 ms; reach 6000–7000 ms only at the
  deepest, most spacious moments, and right after you ask a question so they
  have room to perceive before answering. Avoid long dead air elsewhere.
- 1–3 short lines per turn during the journey (so you ask and listen often);
  induction/deepening turns may run a little longer.
- Voice: warm, slow, present-tense, intimate. Second person. No lists, no meta.

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
  elapsedSeconds?: number;
}

/// A short, concrete pacing line so the guide actually knows where it is in the
/// session and which phase it should be moving toward. Uses real elapsed time
/// when the app reports it; otherwise falls back to estimating from turn count.
function pacingContext(minutes: number, elapsedSeconds: number | undefined,
                       assistantTurns: number): string {
  const total = minutes * 60;
  const elapsed = typeof elapsedSeconds === "number" && elapsedSeconds >= 0
    ? Math.min(elapsedSeconds, total)
    // ~75s of speech+pause per assistant turn is a rough but useful proxy.
    : Math.min(assistantTurns * 75, total);
  const remaining = Math.max(total - elapsed, 0);
  const mins = (s: number) => Math.round(s / 60);
  const frac = elapsed / total;

  let cue: string;
  if (remaining <= 150) {
    cue = "Time is almost up — if you have not already, begin RETURN now and bring them fully back.";
  } else if (frac < 0.18) {
    cue = "Early: settle them and do a real progressive-relaxation induction.";
  } else if (frac < 0.38) {
    cue = "Deepen now — countdown or descent — they should be going truly deep.";
  } else if (frac < 0.78) {
    cue = "They should be deep: open the journey and DRAW IT OUT — ask, listen, build on their words.";
  } else {
    cue = "Begin moving toward integration, then RETURN within the next couple of minutes.";
  }
  return `Pacing: about ${mins(elapsed)} min elapsed of ${minutes}, ~${mins(remaining)} min left. ${cue}`;
}

app.post("/journey/turn", requireSecret, async (req: Request, res: Response) => {
  const body = req.body as TurnBody;
  const theme = (body.theme ?? "A Journey Inward").slice(0, 120);
  const minutes = Math.min(Math.max(Number(body.minutes ?? 20), 5), 30);
  const language = (body.language ?? "English").slice(0, 40);
  const goal = (body.goal ?? "").slice(0, 400);
  const history = Array.isArray(body.history) ? body.history.slice(-40) : [];
  const assistantTurns = history.filter((h) => h.role === "assistant").length;
  const pacing = pacingContext(minutes, body.elapsedSeconds, assistantTurns);

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
        `Start with the intro phase, then take real time in induction and deepening before any journey imagery. (${pacing})`,
    });
  } else {
    for (const h of history) {
      messages.push({ role: h.role, content: h.text });
    }
    messages.push({
      role: "user",
      content:
        (body.userSpeech?.trim()
          ? `The person said softly: "${body.userSpeech.trim().slice(0, 600)}". ` +
            `Echo their own words and deepen into exactly what they described — do not introduce your own scenery. `
          : `The person was quiet. Reassure them in one short breath that silence is fine, then gently offer a different, softer way in — do not re-ask the same question. `) +
        `(${pacing})`,
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
        // Medium effort: the adaptive journey/meeting lines need to be vivid and
        // genuinely responsive to what the person said, which "low" flattened.
        effort: "medium",
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

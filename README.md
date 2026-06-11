# Resonance 🎧

A beautifully minimal iPhone meditation app that pairs **real-time generated frequency sounds** (binaural beats and solfeggio tones) with **animated, research-backed breathing guidance**.

Built with SwiftUI. No audio files — every tone is synthesized live with `AVAudioEngine`, so the binaural separation is sample-accurate.

## The six sessions

| Session | Tone | Why this frequency | Breathing pattern |
|---|---|---|---|
| **Deep Meditation** | Theta · 6 Hz binaural (200 / 206 Hz) | Theta (4–8 Hz) dominates EEG in deep meditative absorption | Extended Exhale · in 4, hold 2, out 8 |
| **Focus & Clarity** | Gamma · 40 Hz binaural (240 / 280 Hz) | 40 Hz gamma is linked to attention and working memory, and actively studied (incl. MIT) | Box Breathing · 4-4-4-4 |
| **Calm & De-stress** | Alpha · 10 Hz binaural (220 / 230 Hz) | Alpha (8–12 Hz) marks relaxed wakeful calm | Coherent Breathing · 5.5 in / 5.5 out |
| **Deep Sleep** | Delta · 2.5 Hz binaural (150 / 152.5 Hz) | Delta (0.5–4 Hz) defines slow-wave sleep | 4-7-8 Breathing (Dr. Weil) |
| **Anxiety Release** | Alpha–theta · 8 Hz binaural (210 / 218 Hz) | The calm border between alpha and theta | Physiological Sigh · two inhales + long exhale |
| **Healing Tone** | 528 Hz pure solfeggio tone | The classic solfeggio tradition (presented honestly as tradition) | Ocean Breath · in 4, out 6 |

Each session includes step-by-step "how to practice" guidance, a selectable duration (5–30 min), a glowing breathing circle with haptic phase cues, a volume fader, and a gentle 2-second fade on every start, pause and finish.

## Where the science is honest

- **Strongest evidence — the breathing.** Slow breathing at ~5.5 breaths/min measurably raises heart-rate variability; the physiological sigh outperformed mindfulness meditation in a 2023 Stanford RCT (Balban et al., *Cell Reports Medicine*).
- **Promising but mixed — binaural beats.** A 2019 meta-analysis (Garcia-Argibay et al.) found effects on anxiety, attention and memory; individual results vary. Headphones are required — the beat exists only when each ear hears a different tone.
- **Tradition, not treatment — solfeggio.** 528 Hz is included because a warm steady tone is a lovely meditation anchor, and the app says exactly that in its Science screen.

## Running the app

1. Open `Resonance.xcodeproj` in **Xcode 16 or newer**.
2. Select your iPhone or any iOS 17+ simulator.
3. Set your development team under *Signing & Capabilities* (only needed for a physical device).
4. Build and run (⌘R). Use headphones for the binaural sessions.

## Project structure

```
Resonance/
├── ResonanceApp.swift          App entry point
├── Theme.swift                 Shared backgrounds & card styling
├── Models/
│   ├── MeditationMode.swift    The six presets: frequencies, guidance, science notes
│   └── BreathingPattern.swift  Six breathing techniques as timed phase sequences
├── Audio/
│   └── ToneEngine.swift        Real-time stereo sine synthesis (AVAudioEngine)
└── Views/
    ├── HomeView.swift          Mode gallery
    ├── SessionView.swift       Intro → live session → completion flow
    ├── BreathingGuideView.swift Animated breathing circle with haptics
    └── ScienceView.swift       Honest evidence explainer
```

## Disclaimer

Resonance is a relaxation aid, not a medical device. If you have epilepsy or a seizure history, consult a doctor before using rhythmic audio stimulation. Don't use entrainment audio while driving.

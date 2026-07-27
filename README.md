# Agents Chat Room

> A Flutter app where you orchestrate multiple AI agents from different providers in a shared chat thread — debate, brainstorm, collaborate — with full visibility and steering controls.

**[Read the full blueprint →](./BLUEPRINT.md)**

---

## What it does

Create a **Room** with a topic and 1–4 **Agents** (each = a configured AI from a specific provider/model with its own API key + system prompt). Then:

- **Single mode** — send a prompt → all Roster Agents reply once → transcript freezes.
- **Debate mode** — Agents reply in rounds, each sees prior rounds, loop continues until timer expires, you take a turn, or the round cap is hit.

You're the **Orchestrator**. You steer mid-debate, set timers, pause everything with one tap, and return later to a fully persisted transcript.

---

## Why

Existing chat UIs are 1:1 (you + one AI). Real work happens in **multi-perspective** discussion — debate, critique, brainstorm. This app makes that first-class.

---

## Status

**v0.1 — pre-implementation.** Blueprint locked. Implementation starts once the scaffold lands.

See [BLUEPRINT.md](./BLUEPRINT.md) for:
- Architecture (fully on-device, Flutter + Drift + Riverpod)
- Domain terms (Orchestrator / Agent / Room / Roster / Round / Take Turn)
- MVP scope (in / out)
- Failure modes & guards (retry budget, stall detection, timer, crash-resume)
- Verification tests (6 must-pass cases on real device)

---

## Stack

| Layer | Choice |
|---|---|
| Language | Dart |
| Framework | Flutter |
| State | Riverpod |
| Persistence | Drift (SQLite) |
| Key storage | `flutter_secure_storage` |
| HTTP | `dio` |
| Domain models | `freezed` + `json_serializable` |

---

## Roadmap (v0.2+)

- Streaming tokens per provider
- Token / cost dashboard
- Agent @-mentions
- Private channels (Orchestrator whispers)
- Export / import Room (markdown / JSON)
- Image input for vision-capable models
- Voice output (TTS per Agent)
- "Fork from round N"

---

## License

Private — © 2026 Ye-Shwethway.
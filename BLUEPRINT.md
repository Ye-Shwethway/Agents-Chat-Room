# Agent Chatroom — Blueprint

**Status**: Pre-build alignment complete (2026-07-27 17:22 UTC)
**Stack**: Flutter + Dart
**Architecture**: Fully on-device (Shape A)
**Persistence**: Drift (SQLite)

---

## 1. Outcome

A Flutter app where the Orchestrator (human) creates **Rooms** with a topic and a Roster of 1–4 **Agents** (each Agent = a configured AI from a specific provider/model with its own API key + system prompt). Two run modes:

- **Single** — Orchestrator sends a prompt → all Roster Agents reply once → transcript freezes.
- **Debate** — Agents reply in rounds, each round all see prior messages, loop continues until timer expires, Orchestrator takes a turn, or round cap is hit. Orchestrator can interrupt at any point.

Agents autonomously debate a topic while Orchestrator is away, with the entire transcript persisted, scrollable, and resumeable.

---

## 2. Domain Terms (Canonical)

| Term | Definition |
|---|---|
| **Orchestrator** | The human (you). Holds all API keys. Creates/edits/deletes Rooms and Agents. Steers mid-debate. |
| **Agent** | A configured AI: provider + model + system prompt + API key + display name. Each Agent is bound to one provider's API. |
| **Room** | A persistent chat session — topic + Roster + ordered transcript + run mode + timer config. |
| **Roster** | The set of Agents assigned to a Room (1–4). |
| **Round** | One turn-batch in Debate mode: each Roster Agent produces one message in sequence (parallelized where safe, but coherent ordering). |
| **Take Turn** | Orchestrator action — interrupts the loop, injects Orchestrator's typed message as the next round. |

---

## 3. Architecture (Shape A — Fully On-Device)

```
┌────────────────────────────────────────────────────┐
│              Flutter App (Mobile)                   │
├────────────────────────────────────────────────────┤
│  UI Layer (Material 3)                              │
│    ├─ RoomListScreen                                │
│    ├─ RoomScreen (transcript + composer + AppBar)   │
│    ├─ AgentEditorScreen                             │
│    └─ RoomEditorScreen                              │
├────────────────────────────────────────────────────┤
│  State Layer (Riverpod)                             │
│    ├─ roomsProvider        ── Room list + active    │
│    ├─ agentsProvider       ── Agent list            │
│    ├─ roomSessionProvider  ── live debate state     │
│    └─ settingsProvider     ── defaults              │
├────────────────────────────────────────────────────┤
│  Service Layer                                      │
│    ├─ DebateEngine       ── round loop, retry,      │
│    │                       cooldown, timer, pause   │
│    ├─ AgentRouter        ── routes to right         │
│    │                       provider adapter         │
│    ├─ KeyVault           ── flutter_secure_storage  │
│    ├─ RoomRepository     ── Drift DAO               │
│    └─ Provider Adapters  ── Gemini, NanoGPT,        │
│                            OpenRouter, OpenAI…      │
├────────────────────────────────────────────────────┤
│  Persistence                                        │
│    ├─ Drift (SQLite) — rooms, agents, transcripts   │
│    └─ Secure Storage — API keys                     │
├────────────────────────────────────────────────────┤
│  External                                           │
│    ├─ Gemini API                                       │
│    ├─ NanoGPT API                                      │
│    ├─ OpenRouter                                       │
│    └─ OpenAI / others                                  │
└────────────────────────────────────────────────────┘
```

**No backend.** Everything runs on-device.

---

## 4. State — Where It Lives

| Data | Where |
|---|---|
| Rooms, Roster, transcript messages | Drift (SQLite) — `rooms`, `agents`, `room_agents`, `messages` |
| Agent configs (name, persona, provider, model, system prompt) | Drift — `agents` table |
| API keys | `flutter_secure_storage` (Keystore/Keychain). **Never** in SQLite. |
| Active debate session state (current round, timer remaining, paused flag) | Riverpod in-memory + checkpointed to Drift after each round |
| App settings (defaults, UI prefs) | Drift — `settings` table (k/v) |

**Source of truth**: Drift for all persistent state. Secure storage for keys only.

---

## 5. Boundaries — Trust Lines

| Zone | Can See | Cannot See |
|---|---|---|
| **Orchestrator (you)** | Everything. All keys. All system prompts. All messages. Mid-debate steering. | — |
| **Agent** | Topic + Roster-visible messages + its own config. Sees Orchestrator's typed messages with role tag "Orchestrator". | Other Agents' system prompts. Any API key. |
| **Provider** | What we send: messages + system prompt + model id. | Anything local. |

**Per-Room system prompt override** — same Agent can have different personas in different Rooms (stored in `room_agents` join table).

**Private channels**: out of scope for v0.1. Default = full transcript visibility among Roster.

---

## 6. MVP Cut (v0.1)

### ✅ In Scope

1. **Agents CRUD** — create/edit/delete Agents (display name, provider, model, system prompt, API key entry).
2. **Rooms CRUD** — create/open/delete Rooms (topic, Roster of 1–4 Agents, run mode = Single or Debate).
3. **Single mode** — send prompt → all Roster Agents reply once → transcript freezes.
4. **Debate mode** — autonomous loop:
   - Roster Agents reply in rounds, each sees prior rounds' messages.
   - **3s cooldown** between rounds.
   - **Max 30 rounds** per session. On hit → inline "Continue for 30 more?" button (renewable indefinitely).
   - **Universal "Pause All" toggle** in AppBar (instant).
   - **"Take Turn" button** in AppBar — injects Orchestrator's typed message as next round (role: Orchestrator).
   - **Per-Room timer**, settable anytime (start, mid-debate). Auto-pauses loop at expiry.
5. **Error guardrails**:
   - Per-Agent retry budget = 2 on rate-limit (HTTP 429 / 5xx).
   - On retry exhaustion → mark Agent "stalled", continue debate without it.
   - Stall detection: if Agent hasn't replied in 60s → mark stalled.
   - Cooldown 3s prevents burst rate-limit.
6. **Resume** — each round persisted to Drift immediately. On app restart mid-debate → "Resume from round N" prompt with inline buttons (`Resume` / `Discard`).
7. **Persistence** — Drift.

### ❌ Out of Scope (v0.1)

- Agent-to-Agent @-mentions
- Private channels / visibility scoping
- Streaming tokens (await full reply for v0.1)
- Voice / image / file attachments
- Multi-device sync
- Token / cost tracking dashboard
- Export / import
- Rerun / fork Room
- Image-input models (text-only for v0.1)

---

## 7. Failure Modes & Guards

| Failure | Guard |
|---|---|
| Provider rate-limits mid-debate (429) | Per-Agent retry budget = 2 + exponential backoff (3s → 6s → mark stalled). |
| Agent silent / network drop | 60s stall detection → mark "stalled", others continue. |
| Debate runs forever | Timer auto-stop + 30-round cap (renewable via inline button). |
| Orchestrator types mid-debate | "Take Turn" pauses loop, message injected as next round with role "Orchestrator". |
| App crash mid-debate | Each round persisted to Drift on arrival. On restart, resume prompt with inline buttons. |
| API key leak | Keys only in `flutter_secure_storage`. **Never** logged. Audit code paths in pre-release test. |
| Provider API change | Adapter pattern — each provider behind a `ProviderAdapter` interface. Adding a provider = new adapter file only. |
| OpenAI-compatible streaming differences | v0.1 = await full reply, no streaming. Avoids 80% of provider quirks. Streaming deferred. |

---

## 8. Verification (Definition of Done for v0.1)

All 6 must pass on real Android device:

1. **Smoke** — 1 Room, 2 Agents (Gemini + MiniMax-M3). Single mode prompt → both reply → both persist.
2. **Loop** — Same Room, Debate mode, 5 rounds. Each Agent sees prior rounds. 3s cooldown observed.
3. **Failure** — Set Gemini key to invalid. Run Debate. Gemini stalls after 2 retries, others continue. Transcript marks Gemini "stalled" not "crashed".
4. **Take Turn** — Mid-debate, tap "Take Turn". Loop pauses. Orchestrator message injected as next round with role tag. Debate resumes.
5. **Timer** — Set 1-min timer. Loop auto-pauses at minute 1. Extend via inline "Continue 30 more?" button.
6. **Crash resume** — Force-kill app at round 7. Restart. Inline prompt "Resume from round 7?". Tap Resume → continues from round 7.

---

## 9. Open Questions (post-MVP, for v0.2)

- Streaming tokens per provider?
- Token/cost dashboard per Room?
- Agent @-mentions between Agents?
- Private channels (Orchestrator whispers to one Agent)?
- Export / import Room (markdown / JSON)?
- Image input for vision-capable models?
- Voice output (TTS per Agent)?
- "Fork from round N" feature?

---

## 10. File Layout (proposed)

```
agent_chatroom/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── domain/
│   │   ├── agent.dart
│   │   ├── room.dart
│   │   ├── message.dart
│   │   └── round.dart
│   ├── data/
│   │   ├── db/
│   │   │   ├── database.dart
│   │   │   ├── tables.dart
│   │   │   └── daos/
│   │   ├── secure/
│   │   │   └── key_vault.dart
│   │   └── providers/
│   │       ├── provider_adapter.dart
│   │       ├── gemini_adapter.dart
│   │       ├── nanogpt_adapter.dart
│   │       ├── openrouter_adapter.dart
│   │       └── openai_adapter.dart
│   ├── services/
│   │   ├── debate_engine.dart
│   │   ├── agent_router.dart
│   │   └── room_repository.dart
│   ├── state/
│   │   ├── rooms_provider.dart
│   │   ├── agents_provider.dart
│   │   ├── room_session_provider.dart
│   │   └── settings_provider.dart
│   └── ui/
│       ├── screens/
│       │   ├── room_list_screen.dart
│       │   ├── room_screen.dart
│       │   ├── agent_editor_screen.dart
│       │   └── room_editor_screen.dart
│       └── widgets/
│           ├── message_bubble.dart
│           ├── debate_controls.dart
│           └── resume_prompt.dart
├── test/
│   ├── debate_engine_test.dart
│   ├── retry_budget_test.dart
│   └── resume_test.dart
└── pubspec.yaml
```

**Key dependencies:**
- `drift` + `drift_dev` + `sqlite3_flutter_libs` — persistence
- `flutter_riverpod` — state
- `flutter_secure_storage` — key vault
- `dio` — HTTP with retry support
- `freezed` + `json_serializable` — domain models
- `intl` — timestamps

---

## 11. Out-of-Scope Hard List (do not pull in)

- Backend / cloud sync (v0.1 is fully local)
- Authentication / multi-user (single Orchestrator only)
- Mobile push notifications (no background work for v0.1)
- Voice / TTS
- Image / video generation (text-only v0.1)

---

## Sign-off

Aligned by:
- Q1 Outcome ✅
- Q2 System shape (A — on-device) ✅
- Q3 Naming (Orchestrator / Agent / Room) ✅
- Q4 State (Drift) ✅
- Q5 Boundaries (secure storage, full visibility, no cross-prompt leak) ✅
- Q6 MVP cut (Single + Debate + guards + timer + Take Turn + Pause + resume) ✅
- Q7 Failure modes (retry budget, stall detection, timer, resume) ✅
- Q8 Verification (6 test cases on real device) ✅

**Ready to scaffold `agent_chatroom/` Flutter project.**
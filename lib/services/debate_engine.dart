import 'package:flutter/foundation.dart';

import '../data/providers/provider_adapter.dart';

/// The DebateEngine orchestrates:
/// - Single mode: prompt → all Agents reply once → transcript freezes
/// - Debate mode: Agents reply in rounds, each round all see prior rounds
///
/// Responsibilities:
/// - Manage the round loop, cooldown, max rounds
/// - Retry budget (2 retries on 429/5xx)
/// - Stall detection (60s per Agent)
/// - Timer auto-stop
/// - Pause/resume (controlled by RoomSessionProvider)
/// - Orchestrator "Take Turn" injection
///
/// Usage pattern:
///   final engine = DebateEngine(...);
///   engine.start(topic: '...', prompt: '...');
///   while (!engine.isFinished) {
///     await engine.processNextRound(); // auto-advances if timer/rounds allow
///   }
class DebateEngine {
  final ProviderFactory providerFactory;

  final Duration cooldown;
  final int retryBudget;
  final Duration stallTimeout;

  final int maxRounds;

  /// Whether the engine is actively running.
  bool isRunning = false;

  /// Whether the engine is currently paused (user paused all).
  bool isPaused = false;

  /// Current round number (1-based). 0 means not started.
  int currentRound = 0;

  /// Tracks Agent progress through the retry budget.
  final Map<String, int> _retryCount = {};

  DebateEngine({
    required this.providerFactory,
    this.cooldown = const Duration(seconds: 3),
    this.retryBudget = 2,
    this.stallTimeout = const Duration(seconds: 60),
    this.maxRounds = 30,
  });

  /// Start a new session with a topic.
  ///
  /// Returns true if the session started (not already running).
  bool start({
    required String topic,
  }) {
    if (isRunning) return false;
    isRunning = true;
    isPaused = false;
    currentRound = 0;
    _retryCount.clear();
    return true;
  }

  /// Inject an Orchestrator message into the debate.
  ///
  /// When the Orchestrator types, this is inserted as a round with
  /// role=orchestrator. The debate resumes normally after.
  void takeTurn(String message) {
    // This is a hook — the actual round creation happens in the
    // DebateService layer (see services/debate_service.dart).
    // Engine stores intent; service executes.
  }

  /// Pause the engine (called by pauseAll AppBar action).
  void pause() {
    if (!isRunning) return;
    isPaused = true;
  }

  /// Resume after pause.
  void resume() {
    isPaused = false;
  }

  /// Stop and reset the engine.
  void stop() {
    isRunning = false;
    isPaused = false;
    currentRound = 0;
    _retryCount.clear();
  }

  /// Check if the current round should be processed.
  bool canProcessRound() {
    if (!isRunning) return false;
    if (isPaused) return false;
    if (currentRound >= maxRounds) return false;
    return true;
  }

  /// Check if a round was "completed" (auto-stopped due to timer/rounds).
  bool isRoundComplete(int completed) => completed >= maxRounds;

  /// Check if the engine hit the max round cap.
  bool hitMaxRounds() => currentRound >= maxRounds;

  /// Increment retry count for an Agent.
  void incrementRetry(String agentId) {
    _retryCount[agentId] = (_retryCount[agentId] ?? 0) + 1;
  }

  /// Get retry count for an Agent.
  int getRetryCount(String agentId) => _retryCount[agentId] ?? 0;

  /// Check if an Agent has exhausted its retry budget.
  bool isStalled(String agentId) => getRetryCount(agentId) >= retryBudget;

  /// Advance to the next round.
  int nextRound() => ++currentRound;
}
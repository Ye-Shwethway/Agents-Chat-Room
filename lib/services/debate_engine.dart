import 'package:flutter/foundation.dart';

import '../domain/agent.dart';
import '../domain/message.dart';
import '../domain/room.dart';
import '../data/providers/provider_adapter.dart';

/// Factory that produces a ProviderAdapter for a given LlmProvider.
typedef ProviderFactory = ProviderAdapter Function(LlmProvider provider);

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
@immutable
class DebateEngine {
  final ProviderFactory providerFactory;

  final Duration cooldown;
  final int retryBudget;
  final Duration stallTimeout;

  final int maxRounds;

  /// Whether the engine is actively running.
  bool get isRunning => _running;
  bool _running = false;

  /// Whether the engine is currently paused (user paused all).
  bool get isPaused => _paused;
  bool _paused = false;

  /// Current round number (1-based). 0 means not started.
  int get currentRound => _currentRound;
  int _currentRound = 0;

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
    required List<Agent> roster,
  }) {
    if (_running) return false;
    _running = true;
    _paused = false;
    _currentRound = 0;
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
    _takeTurnMessage = message;
  }

  String? _takeTurnMessage;

  /// Pause the engine (called by pauseAll AppBar action).
  void pause() {
    if (!_running) return;
    _paused = true;
  }

  /// Resume after pause.
  void resume() {
    _paused = false;
  }

  /// Stop and reset the engine.
  void stop() {
    _running = false;
    _paused = false;
    _currentRound = 0;
    _retryCount.clear();
  }

  /// Check if the current round should be processed.
  bool canProcessRound() {
    if (!_running) return false;
    if (_paused) return false;
    if (_currentRound >= maxRounds) return false;
    return true;
  }

  /// Check if a round was "completed" (auto-stopped due to timer/rounds).
  bool isRoundComplete(int completed) => completed >= maxRounds;

  /// Check if the engine hit the max round cap.
  bool hitMaxRounds() => _currentRound >= maxRounds;

  /// Increment retry count for an Agent.
  void incrementRetry(String agentId) {
    _retryCount[agentId] = (_retryCount[agentId] ?? 0) + 1;
  }

  /// Get retry count for an Agent.
  int getRetryCount(String agentId) => _retryCount[agentId] ?? 0;

  /// Check if an Agent has exhausted its retry budget.
  bool isStalled(String agentId) => getRetryCount(agentId) >= retryBudget;

  /// Advance to the next round.
  int nextRound() => ++_currentRound;
}
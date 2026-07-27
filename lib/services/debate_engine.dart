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
class DebateEngine {
  final ProviderFactory providerFactory;
  final Duration cooldown;
  final int retryBudget;
  final Duration stallTimeout;
  final int maxRounds;

  bool isRunning = false;
  bool isPaused = false;
  int currentRound = 0;

  final Map<String, int> _retryCount = {};

  DebateEngine({
    required this.providerFactory,
    this.cooldown = const Duration(seconds: 3),
    this.retryBudget = 2,
    this.stallTimeout = const Duration(seconds: 60),
    this.maxRounds = 30,
  });

  bool start({required String topic}) {
    if (isRunning) return false;
    isRunning = true;
    isPaused = false;
    currentRound = 0;
    _retryCount.clear();
    return true;
  }

  void pause() {
    if (!isRunning) return;
    isPaused = true;
  }

  void resume() {
    isPaused = false;
  }

  void stop() {
    isRunning = false;
    isPaused = false;
    currentRound = 0;
    _retryCount.clear();
  }

  bool canProcessRound() {
    if (!isRunning) return false;
    if (isPaused) return false;
    if (currentRound >= maxRounds) return false;
    return true;
  }

  bool isRoundComplete(int completed) => completed >= maxRounds;
  bool hitMaxRounds() => currentRound >= maxRounds;

  void incrementRetry(String agentId) {
    _retryCount[agentId] = (_retryCount[agentId] ?? 0) + 1;
  }

  int getRetryCount(String agentId) => _retryCount[agentId] ?? 0;
  bool isStalled(String agentId) => getRetryCount(agentId) >= retryBudget;

  int nextRound() => ++currentRound;
}
import 'package:freezed_annotation/freezed_annotation.dart';

import 'agent.dart';

part 'room.freezed.dart';

/// How a Room processes a single user prompt.
enum RunMode {
  /// Orchestrator prompt → all Roster Agents reply once → transcript freezes.
  single,

  /// Agents reply in rounds, each round all see prior rounds, loop continues
  /// until timer expires, Orchestrator takes a turn, or round cap is hit.
  debate,
}

/// A persistent chat session: topic + Roster + transcript + run mode + timer.
///
/// Rooms are owned by the Orchestrator. Only one Room session can be
/// "active" at a time (single-window UI).
@freezed
class Room with _$Room {
  const factory Room({
    required String id,

    /// The topic / prompt that anchors the discussion.
    required String topic,

    /// Roster of Agents assigned to this Room (1–4).
    @Default([]) List<Agent> roster,

    /// How messages are produced within this Room.
    @Default(RunMode.single) RunMode runMode,

    /// Per-Room timer config (debate mode only). Null = no auto-stop.
    @Default(null) Duration? timerDuration,

    /// Per-Room max rounds cap. Hits → prompt to renew.
    @Default(30) int maxRounds,

    /// When this Room was created.
    required DateTime createdAt,

    /// Last activity (message timestamp). Used for sorting the Room list.
    required DateTime updatedAt,
  }) = _Room;
}
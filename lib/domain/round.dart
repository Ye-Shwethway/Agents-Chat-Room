import 'package:freezed_annotation/freezed_annotation.dart';

import 'message.dart';

part 'round.freezed.dart';

/// One turn-batch in a Debate-mode Room: each Roster Agent produces one
/// `Message` (with `round = n`).
///
/// Single-mode Rooms treat each Orchestrator prompt as a degenerate Round
/// (round 1 with one Orchestrator + N Agent messages).
@freezed
class Round with _$Round {
  const factory Round({
    required int number,

    /// Messages produced during this round, in arrival order.
    @Default([]) List<Message> messages,
  }) = _Round;
}
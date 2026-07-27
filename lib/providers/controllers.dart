import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../domain/agent.dart';
import '../domain/room.dart';

/// Controller for creating/updating/deleting Agents.
///
/// Wrap any DB write in `AsyncValue.guard` so the UI can render errors
/// uniformly. UI layer calls these from Providers or directly.
class AgentController {
  AgentController(this._db, this._ref);

  final AppDatabase _db;
  final Ref _ref;

  Future<void> create(Agent agent) async {
    await _db.upsertAgent(
      AgentsCompanion.insert(
        id: agent.id,
        name: agent.name,
        provider: agent.provider.name,
        modelId: agent.modelId,
        systemPrompt: Value(agent.systemPrompt),
        createdAt: agent.createdAt,
      ),
    );
    _ref.invalidate(agentsProvider);
  }

  Future<void> update(Agent agent) async {
    await create(agent);  // same upsert
  }

  Future<void> delete(String id) async {
    await _db.deleteAgent(id);
    _ref.invalidate(agentsProvider);
  }
}

final agentControllerProvider = Provider<AgentController>((ref) {
  return AgentController(ref.watch(databaseProvider), ref);
});

/// Controller for Rooms.
class RoomController {
  RoomController(this._db, this._ref);

  final AppDatabase _db;
  final Ref _ref;

  Future<void> create(Room room, List<String> agentIds) async {
    await _db.transaction(() async {
      await _db.upsertRoom(
        RoomsCompanion.insert(
          id: room.id,
          topic: room.topic,
          runMode: room.runMode.name,
          timerDurationSeconds: Value(room.timerDuration?.inSeconds),
          maxRounds: Value(room.maxRounds),
          createdAt: room.createdAt,
          updatedAt: room.updatedAt,
        ),
      );
      await _db.setRoster(room.id, agentIds);
    });
    _ref.invalidate(roomsProvider);
  }

  Future<void> setRoster(String roomId, List<String> agentIds) async {
    await _db.setRoster(roomId, agentIds);
    _ref.invalidate(rosterProvider(roomId));
  }

  Future<void> delete(String id) async {
    await _db.deleteRoom(id);
    _ref.invalidate(roomsProvider);
  }
}

final roomControllerProvider = Provider<RoomController>((ref) {
  return RoomController(ref.watch(databaseProvider), ref);
});
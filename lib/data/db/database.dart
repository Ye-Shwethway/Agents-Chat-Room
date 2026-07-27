import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Agents, Rooms, RoomAgents, Messages, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only constructor — pass an in-memory NativeDatabase.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
      );

  // ---- Agent queries ----

  Future<List<Agent>> getAllAgents() => select(agents).get();

  Stream<List<Agent>> watchAllAgents() =>
      (select(agents)..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .watch();

  Future<Agent?> getAgent(String id) =>
      (select(agents)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertAgent(AgentsCompanion entry) =>
      into(agents).insertOnConflictUpdate(entry);

  Future<void> deleteAgent(String id) =>
      (delete(agents)..where((t) => t.id.equals(id))).go();

  // ---- Room queries ----

  Future<List<Room>> getAllRooms() => select(rooms).get();

  Stream<List<Room>> watchAllRooms() =>
      (select(rooms)..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
          .watch();

  Future<Room?> getRoom(String id) =>
      (select(rooms)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertRoom(RoomsCompanion entry) =>
      into(rooms).insertOnConflictUpdate(entry);

  Future<void> deleteRoom(String id) async {
    // Cascade on Messages + RoomAgents handles child rows via FK.
    await (delete(rooms)..where((t) => t.id.equals(id))).go();
  }

  // ---- Roster (join) ----

  Future<List<Agent>> getRoster(String roomId) async {
    final query = select(roomAgents).join([
      innerJoin(agents, agents.id.equalsExp(roomAgents.agentId)),
    ])
      ..where(roomAgents.roomId.equals(roomId))
      ..orderBy([OrderingTerm(expression: roomAgents.position)]);
    final rows = await query.get();
    return rows.map((row) => row.readTable(agents)).toList();
  }

  Stream<List<Agent>> watchRoster(String roomId) {
    final query = select(roomAgents).join([
      innerJoin(agents, agents.id.equalsExp(roomAgents.agentId)),
    ])
      ..where(roomAgents.roomId.equals(roomId))
      ..orderBy([OrderingTerm(expression: roomAgents.position)]);
    return query.watch().map(
          (rows) => rows.map((row) => row.readTable(agents)).toList(),
        );
  }

  Future<void> setRoster(String roomId, List<String> agentIds) async {
    await transaction(() async {
      await (delete(roomAgents)..where((t) => t.roomId.equals(roomId))).go();
      for (var i = 0; i < agentIds.length; i++) {
        await into(roomAgents).insert(
          RoomAgentsCompanion.insert(
            roomId: roomId,
            agentId: agentIds[i],
            position: i,
          ),
        );
      }
    });
  }

  // ---- Message queries ----

  Stream<List<Message>> watchMessages(String roomId) =>
      (select(messages)
            ..where((t) => t.roomId.equals(roomId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.round),
              (t) => OrderingTerm(expression: t.ordinal),
              (t) => OrderingTerm(expression: t.createdAt),
            ]))
          .watch();

  Future<void> upsertMessage(MessagesCompanion entry) =>
      into(messages).insertOnConflictUpdate(entry);

  Future<List<Message>> getMessagesAfter(String roomId, int round) =>
      (select(messages)
            ..where((t) => t.roomId.equals(roomId) & t.round.isBiggerThanValue(round))
            ..orderBy([
              (t) => OrderingTerm(expression: t.round),
              (t) => OrderingTerm(expression: t.ordinal),
            ]))
          .get();

  // ---- Settings ----

  Future<String?> getSetting(String key) async {
    final row = await (select(settings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: value),
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'agent_chatroom.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
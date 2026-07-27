import 'package:drift/drift.dart';

/// Drift table definitions.
///
/// These mirror the domain models in `lib/domain/` but in storage form:
/// enums become text columns (Drift has no native enum type), nested
/// objects (Room.roster → list of Agents) become a join table
/// (`RoomAgents`), and freezed-style immutability is replaced by Drift's
/// generated row classes (e.g. `AgentRow`).
///
/// Schema versioning: see `database.dart` `schemaVersion`. Every time
/// these tables change, bump it and add a migration step.

/// Agents table — see `lib/domain/agent.dart`.
class Agents extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get provider => text()();      // LlmProvider.name
  TextColumn get modelId => text()();
  TextColumn get systemPrompt => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Rooms table — see `lib/domain/room.dart`.
class Rooms extends Table {
  TextColumn get id => text()();
  TextColumn get topic => text()();
  TextColumn get runMode => text()();       // RunMode.name
  IntColumn get timerDurationSeconds => integer().nullable()();
  IntColumn get maxRounds => integer().withDefault(const Constant(30))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Join table: which Agents are in a Room's Roster, and in what order.
///
/// `position` is 0-based roster order; the UI uses this to render the
/// Roster column.
class RoomAgents extends Table {
  TextColumn get roomId => text().references(Rooms, #id, onDelete: KeyAction.cascade)();
  TextColumn get agentId => text().references(Agents, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {roomId, agentId};
}

/// Messages table — see `lib/domain/message.dart`.
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get roomId => text().references(Rooms, #id, onDelete: KeyAction.cascade)();
  TextColumn get agentId => text().nullable()();  // null for orchestrator / system
  TextColumn get role => text()();                 // MessageRole.name
  TextColumn get content => text().withDefault(const Constant(''))();
  IntColumn get round => integer().withDefault(const Constant(0))();
  IntColumn get ordinal => integer().withDefault(const Constant(0))();
  TextColumn get status => text()();               // MessageStatus.name
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Settings — generic key/value store for app preferences and runtime state.
///
/// Used for things like: "currently active Room id", "preferred theme",
/// "last-used model per provider".
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
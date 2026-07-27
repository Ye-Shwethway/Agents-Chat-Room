import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/providers/gemini_adapter.dart';
import '../data/providers/key_vault.dart';
import '../data/providers/nanogpt_adapter.dart';
import '../data/providers/openai_adapter.dart';
import '../data/providers/openrouter_adapter.dart';
import '../data/providers/provider_adapter.dart';
import '../data/secure/key_vault.dart';
import '../domain/agent.dart';
import '../domain/message.dart';
import '../domain/room.dart';

/// Typedef so the UI doesn't need to know the underlying Drift row class.
typedef Agent = DomainAgent;
typedef Room = DomainRoom;
typedef Message = DomainMessage;

/// Factory that maps LlmProvider -> ProviderAdapter.
typedef ProviderFactory = ProviderAdapter Function(LlmProvider);

// ---- Core providers ----

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final keyVaultProvider = Provider<KeyVault>((ref) => KeyVault());

final providerFactoryProvider = Provider<ProviderFactory>((ref) {
  return (LlmProvider provider) {
    switch (provider) {
      case LlmProvider.gemini:
        return GeminiAdapter();
      case LlmProvider.nanogpt:
        return NanoGptAdapter();
      case LlmProvider.openrouter:
        return OpenRouterAdapter();
      case LlmProvider.openai:
        return OpenAiAdapter();
    }
  };
});

// ---- Reactive query providers ----
//
// Each watches a Drift database stream and maps the generated row class
// (AgentData, RoomData, MessageData) into the matching domain model so
// the rest of the app sees stable domain types only.

final agentsProvider = StreamProvider<List<DomainAgent>>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .watchAllAgents()
      .map((rows) => rows.map(_agentFromRow).toList());
});

final roomsProvider = StreamProvider<List<DomainRoom>>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .watchAllRooms()
      .map((rows) => rows.map(_roomFromRow).toList());
});

final rosterProvider =
    StreamProvider.family<List<DomainAgent>, String>((ref, roomId) {
  final db = ref.watch(databaseProvider);
  return db
      .watchRoster(roomId)
      .map((rows) => rows.map(_agentFromRow).toList());
});

final messagesProvider =
    StreamProvider.family<List<DomainMessage>, String>((ref, roomId) {
  final db = ref.watch(databaseProvider);
  return db
      .watchMessages(roomId)
      .map((rows) => rows.map(_messageFromRow).toList());
});

/// Currently active Room id, kept in the Settings table.
final activeRoomIdProvider = StateProvider<String?>((ref) => null);

/// Map of provider name -> whether a key exists in KeyVault.
final providerAvailabilityProvider =
    FutureProvider<Map<String, bool>>((ref) async {
  final vault = ref.watch(keyVaultProvider);
  final result = <String, bool>{};
  for (final p in LlmProvider.values) {
    final key = await vault.getProviderKey(p.name);
    result[p.name] = key != null && key.isNotEmpty;
  }
  return result;
});

// ---- Drift row → domain model mappers ----

DomainAgent _agentFromRow(AgentData row) => DomainAgent(
      id: row.id,
      name: row.name,
      provider: _providerFromName(row.provider),
      modelId: row.modelId,
      systemPrompt: row.systemPrompt,
      createdAt: row.createdAt,
    );

DomainRoom _roomFromRow(RoomData row) => DomainRoom(
      id: row.id,
      topic: row.topic,
      roster: const [],
      runMode: _runModeFromName(row.runMode),
      timerDuration: row.timerDurationSeconds == null
          ? null
          : Duration(seconds: row.timerDurationSeconds!),
      maxRounds: row.maxRounds,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );

DomainMessage _messageFromRow(MessageData row) => DomainMessage(
      id: row.id,
      roomId: row.roomId,
      agentId: row.agentId,
      role: _roleFromName(row.role),
      content: row.content,
      round: row.round,
      ordinal: row.ordinal,
      status: _statusFromName(row.status),
      createdAt: row.createdAt,
    );

LlmProvider _providerFromName(String name) =>
    LlmProvider.values.firstWhere((p) => p.name == name);

RunMode _runModeFromName(String name) =>
    RunMode.values.firstWhere((p) => p.name == name);

MessageRole _roleFromName(String name) =>
    MessageRole.values.firstWhere((p) => p.name == name);

MessageStatus _statusFromName(String name) =>
    MessageStatus.values.firstWhere((p) => p.name == name);

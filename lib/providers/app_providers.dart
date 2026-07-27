import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/providers/gemini_adapter.dart';
import '../data/providers/nanogpt_adapter.dart';
import '../data/providers/openai_adapter.dart';
import '../data/providers/openrouter_adapter.dart';
import '../data/providers/provider_adapter.dart';
import '../data/secure/key_vault.dart';
import '../domain/agent.dart';
import '../domain/room.dart';

/// App-wide singletons.

/// On-device Drift database. The `AppDatabase` instance is process-singleton
/// (one DB connection per app run). The provider returns the same instance
/// for the entire app lifetime.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Secure API key vault (wraps flutter_secure_storage).
final keyVaultProvider = Provider<KeyVault>((ref) => KeyVault());

/// Factory that maps LlmProvider -> ProviderAdapter instance.
///
/// Providers that are rejected by their `.env` (i.e. key absent) are not
/// callable; the UI checks [providerAvailabilityProvider] before letting
/// the user invoke them.
final providerFactoryProvider = Provider<ProviderAdapter Function(LlmProvider)>(
  (ref) {
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
  },
);

/// Reactive list of all Agents in the database.
final agentsProvider = StreamProvider<List<Agent>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllAgents();
});

/// Reactive list of all Rooms (sorted by `updatedAt desc`).
final roomsProvider = StreamProvider<List<Room>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllRooms();
});

/// Reactive roster (Roster agents in display order) for a given Room.
final rosterProvider = StreamProvider.family<List<Agent>, String>((ref, roomId) {
  final db = ref.watch(databaseProvider);
  return db.watchRoster(roomId);
});

/// Reactive message stream for a given Room (chronological).
final messagesProvider = StreamProvider.family<List<Message>, String>((ref, roomId) {
  final db = ref.watch(databaseProvider);
  return db.watchMessages(roomId);
});

/// Currently active Room id, kept in the Settings table.
///
/// Used by the BottomNavigationBar to remember which Room is "open" when
/// the app cold-starts.
final activeRoomIdProvider = StateProvider<String?>((ref) => null);

/// Map of provider name -> whether a key exists in KeyVault.
///
/// Recomputed when the user adds/deletes a key. Used to filter the
/// "Choose provider" dropdown so only configured providers are shown.
final providerAvailabilityProvider = FutureProvider<Map<String, bool>>((ref) async {
  final vault = ref.watch(keyVaultProvider);
  final result = <String, bool>{};
  for (final p in LlmProvider.values) {
    final key = await vault.getProviderKey(p.name);
    result[p.name] = key != null && key.isNotEmpty;
  }
  return result;
});
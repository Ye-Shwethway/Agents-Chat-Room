import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure API key vault.
///
/// Keys are stored in `flutter_secure_storage` (Keystore on Android,
/// Keychain on iOS). Never persisted to Drift or plaintext files.
///
/// Key format: `{"<provider>":"<key>"}` or `{"<agent_id>":"<key>"}`
class KeyVault {
  static const _storage = FlutterSecureStorage();

  /// Get a provider's API key.
  Future<String?> getProviderKey(String provider) {
    return _storage.read(key: 'api_key.$provider');
  }

  /// Get an Agent's API key (agent-specific key overrides provider default).
  Future<String?> getAgentKey(String agentId) {
    return _storage.read(key: 'api_key.agent.$agentId');
  }

  /// Set a provider's API key.
  Future<void> setProviderKey(String provider, String key) {
    return _storage.write(key: 'api_key.$provider', value: key);
  }

  /// Set an Agent's API key.
  Future<void> setAgentKey(String agentId, String key) {
    return _storage.write(key: 'api_key.agent.$agentId', value: key);
  }

  /// Delete a provider's API key.
  Future<void> deleteProviderKey(String provider) {
    return _storage.delete(key: 'api_key.$provider');
  }

  /// Delete an Agent's API key.
  Future<void> deleteAgentKey(String agentId) {
    return _storage.delete(key: 'api_key.agent.$agentId');
  }

  /// Migrate an existing key from provider-level to agent-level.
  ///
  /// Useful when a user has a single NanoGPT key and wants to give
  /// a specific Agent a different model from the same provider.
  Future<void> migrateKey(String provider, String agentId, String key) async {
    await setProviderKey(provider, key);
    await setAgentKey(agentId, key);
  }
}
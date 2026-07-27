import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/agent.dart';
import '../../providers/app_providers.dart';

/// Settings screen — manage API keys for each LLM provider.
///
/// Keys are stored in [KeyVault] (flutter_secure_storage, backed by Keystore
/// on Android). They are NEVER persisted to Drift or logs.
///
/// One key per provider (for now). Future: per-Agent override.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final Map<LlmProvider, TextEditingController> _controllers;
  late final Map<LlmProvider, bool> _hasKey;

  @override
  void initState() {
    super.initState();
    _controllers = {for (final p in LlmProvider.values) p: TextEditingController()};
    _hasKey = {for (final p in LlmProvider.values) p: false};
    _loadExistingKeys();
  }

  Future<void> _loadExistingKeys() async {
    final vault = ref.read(keyVaultProvider);
    for (final p in LlmProvider.values) {
      final k = await vault.getProviderKey(p.name);
      if (!mounted) return;
      setState(() {
        _hasKey[p] = k != null && k.isNotEmpty;
        _controllers[p]!.text = k ?? '';
      });
    }
    ref.invalidate(providerAvailabilityProvider);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'API Keys',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Each key is stored in your device\'s secure store '
              '(Android Keystore) and never leaves the device.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          for (final provider in LlmProvider.values)
            _ProviderKeyTile(
              provider: provider,
              controller: _controllers[provider]!,
              hasKey: _hasKey[provider]!,
              onSave: () => _saveKey(provider),
              onDelete: () => _deleteKey(provider),
            ),
        ],
      ),
    );
  }

  Future<void> _saveKey(LlmProvider provider) async {
    final controller = _controllers[provider]!;
    final value = controller.text.trim();
    if (value.isEmpty) return;
    final vault = ref.read(keyVaultProvider);
    await vault.setProviderKey(provider.name, value);
    if (!mounted) return;
    setState(() => _hasKey[provider] = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${provider.name} key saved')),
    );
    ref.invalidate(providerAvailabilityProvider);
  }

  Future<void> _deleteKey(LlmProvider provider) async {
    final vault = ref.read(keyVaultProvider);
    await vault.deleteProviderKey(provider.name);
    if (!mounted) return;
    setState(() {
      _hasKey[provider] = false;
      _controllers[provider]!.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${provider.name} key deleted')),
    );
    ref.invalidate(providerAvailabilityProvider);
  }
}

class _ProviderKeyTile extends StatelessWidget {
  const _ProviderKeyTile({
    required this.provider,
    required this.controller,
    required this.hasKey,
    required this.onSave,
    required this.onDelete,
  });

  final LlmProvider provider;
  final TextEditingController controller;
  final bool hasKey;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    provider.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (hasKey)
                  Chip(
                    label: const Text('Configured'),
                    backgroundColor: Colors.green.shade100,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: hasKey ? '••••••••' : 'Paste key here',
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              maxLines: 1,
              inputFormatters: [
                LengthLimitingTextInputFormatter(500),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasKey)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    onPressed: onDelete,
                  ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                  onPressed: onSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

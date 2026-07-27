import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/agent.dart';
import '../../providers/app_providers.dart';
import '../../providers/controllers.dart';

/// Screen to create or edit a single Agent.
///
/// Fields:
///   - Name (display name, required)
///   - Provider (gemini | nanogpt | openrouter | openai)
///   - ModelId (free text, e.g. "gemini-2.5-pro", "minimax/minimax-m3")
///   - System prompt (free text, optional)
///
/// Available providers are filtered to those with an API key configured.
class AgentEditScreen extends ConsumerStatefulWidget {
  const AgentEditScreen({super.key, this.agent});

  /// If non-null we're editing; if null we're creating.
  final Agent? agent;

  @override
  ConsumerState<AgentEditScreen> createState() => _AgentEditScreenState();
}

class _AgentEditScreenState extends ConsumerState<AgentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _modelId;
  late final TextEditingController _systemPrompt;
  LlmProvider? _provider;

  @override
  void initState() {
    super.initState();
    final a = widget.agent;
    _name = TextEditingController(text: a?.name ?? '');
    _modelId = TextEditingController(text: a?.modelId ?? '');
    _systemPrompt = TextEditingController(text: a?.systemPrompt ?? '');
    _provider = a?.provider;
  }

  @override
  void dispose() {
    _name.dispose();
    _modelId.dispose();
    _systemPrompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync = ref.watch(providerAvailabilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.agent == null ? 'New Agent' : 'Edit Agent'),
        actions: [
          if (widget.agent != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _onDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Optimist, Cynic, Pragmatist',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              maxLength: 40,
            ),
            const SizedBox(height: 16),
            availabilityAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (availability) {
                final available = LlmProvider.values
                    .where((p) => availability[p.name] ?? false)
                    .toList();
                if (available.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No provider configured. Add a key in Settings.',
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Settings'),
                        onPressed: () {
                          Navigator.of(context).pushNamed('/settings');
                        },
                      ),
                    ],
                  );
                }
                _provider ??= available.first;
                return DropdownButtonFormField<LlmProvider>(
                  initialValue: _provider,
                  decoration: const InputDecoration(
                    labelText: 'Provider',
                    border: OutlineInputBorder(),
                  ),
                  items: available
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name),
                          ))
                      .toList(),
                  onChanged: (p) => setState(() => _provider = p),
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelId,
              decoration: const InputDecoration(
                labelText: 'Model ID',
                hintText: 'e.g. minimax/minimax-m3',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              maxLength: 80,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _systemPrompt,
              decoration: const InputDecoration(
                labelText: 'System Prompt',
                hintText: 'Persona, role, or any framing…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 8,
              maxLength: 4000,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.save_outlined),
              label: Text(widget.agent == null ? 'Create' : 'Save'),
              onPressed: _onSubmit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(agentControllerProvider);
    final p = _provider;
    if (p == null) return;
    final agent = Agent(
      id: widget.agent?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      provider: p,
      modelId: _modelId.text.trim(),
      systemPrompt: _systemPrompt.text.trim(),
      createdAt: widget.agent?.createdAt ?? DateTime.now(),
    );
    await controller.upsert(agent);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _onDelete() async {
    final id = widget.agent?.id;
    if (id == null) return;
    final controller = ref.read(agentControllerProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Agent?'),
        content: Text('Remove "${widget.agent!.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.delete(id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

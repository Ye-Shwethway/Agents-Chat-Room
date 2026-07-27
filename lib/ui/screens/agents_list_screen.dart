import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/agent.dart';
import '../../providers/app_providers.dart';

/// Browse, create, edit, delete Agents.
///
/// Tapping an entry opens [AgentEditScreen] in edit mode. The FAB opens it
/// in create mode.
class AgentsListScreen extends ConsumerWidget {
  const AgentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentsProvider);
    final availabilityAsync = ref.watch(providerAvailabilityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Agents')),
      body: agentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e', textAlign: TextAlign.center),
          ),
        ),
        data: (agents) {
          if (agents.isEmpty) {
            return availabilityAsync.maybeWhen(
              data: (avail) {
                final hasAny = avail.values.any((v) => v);
                if (!hasAny) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.key_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No provider keys configured.\n\n'
                          'Open Settings to add an API key, '
                          'then create your first agent.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          icon: const Icon(Icons.settings),
                          label: const Text('Open Settings'),
                          onPressed: () {
                            Navigator.of(context).pushNamed('/settings');
                          },
                        ),
                      ],
                    ),
                  );
                }
                return const Center(
                  child: Text(
                    'No agents yet.\nTap + to create one.',
                    textAlign: TextAlign.center,
                  ),
                );
              },
              orElse: () => const Center(child: CircularProgressIndicator()),
            );
          }
          return ListView.separated(
            itemCount: agents.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final Agent a = agents[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(a.name.isEmpty ? '?' : a.name.characters.first),
                ),
                title: Text(a.name),
                subtitle: Text('${a.provider.name} · ${a.modelId}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/agents/edit',
                    arguments: a,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('New Agent'),
        onPressed: () {
          Navigator.of(context).pushNamed('/agents/edit');
        },
      ),
    );
  }
}

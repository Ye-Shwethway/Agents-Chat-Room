import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

/// Lists all Rooms. Tapping a Room navigates to the Room screen (TODO).
/// FAB opens a "Create Room" dialog (TODO).
class RoomListScreen extends ConsumerWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings — coming soon')),
              );
            },
          ),
        ],
      ),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e', textAlign: TextAlign.center),
          ),
        ),
        data: (rooms) {
          if (rooms.isEmpty) {
            return const Center(
              child: Text('No rooms yet.\nTap + to create one.'),
            );
          }
          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final room = rooms[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(room.runMode == RunMode.debate ? 'D' : 'S'),
                ),
                title: Text(
                  room.topic.isEmpty ? '(untitled)' : room.topic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${room.runMode == RunMode.debate ? 'Debate' : 'Single'}'
                  '${room.timerDuration != null ? " • ${room.timerDuration!.inMinutes}m timer" : ""}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Room "${room.topic}" — TBD')),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Room'),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create-Room flow — coming soon')),
          );
        },
      ),
    );
  }
}
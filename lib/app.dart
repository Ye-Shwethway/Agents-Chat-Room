import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/agent.dart';
import 'ui/screens/agent_edit_screen.dart';
import 'ui/screens/agents_list_screen.dart';
import 'ui/screens/room_list_screen.dart';
import 'ui/screens/settings_screen.dart';

/// The root widget for Agent Chatroom.
///
/// Navigation uses simple `Navigator.pushNamed` for v0.1. A bottom nav bar
/// switches between Rooms and Agents. Settings is reached from the top-right
/// gear icon on the Rooms screen.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agent Chatroom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const _RootScreen(),
      routes: {
        '/settings': (_) => const SettingsScreen(),
        '/agents/edit': (ctx) {
          final agent = ModalRoute.of(ctx)?.settings.arguments as Agent?;
          return AgentEditScreen(agent: agent);
        },
      },
    );
  }
}

class _RootScreen extends ConsumerStatefulWidget {
  const _RootScreen();

  @override
  ConsumerState<_RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<_RootScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          RoomListScreen(),
          AgentsListScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Rooms',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Agents',
          ),
        ],
      ),
    );
  }
}

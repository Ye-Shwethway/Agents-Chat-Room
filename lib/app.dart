import 'package:flutter/material.dart';

import 'ui/screens/room_list_screen.dart';

/// The root widget for Agent Chatroom.
///
/// In v0.1 this is just a placeholder for the Room list. Future versions
/// will add navigation, providers, and settings screens here.
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
      home: const RoomListScreen(),
    );
  }
}
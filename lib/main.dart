import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // Riverpod's ProviderScope provides the app-wide Riverpod context.
  // Provider-internal disposals are wired through `ref.onDispose` in
  // `lib/providers/app_providers.dart`.
  runApp(const ProviderScope(child: App()));
}
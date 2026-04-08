import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'widgets/main_shell.dart';

class AlfalApp extends ConsumerWidget {
  const AlfalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // High-level Auth Guard: Rebuilds root only on user changes
    final user = ref.watch(authProvider.select((s) => s.user));

    return MaterialApp(
      title: 'ALFAL',
      debugShowCheckedModeBanner: false,
      theme: ATheme.dark,
      // Switching between top-level flows: Authentication vs Dashboard
      home: user == null 
          ? const LoginScreen() 
          : const MainShell(),
    );
  }
}

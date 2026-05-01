import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'services/audio_handler.dart';
import 'widgets/main_shell.dart';

// Re-export for backward compatibility
export 'services/audio_handler.dart' show AlfalAudioHandler;

// Global instance untuk audio handler (tanpa AudioService)
late AlfalAudioHandler audioHandler;

class MusicApp extends ConsumerStatefulWidget {
  const MusicApp({super.key});

  @override
  ConsumerState<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends ConsumerState<MusicApp> {
  bool _isReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initAudioService();
  }

  Future<void> _initAudioService() async {
    // Inisialisasi audio handler tanpa AudioService
    try {
      // Request notification permission safely when app starts
      await Permission.notification.request();
      
      audioHandler = AlfalAudioHandler();
      setState(() => _isReady = true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while initializing audio
    if (!_isReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ATheme.dark,
        home: const Scaffold(
          backgroundColor: Color(0xFF030308),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
          ),
        ),
      );
    }

    // Show error if audio service failed
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ATheme.dark,
        home: Scaffold(
          backgroundColor: const Color(0xFF030308),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Audio Error: $_error', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      );
    }

    // High-level Auth Guard: Rebuilds root only on user changes
    final user = ref.watch(authProvider.select((s) => s.user));

    return MaterialApp(
      title: 'Music',
      debugShowCheckedModeBanner: false,
      theme: ATheme.dark,
      // Switching between top-level flows: Authentication vs Dashboard
      home: user == null 
          ? const LoginScreen() 
          : const MainShell(),
    );
  }
}

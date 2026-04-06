import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'player_provider.dart';

// ── Auth State ───────────────────────────────────────────────
// ── Auth State ───────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) =>
      AuthState(
        user: clearUser ? null : user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

// ── Auth Notifier ─────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final AuthService _service = AuthService();

  AuthNotifier(this._ref) : super(const AuthState()) {
    _init();
  }

  void _init() {
    // Supabase handles session persistence automatically.
    // We check if a session already exists from the previous run.
    final currentUser = _service.currentUser;
    if (currentUser != null) {
      // User is already logged in, show MainShell immediately
      state = state.copyWith(user: currentUser, isLoading: false);
      // Refresh full profile (username, avatar) in background
      _refreshProfile(currentUser.id);
    } else {
      // No session found, default to guest so app.dart shows MainShell immediately
      continueAsGuest();
    }
  }

  Future<void> _refreshProfile(String id) async {
    try {
      final freshUser = await _service.getProfile(id);
      state = state.copyWith(user: freshUser);
    } catch (_) {}
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _service.login(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> register(String email, String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _service.register(email, username, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> updateProfile({String? username, String? avatarUrl}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _service.updateProfile(
        username: username,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> logout() async {
    // 1. Instant feedback: switch to guest state
    continueAsGuest();

    // 2. Stop music without awaiting (no reason to wait for UI update)
    _ref.read(playerProvider.notifier).stop();

    // 3. Clear backend session in background (non-blocking)
    // We don't await this so the UI can jump to Home immediately.
    _service.logout().catchError((_) {});
  }

  void continueAsGuest() {
    state = state.copyWith(
      user: const UserModel(
        id: 'guest_id',
        email: 'guest@alfal.local',
        username: 'Guest Explorer',
        role: 'guest',
      ),
      isLoading: false,
      clearError: true,
    );
  }

  String _parseError(Object e) {
    final str = e.toString().toLowerCase();
    if (str.contains('invalid login credentials')) return 'Email atau password salah.';
    if (str.contains('user already registered')) return 'Email sudah terdaftar.';
    if (str.contains('network') || str.contains('socketexception')) {
      return 'Masalah koneksi. Periksa internet Anda.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

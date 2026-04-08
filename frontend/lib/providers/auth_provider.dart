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
      state = state.copyWith(user: currentUser, isLoading: false);
      _refreshProfile(currentUser.id);
    } else {
      // Start with null user to force LoginScreen as per new design
      state = state.copyWith(user: null, isLoading: false);
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
      await _service.register(email, username, password);
      // After register, session is cleared (ghost session fix).
      // User must verify OTP — keep state as null (unauthenticated).
      // SignupScreen will navigate to VerifyOTPScreen.
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> verifyOTP(String email, String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _service.verifyOTP(email, token);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<void> resendOTP(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.resendOTP(email);
      state = state.copyWith(isLoading: false);
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
    await _service.logout();
    state = const AuthState(user: null, isLoading: false);
    _ref.read(playerProvider.notifier).stop();
  }

  void continueAsGuest() {
    state = const AuthState(
      user: UserModel(
        id: 'guest_primary',
        email: 'guest@alfal.app',
        username: 'Guest User',
        role: 'guest',
      ),
      isLoading: false,
    );
  }

  String _parseError(Object e) {
    final str = e.toString().toLowerCase();
    if (str.contains('invalid login credentials')) return 'Email atau password salah.';
    if (str.contains('user already registered')) return 'Email sudah terdaftar.';
    if (str.contains('email not confirmed')) return 'Email belum diverifikasi. Silakan masukkan kode OTP dari email Anda.';
    if (str.contains('rate limit') || str.contains('over_email_send_rate_limit') || str.contains('429')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa menit lalu coba lagi.';
    }
    if (str.contains('otp_expired') || str.contains('token has expired')) {
      return 'Kode OTP sudah kadaluarsa. Klik "Resend" untuk mendapatkan kode baru.';
    }
    if (str.contains('network') || str.contains('socketexception')) {
      return 'Masalah koneksi. Periksa internet Anda.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

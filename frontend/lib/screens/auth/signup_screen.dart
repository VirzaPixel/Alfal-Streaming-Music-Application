import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/a_text_field.dart';
import 'login_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _done = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || username.isEmpty || password.isEmpty) return;

    await ref.read(authProvider.notifier).register(email, username, password);
    if (mounted && ref.read(authProvider).error == null) {
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -size.height * 0.15,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AColors.primary.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.12,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: 400.ms,
              child: _done ? _buildSuccess() : _buildForm(auth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AuthState auth) {
    return Positioned.fill(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glass Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset('assets/logo/alfal_logo.png',
                                  fit: BoxFit.cover),
                            ),
                          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 24),
                          Text(
                            'Create Account',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ).animate().fadeIn(delay: 100.ms),
                          const SizedBox(height: 6),
                          Text(
                            'Join the ALFAL Music community',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 14),
                          ).animate().fadeIn(delay: 150.ms),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    ATextField(
                      label: 'Email',
                      hint: 'name@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icon(Icons.email_outlined,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.3)),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    ATextField(
                      label: 'Username',
                      hint: 'Public name',
                      controller: _userCtrl,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icon(Icons.person_outline_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.3)),
                    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    ATextField(
                      label: 'Password',
                      hint: 'At least 8 chars',
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icon(Icons.lock_outline_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.3)),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                    if (auth.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AColors.error.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AColors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(auth.error!,
                                  style: GoogleFonts.outfit(color: AColors.error, fontSize: 13)),
                            ),
                          ],
                        ),
                      ).animate().shake(),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text('Sign Up',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
                    children: const [
                      TextSpan(text: 'Already have an account?  '),
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(color: AColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      key: const ValueKey('success'),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.mark_email_unread_rounded,
                  color: Color(0xFF10B981), size: 48),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 36),

            Text(
              'Check Your Email! 📬',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We sent a verification link to your email. Click it before you can sign in.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: Colors.white38, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 44),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: Text('Go to Login',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/a_text_field.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;
    await ref.read(authProvider.notifier).login(email, pass);
    // Routing is now handled in app.dart by watching authProvider,
    // so we don't need Navigator.pop here.
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AColors.bg,
      body: Stack(
        children: [
          // Background gradient blobs
          Positioned(
            top: -size.height * 0.15,
            left: -size.width * 0.3,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AColors.primary.withValues(alpha: 0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            right: -size.width * 0.2,
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

          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glass Card Container
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05)),
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
                          // Header
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
                                    child: Image.asset(
                                      'assets/logo/alfal_logo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                                const SizedBox(height: 24),
                                Text(
                                  'Sign In',
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ).animate().fadeIn(delay: 100.ms),
                                const SizedBox(height: 6),
                                Text(
                                  'Welcome back to ALFAL Music',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white38,
                                    fontSize: 14,
                                  ),
                                ).animate().fadeIn(delay: 150.ms),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Form
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
                            label: 'Password',
                            hint: '••••••••',
                            controller: _passCtrl,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icon(Icons.lock_outline_rounded,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.3)),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscure = !_obscure),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),

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
                                  const Icon(Icons.error_outline_rounded,
                                      color: AColors.error, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(auth.error!,
                                        style: GoogleFonts.outfit(
                                            color: AColors.error, fontSize: 13)),
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
                              onPressed: auth.isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text('Sign In',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                            ),
                          ).animate().fadeIn(delay: 300.ms),

                          const SizedBox(height: 24),
                          
                          // Guest mode - Moved up as requested
                          Center(
                            child: TextButton(
                              onPressed: () => ref.read(authProvider.notifier).continueAsGuest(),
                              child: Text(
                                'Continue as Guest',
                                style: GoogleFonts.outfit(
                                  color: Colors.white60,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 350.ms),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
                          children: const [
                            TextSpan(text: "Don't have an account?  "),
                            TextSpan(
                              text: 'Sign Up now',
                              style: TextStyle(color: AColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    
                    const SizedBox(height: 48),
                    
                    Text(
                      'DEVELOPED BY VIRZA',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.15),
                        letterSpacing: 3,
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

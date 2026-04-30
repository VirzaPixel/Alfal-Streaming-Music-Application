import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/a_text_field.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/main_shell.dart';
import 'signup_screen.dart';
import 'verify_otp_screen.dart';

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

    // After login attempt, check if we need verification
    if (!mounted) return;
    final authState = ref.read(authProvider);
    
    if (authState.error != null && authState.error!.contains('belum diverifikasi')) {
      // Trigger resend and go to OTP screen
      await ref.read(authProvider.notifier).resendOTP(email);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyOTPScreen(email: email),
          ),
        );
      }
    }
  }

  void _navigateToShell() {
    // Reset tab to Home so user always lands on Home after login
    ref.read(shellTabProvider.notifier).state = TabType.home;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // ✅ Auto-navigate when login/guest succeeds
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null) {
        _navigateToShell();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: AAnimatedBackground()),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  Text(
                    'Sign In.',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 12),
                  Text(
                    'Enter your credentials to access your global music library.',
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 80),

                  AGlass(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        ATextField(
                          label: 'EMAIL ADDRESS',
                          hint: 'email@domain.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        ATextField(
                          label: 'PASSWORD',
                          hint: '••••••••',
                          controller: _passCtrl,
                          obscureText: _obscure,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscure = !_obscure),
                            child: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: Colors.white54,
                            ),
                          ),
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

                        if (auth.error != null) ...[
                          const SizedBox(height: 24),
                          Text(
                            auth.error!,
                            style: GoogleFonts.outfit(color: AColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                          ).animate().shake(),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: auth.isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              'CONTINUE',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 700.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

                  const SizedBox(height: 48),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
                          children: const [
                            TextSpan(text: "New here? "),
                            TextSpan(
                              text: 'Register Account',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 900.ms),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

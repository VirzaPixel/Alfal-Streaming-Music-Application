import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/a_text_field.dart';
import 'login_screen.dart';
import 'verify_otp_screen.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _isBusy = false;

  Future<void> _register() async {
    if (_isBusy) return;
    
    final email = _emailCtrl.text.trim().toLowerCase();
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;
    
    if (email.isEmpty || username.isEmpty || password.isEmpty) return;

    setState(() => _isBusy = true);
    
    try {
      await ref.read(authProvider.notifier).register(email, username, password);

      if (!mounted) return;
      final authState = ref.read(authProvider);
      
      if (authState.error != null) {
        setState(() => _isBusy = false);
        return;
      }

      if (authState.user == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyOTPScreen(email: email),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.isLoading || _isBusy;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  Text(
                    'Register.',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 12),
                  Text(
                    'Create your unique identity in ALFAL to start discovering music.',
                    style: GoogleFonts.outfit(
                      color: Colors.white24,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 70),

                  ATextField(
                    label: 'PUBLIC USERNAME',
                    hint: 'e.g. virza',
                    controller: _userCtrl,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 32),

                  ATextField(
                    label: 'EMAIL ADDRESS',
                    hint: 'email@domain.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  ATextField(
                    label: 'PASSWORD',
                    hint: 'min 8 characters',
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscure = !_obscure),
                      child: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: Colors.white24,
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

                  const SizedBox(height: 64),

                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              'CREATE ACCOUNT',
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
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
                          children: const [
                            TextSpan(text: "Already a member? "),
                            TextSpan(
                              text: 'Sign In here',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
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

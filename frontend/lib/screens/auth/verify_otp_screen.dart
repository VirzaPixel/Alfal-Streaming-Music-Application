import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/a_text_field.dart';
import '../../widgets/main_shell.dart';

class VerifyOTPScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyOTPScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends ConsumerState<VerifyOTPScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear any error from previous screen (e.g., resendOTP rate limit)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length < 6 || code.length > 8) return;
    
    try {
      await ref.read(authProvider.notifier).verifyOTP(widget.email, code);
      // Check if verification actually succeeded
      // Ensure we just rely on the router/listen behavior
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // ✅ Listen for successful verification → navigate to Dashboard
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Text(
              'Verification',
              style: GoogleFonts.outfit(
                fontSize: 42,
                fontWeight: FontWeight.w200, // Light and elegant
                color: Colors.white,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A verification code has been sent to\n${widget.email}',
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.white38,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 80),
            ATextField(
              label: 'Verification Code',
              hint: '00000000',
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 8,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              // Accept 6-8 digits (Supabase OTP length varies by project settings
              style: GoogleFonts.outfit(
                fontSize: 32,
                letterSpacing: 12,
                fontWeight: FontWeight.bold,
                color: AColors.primary,
              ),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 20),
              Text(
                auth.error!,
                style: const TextStyle(color: AColors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : Text(
                        'CONFIRM CODE',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 2,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: _ResendButton(email: widget.email),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResendButton extends ConsumerStatefulWidget {
  final String email;
  const _ResendButton({required this.email});

  @override
  ConsumerState<_ResendButton> createState() => _ResendButtonState();
}

class _ResendButtonState extends ConsumerState<_ResendButton> {
  int _secondsRemaining = 0;
  Timer? _timer;

  void _startTimer() {
    setState(() => _secondsRemaining = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return TextButton(
      onPressed: (auth.isLoading || _secondsRemaining > 0)
          ? null
          : () async {
              await ref.read(authProvider.notifier).resendOTP(widget.email);
              if (mounted) {
                final error = ref.read(authProvider).error;
                if (error == null) {
                  _startTimer();
                } else {
                  // If it's a rate limit error, start timer anyway to prevent spamming
                  if (error.contains('Wait') || error.contains('Tunggu')) {
                    _startTimer();
                  }
                }
              }
            },
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
          children: [
            const TextSpan(text: "Didn't receive code? "),
            TextSpan(
              text: _secondsRemaining > 0 
                  ? 'Wait ${_secondsRemaining}s' 
                  : 'Resend',
              style: TextStyle(
                  color: (auth.isLoading || _secondsRemaining > 0) 
                      ? Colors.white10 
                      : AColors.primary, 
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

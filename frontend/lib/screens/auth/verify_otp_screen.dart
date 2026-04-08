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

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length < 6 || code.length > 8) return;
    
    try {
      await ref.read(authProvider.notifier).verifyOTP(widget.email, code);
      // Check if verification actually succeeded
      if (mounted) {
        final user = ref.read(authProvider).user;
        if (user != null) {
          // Success - nav is handled by ref.listen, but show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Verified! Redirecting...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Something went wrong silently
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Verification failed silently. Check console.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // ✅ Listen for successful verification → navigate to Dashboard
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null && next.user?.isGuest != true) {
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
              child: TextButton(
                onPressed: auth.isLoading 
                    ? null 
                    : () async {
                        await ref.read(authProvider.notifier).resendOTP(widget.email);
                        if (mounted && ref.read(authProvider).error == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('A fresh code has been sent! Check your newest email.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
                    children: [
                      const TextSpan(text: "Didn't receive code? "),
                      TextSpan(
                        text: 'Resend',
                        style: TextStyle(
                            color: auth.isLoading ? Colors.white10 : AColors.primary, 
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

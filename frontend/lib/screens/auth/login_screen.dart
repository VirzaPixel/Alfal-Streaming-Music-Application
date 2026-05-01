import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/main_shell.dart';
import 'signup_screen.dart';
import 'verify_otp_screen.dart';

class _Y2K {
  static const bg       = Color(0xFF010103);
  static const surface  = Color(0xFF08080C);
  static const lime     = Color(0xFFCCFF00);
  static const cyan     = Color(0xFF00FFFF);
  static const pink     = Color(0xFFFF00FF);
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;
  bool _btnPressed = false;

  late AnimationController _scanlineCtrl;
  late AnimationController _glitchCtrl;

  @override
  void initState() {
    super.initState();
    _scanlineCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _glitchCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _triggerGlitch();
  }

  void _triggerGlitch() async {
    while (mounted) {
      await Future.delayed(Duration(seconds: 4 + Random().nextInt(4)));
      if (!mounted) break;
      await _glitchCtrl.forward();
      await Future.delayed(80.ms);
      _glitchCtrl.reverse();
    }
  }

  void _showPixelToast(String message, {bool isError = true}) {
    _PixelToast.show(context, message, isError: isError);
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose();
    _scanlineCtrl.dispose(); _glitchCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;

    if (email.isEmpty) {
      _showPixelToast('Please enter your email address!');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showPixelToast('That email format looks a bit off...');
      return;
    }
    if (pass.isEmpty) {
      _showPixelToast('Don\'t forget your password!');
      return;
    }

    await ref.read(authProvider.notifier).login(email, pass);
    if (!mounted) return;
    final authState = ref.read(authProvider);
    
    if (authState.error != null) {
      if (authState.error!.contains('belum diverifikasi')) {
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyOTPScreen(email: email)));
      } else {
        _showPixelToast('Access Denied: ${authState.error!}');
      }
    } else {
      _showPixelToast('Welcome back! Access granted', isError: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.user != null) {
        ref.read(shellTabProvider.notifier).state = TabType.home;
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (route) => false);
      }
    });

    return Scaffold(
      backgroundColor: _Y2K.bg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _DeepGridPainter()))),
          _DecorativeStreams(),
          Positioned.fill(child: RepaintBoundary(child: _ScanlineOverlay(controller: _scanlineCtrl))),
          _CornerDecorations(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _PixelBox(
                        child: Text('ALFAL', style: GoogleFonts.silkscreen(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        borderColor: _Y2K.lime,
                        shadowColor: _Y2K.lime,
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      _GlitchHeading(text: 'LOGIN', glitchCtrl: _glitchCtrl),
                      const Spacer(),
                      _MiniVisualizer(),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 10),
                  Container(height: 3, width: 60, color: _Y2K.cyan)
                      .animate().fadeIn(delay: 250.ms).scaleX(begin: 0, alignment: Alignment.centerLeft),

                  const Spacer(flex: 2),

                  _PixelInput(
                    label: 'Email',
                    controller: _emailCtrl,
                    hint: 'ENTER EMAIL...',
                    accentColor: _Y2K.cyan,
                    icon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideX(begin: 0.05),

                  const SizedBox(height: 32),

                  _PixelInput(
                    label: 'Password',
                    controller: _passCtrl,
                    hint: 'ENTER PASSWORD...',
                    accentColor: _Y2K.pink,
                    icon: Icons.lock_open,
                    isPassword: true,
                    obscure: _obscure,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideX(begin: 0.05),


                  const Spacer(flex: 3),

                  GestureDetector(
                    onTapDown: (_) => setState(() => _btnPressed = true),
                    onTapUp: (_) => setState(() => _btnPressed = false),
                    onTapCancel: () => setState(() => _btnPressed = false),
                    onTap: auth.isLoading ? null : _login,
                    child: AnimatedScale(
                      scale: _btnPressed ? 0.96 : 1.0,
                      duration: 100.ms,
                      child: AnimatedContainer(
                        duration: 150.ms,
                        curve: Curves.easeOut,
                        transform: Matrix4.translationValues(_btnPressed ? 3 : 0, _btnPressed ? 3 : 0, 0),
                        height: 68,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _Y2K.lime,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: _btnPressed ? [] : [
                            const BoxShadow(color: _Y2K.pink, offset: Offset(6, 6)),
                            const BoxShadow(color: _Y2K.cyan, offset: Offset(-2, -2)),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: auth.isLoading
                            ? const CircularProgressIndicator(strokeWidth: 4, color: Colors.black)
                            : Text('CONTINUE',
                                style: GoogleFonts.silkscreen(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms, duration: 400.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),

                  const SizedBox(height: 32),

                  Center(
                    child: _PixelLink(label: 'CREATE_ACCOUNT', target: const SignupScreen()),
                  ).animate().fadeIn(delay: 850.ms, duration: 600.ms),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PixelBox extends StatelessWidget {
  final Widget child; final Color borderColor; final Color shadowColor;
  const _PixelBox({required this.child, required this.borderColor, required this.shadowColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(border: Border.all(color: borderColor, width: 2), boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(3, 3))]),
    child: child,
  );
}

class _GlitchHeading extends StatelessWidget {
  final String text; final AnimationController glitchCtrl;
  const _GlitchHeading({required this.text, required this.glitchCtrl});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: glitchCtrl,
    builder: (_, __) => Text(text, style: GoogleFonts.silkscreen(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, shadows: [
      if (glitchCtrl.value > 0.5) Shadow(color: _Y2K.pink, offset: const Offset(4, 0)),
      if (glitchCtrl.value > 0.5) Shadow(color: _Y2K.cyan, offset: const Offset(-4, 0)),
    ])),
  );
}

class _MiniVisualizer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(4, (i) => Container(
      margin: const EdgeInsets.only(left: 4),
      width: 4, height: 12 + (i * 3),
      color: _Y2K.cyan,
    )).animate(onPlay: (c) => c.repeat(reverse: true)).scaleY(begin: 0.5, end: 1.2, duration: 400.ms),
  );
}

class _PixelInput extends StatelessWidget {
  final String label; final TextEditingController controller; final String hint; final IconData icon; final Color accentColor;
  final bool isPassword; final bool obscure; final VoidCallback? onToggleObscure; final TextInputType? keyboardType;

  const _PixelInput({required this.label, required this.controller, required this.hint, required this.icon, required this.accentColor, this.isPassword = false, this.obscure = false, this.onToggleObscure, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: accentColor,
          selectionColor: accentColor.withOpacity(0.3),
          selectionHandleColor: accentColor,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          border: InputBorder.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 6, height: 6, color: accentColor),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.silkscreen(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const Expanded(child: Divider(color: Colors.white10, indent: 10, thickness: 1)),
          ]),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: 250.ms,
            decoration: BoxDecoration(color: _Y2K.surface, border: Border.all(color: accentColor, width: 2), boxShadow: [BoxShadow(color: accentColor, offset: const Offset(3, 3))]),
            child: Row(children: [
              const SizedBox(width: 16),
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 18),
              Expanded(
                child: TextField(
                  controller: controller, obscureText: obscure, keyboardType: keyboardType,
                  style: GoogleFonts.vt323(color: Colors.white, fontSize: 24, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                  cursorColor: accentColor, cursorWidth: 3,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.vt323(color: Colors.white10, fontSize: 20),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    suffixIcon: isPassword ? GestureDetector(onTap: onToggleObscure, child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: accentColor, size: 20)) : null,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _PixelToast {
  static void show(BuildContext context, String message, {bool isError = true}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _PixelToastWidget(message: message, isError: isError),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }
}

class _PixelToastWidget extends StatelessWidget {
  final String message; final bool isError;
  const _PixelToastWidget({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20, right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isError ? _Y2K.pink : _Y2K.lime,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(color: isError ? _Y2K.cyan : _Y2K.pink, offset: const Offset(4, 4)),
            ],
          ),
          child: Row(
            children: [
              Icon(isError ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, color: isError ? Colors.white : Colors.black, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: GoogleFonts.silkscreen(color: isError ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOutBack).shake(delay: 400.ms, hz: 4),
    );
  }
}


class _PixelLink extends StatelessWidget {
  final String label; final Widget? target;
  const _PixelLink({required this.label, this.target});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: target != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => target!)) : null,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: _Y2K.cyan, width: 1), color: _Y2K.cyan.withOpacity(0.05)),
        child: Text('[ $label ]', style: GoogleFonts.silkscreen(color: _Y2K.cyan, fontSize: 10, fontWeight: FontWeight.bold)),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(delay: 2.seconds, duration: 2.seconds),
    ),
  );
}

class _DecorativeStreams extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(children: [
    Positioned(top: 100, left: -20, child: _StreamLine(color: _Y2K.pink.withOpacity(0.1))),
    Positioned(top: 400, right: -20, child: _StreamLine(color: _Y2K.cyan.withOpacity(0.1))),
  ]);
}

class _StreamLine extends StatelessWidget {
  final Color color;
  const _StreamLine({required this.color});
  @override
  Widget build(BuildContext context) => Container(width: 250, height: 2, color: color).animate(onPlay: (c) => c.repeat()).slideX(begin: -1, end: 1, duration: 3.seconds);
}

class _CornerDecorations extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned.fill(child: IgnorePointer(
    child: Stack(children: [
      Positioned(top: 40, right: 20, child: Text('LOC: 42.12', style: GoogleFonts.vt323(color: Colors.white10, fontSize: 11, fontWeight: FontWeight.bold))),
      Positioned(bottom: 40, left: 20, child: Text('STABILITY: 0.98', style: GoogleFonts.vt323(color: Colors.white10, fontSize: 11, fontWeight: FontWeight.bold))),
    ]),
  ));
}

class _DeepGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.04)..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 40) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), p); }
    for (double y = 0; y < size.height; y += 40) { canvas.drawLine(Offset(0, y), Offset(size.width, y), p); }
  }
  @override bool shouldRepaint(_DeepGridPainter _) => false;
}

class _ScanlineOverlay extends StatelessWidget {
  final AnimationController controller;
  const _ScanlineOverlay({required this.controller});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, __) => CustomPaint(painter: _ScanlinePainter(controller.value)),
  );
}

class _ScanlinePainter extends CustomPainter {
  final double progress; _ScanlinePainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.015);
    for (double y = 0; y < size.height; y += 5) { canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), p); }
    final sy = size.height * progress;
    canvas.drawRect(Rect.fromLTWH(0, sy, size.width, 3), Paint()..color = Colors.white.withOpacity(0.08));
  }
  @override bool shouldRepaint(_ScanlinePainter old) => old.progress != progress;
}

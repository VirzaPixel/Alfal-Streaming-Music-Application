import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import 'verify_otp_screen.dart';

class _Y2K {
  static const bg       = Color(0xFF010103);
  static const surface  = Color(0xFF08080C);
  static const lime     = Color(0xFFCCFF00);
  static const cyan     = Color(0xFF00FFFF);
  static const pink     = Color(0xFFFF00FF);
  static const white30  = Color(0x33FFFFFF);
  static const white10  = Color(0x1AFFFFFF);
}

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> with TickerProviderStateMixin {
  final _userCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;
  bool _isBusy     = false;
  bool _btnPressed = false;

  late AnimationController _scanCtrl;
  late AnimationController _progressCtrl;

  int get _filledCount => [_userCtrl.text.isNotEmpty, _emailCtrl.text.isNotEmpty, _passCtrl.text.isNotEmpty].where((e) => e).length;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: 4.seconds)..repeat();
    _progressCtrl = AnimationController(vsync: this, duration: 600.ms);
    _userCtrl.addListener(_onFieldChange);
    _emailCtrl.addListener(_onFieldChange);
    _passCtrl.addListener(_onFieldChange);
  }

  void _onFieldChange() {
    setState(() {});
    _progressCtrl.animateTo(_filledCount / 3, duration: 400.ms, curve: Curves.easeOut);
  }

  void _showPixelToast(String message, {bool isError = true}) {
    _PixelToast.show(context, message, isError: isError);
  }

  @override
  void dispose() {
    _userCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    _scanCtrl.dispose(); _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_isBusy) return;
    final email = _emailCtrl.text.trim().toLowerCase();
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;

    if (username.length < 3) {
      _showPixelToast('Username must be at least 3 characters!');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showPixelToast('Please check your email format!');
      return;
    }
    if (password.length < 6) {
      _showPixelToast('Password must be at least 6 characters!');
      return;
    }

    setState(() => _isBusy = true);
    try {
      await ref.read(authProvider.notifier).register(email, username, password);
      if (!mounted) return;
      
      final authState = ref.read(authProvider);
      
      // If there's an error in state but it didn't throw (like user already registered handling)
      if (authState.error != null) { 
        _showPixelToast('Oops! ${authState.error!}');
        setState(() => _isBusy = false); 
        return; 
      }

      // If successful and needs verification
      if (authState.user == null) {
        _showPixelToast('Got it! Check your email for the code', isError: false);
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyOTPScreen(email: email)));
      }
    } catch (e) { 
      if (mounted) {
        final authError = ref.read(authProvider).error;
        _showPixelToast(authError ?? 'Connection error, please try again');
      }
    }
    finally { if (mounted) setState(() => _isBusy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.isLoading || _isBusy;

    return Scaffold(
      backgroundColor: _Y2K.bg,
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _DeepGridPainter()))),
        _DecorativeStreams(),
        Positioned.fill(child: RepaintBoundary(child: _ScanlineOverlay(controller: _scanCtrl))),
        _CornerDecorations(),
        
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── NAVIGATION & STATUS ──
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48, width: 48,
                      decoration: BoxDecoration(
                        color: _Y2K.surface,
                        border: Border.all(color: _Y2K.pink, width: 2.5),
                        boxShadow: const [BoxShadow(color: _Y2K.pink, offset: Offset(4, 4))],
                      ),
                      child: const Icon(Icons.arrow_back, color: _Y2K.pink, size: 24),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                  const Spacer(),
                  _MiniMapDecoration().animate().fadeIn(delay: 150.ms).slideX(begin: 1, end: 0, curve: Curves.easeOut),
                ]),

                const SizedBox(height: 16),
                _BrandedHeading(text: 'New Here ?')
                    .animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: -0.2),
                
                const SizedBox(height: 12),
                _DetailedProgress(progress: _progressCtrl, count: _filledCount)
                    .animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 32),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(text: 'USERNAME', color: _Y2K.lime),
                        const SizedBox(height: 8),
                        _PixelInput(
                          controller: _userCtrl,
                          hint: 'Tell Me Your Name...',
                          icon: Icons.person_add_alt_1_rounded,
                          color: _Y2K.lime,
                        ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.05),

                        const SizedBox(height: 24),
                        _FieldLabel(text: 'EMAIL', color: _Y2K.cyan),
                        const SizedBox(height: 8),
                        _PixelInput(
                          controller: _emailCtrl,
                          hint: 'Your Email pls...',
                          icon: Icons.email_outlined,
                          color: _Y2K.cyan,
                          keyboardType: TextInputType.emailAddress,
                        ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.05),

                        const SizedBox(height: 24),
                        _FieldLabel(text: 'PASSWORD', color: _Y2K.pink),
                        const SizedBox(height: 8),
                        _PixelInput(
                          controller: _passCtrl,
                          hint: 'Make It Strong y...',
                          icon: Icons.lock_outline_rounded,
                          color: _Y2K.pink,
                          isPassword: true,
                          obscure: _obscure,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                        ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.05),
                        
                        const SizedBox(height: 40),
                        
                        GestureDetector(
                          onTapDown: (_) => setState(() => _btnPressed = true),
                          onTapUp: (_) => setState(() => _btnPressed = false),
                          onTapCancel: () => setState(() => _btnPressed = false),
                          onTap: isLoading ? null : _register,
                          child: AnimatedScale(
                            scale: _btnPressed ? 0.96 : 1.0,
                            duration: 100.ms,
                            child: AnimatedContainer(
                              duration: 150.ms,
                              curve: Curves.easeOut,
                              transform: Matrix4.translationValues(_btnPressed ? 3 : 0, _btnPressed ? 3 : 0, 0),
                              height: 68, width: double.infinity,
                              decoration: BoxDecoration(
                                color: _Y2K.pink,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: _btnPressed ? [] : const [
                                  BoxShadow(color: _Y2K.cyan, offset: Offset(6, 6)),
                                  BoxShadow(color: _Y2K.lime, offset: Offset(-2, -2)),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: isLoading
                                  ? const CircularProgressIndicator(strokeWidth: 4, color: Colors.white)
                                  : Text('CONTINUE', style: GoogleFonts.silkscreen(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 2)),
                            ),
                          ),
                        ).animate().fadeIn(delay: 750.ms, duration: 400.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),

                        const SizedBox(height: 32),
                        Center(child: _PixelLink(label: 'RETURN_TO_LOGIN', target: null))
                            .animate().fadeIn(delay: 900.ms),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _BrandedHeading extends StatelessWidget {
  final String text;
  const _BrandedHeading({required this.text});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 8, height: 36, color: _Y2K.pink)
          .animate().scaleY(begin: 0, duration: 600.ms, curve: Curves.easeOutBack),
      const SizedBox(width: 14),
      Text(text, style: GoogleFonts.silkscreen(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
    ],
  );
}

class _PixelInput extends StatelessWidget {
  final TextEditingController controller; final String hint; final IconData icon; final Color color; 
  final bool isPassword; final bool obscure; final VoidCallback? onToggleObscure; final TextInputType? keyboardType;
  
  const _PixelInput({
    required this.controller, required this.hint, required this.icon, required this.color, 
    this.isPassword = false, this.obscure = false, this.onToggleObscure, this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: color,
        selectionColor: color.withOpacity(0.3),
        selectionHandleColor: color,
      ),
      // Fix for the purple box/outline on some devices
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        border: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
      ),
    ),
    child: Container(
      height: 64,
      decoration: BoxDecoration(
        color: _Y2K.surface,
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: color, offset: const Offset(4, 4))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.vt323(color: Colors.white, fontSize: 20, letterSpacing: 1),
        cursorColor: color,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: color, size: 22),
          hintText: hint,
          hintStyle: GoogleFonts.vt323(color: Colors.white.withOpacity(0.15), fontSize: 20),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          suffixIcon: isPassword ? GestureDetector(onTap: onToggleObscure, child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: color, size: 20)) : null,
        ),
      ),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text; final Color color;
  const _FieldLabel({required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 6, height: 6, color: color),
    const SizedBox(width: 8),
    Text(text, style: GoogleFonts.silkscreen(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    const Expanded(child: Divider(color: _Y2K.white10, indent: 10, thickness: 1)),
  ]);
}

class _DetailedProgress extends StatelessWidget {
  final AnimationController progress; final int count;
  const _DetailedProgress({required this.progress, required this.count});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: _Y2K.surface, border: Border.all(color: _Y2K.white10, width: 1.5)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Register Status', style: GoogleFonts.silkscreen(color: _Y2K.white30, fontSize: 9, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('STEP_$count / 3', style: GoogleFonts.vt323(color: count == 3 ? _Y2K.lime : _Y2K.pink, fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        AnimatedBuilder(animation: progress, builder: (_, __) => LinearProgressIndicator(value: progress.value, backgroundColor: _Y2K.bg, color: count == 3 ? _Y2K.lime : _Y2K.pink, minHeight: 4)),
      ],
    ),
  );
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
              Icon(isError ? Icons.warning_amber_rounded : Icons.terminal_outlined, color: isError ? Colors.white : Colors.black, size: 24),
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


class _MiniMapDecoration extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 60, height: 36,
    decoration: BoxDecoration(border: Border.all(color: _Y2K.white10, width: 1)),
    child: Stack(children: [
      Positioned(left: 10, top: 10, child: Container(width: 5, height: 5, color: _Y2K.cyan)),
      Positioned(right: 15, bottom: 6, child: Container(width: 5, height: 5, color: _Y2K.lime)),
    ]),
  );
}

class _PixelLink extends StatelessWidget {
  final String label; final Widget? target;
  const _PixelLink({required this.label, this.target});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: target != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => target!)) : Navigator.of(context).pop,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: _Y2K.white30, width: 1), color: _Y2K.white30.withOpacity(0.05)),
      child: Text('[ $label ]', style: GoogleFonts.silkscreen(color: _Y2K.white30, fontSize: 10, fontWeight: FontWeight.bold)),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(delay: 3.seconds, duration: 2.seconds),
  );
}

class _DecorativeStreams extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(children: [
    Positioned(top: 250, right: -60, child: Container(width: 120, height: 2, color: _Y2K.cyan.withOpacity(0.15))),
    Positioned(bottom: 100, left: -60, child: Container(width: 120, height: 2, color: _Y2K.pink.withOpacity(0.15))),
  ]);
}

class _CornerDecorations extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned.fill(child: IgnorePointer(
    child: Stack(children: [
      Positioned(top: 40, left: 20, child: Text('TRACE: ACTIVE', style: GoogleFonts.vt323(color: _Y2K.white10, fontSize: 11, fontWeight: FontWeight.bold))),
      Positioned(bottom: 40, right: 20, child: Text('SRV: ASIA_01', style: GoogleFonts.vt323(color: _Y2K.white10, fontSize: 11, fontWeight: FontWeight.bold))),
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

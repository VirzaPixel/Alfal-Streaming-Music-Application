import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/main_shell.dart';

class _Y2K {
  static const bg       = Color(0xFF010103);
  static const surface  = Color(0xFF08080C);
  static const lime     = Color(0xFFCCFF00);
  static const cyan     = Color(0xFF00FFFF);
  static const pink     = Color(0xFFFF00FF);
  static const white30  = Color(0x33FFFFFF);
}

class VerifyOTPScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyOTPScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends ConsumerState<VerifyOTPScreen> with TickerProviderStateMixin {
  final TextEditingController _otpCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isBusy = false;
  late AnimationController _scanCtrl;
  late AnimationController _cursorCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: 4.seconds)..repeat();
    _cursorCtrl = AnimationController(vsync: this, duration: 500.ms)..repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _showPixelToast(String message, {bool isError = true}) {
    _PixelToast.show(context, message, isError: isError);
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _focusNode.dispose();
    _scanCtrl.dispose();
    _cursorCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text;
    if (otp.length < 8) {
      _showPixelToast('Please enter the full 8-digit code!');
      return;
    }
    if (_isBusy) return;

    setState(() => _isBusy = true);
    try {
      await ref.read(authProvider.notifier).verifyOTP(widget.email, otp);
      if (!mounted) return;
      
      final authState = ref.read(authProvider);
      if (authState.error != null) {
        _showPixelToast('Oops! ${authState.error!}');
        return;
      }
      if (authState.user != null) {
        ref.read(shellTabProvider.notifier).state = TabType.home;
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (route) => false);
      }
    } catch (e) {
      if (mounted) {
        final authError = ref.read(authProvider).error;
        _showPixelToast(authError ?? 'Invalid or expired code. Please try again.');
      }
    } finally { if (mounted) setState(() => _isBusy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.isLoading || _isBusy;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _Y2K.bg,
      resizeToAvoidBottomInset: false, // We'll handle it manually for better control
      body: Stack(children: [
        Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _DeepGridPainter()))),
        Positioned.fill(child: RepaintBoundary(child: _ScanlineOverlay(controller: _scanCtrl))),
        
        SafeArea(
          child: AnimatedPadding(
            duration: 300.ms,
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? 10 : 0),
            child: Column(
              children: [
                // ── HEADER ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 44, width: 44,
                        decoration: BoxDecoration(
                          color: _Y2K.surface,
                          border: Border.all(color: _Y2K.cyan, width: 2),
                          boxShadow: const [BoxShadow(color: _Y2K.cyan, offset: Offset(3, 3))],
                        ),
                        child: const Icon(Icons.close, color: _Y2K.cyan, size: 24),
                      ),
                    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
                    const Spacer(),
                    _SecurityLevelTag().animate().fadeIn(delay: 150.ms),
                  ]),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        _BrandedHeading(text: 'VERIFY_IDENTITY').animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                        
                        const SizedBox(height: 12),
                        Text('CODE SENT TO: ${widget.email.toUpperCase()}', 
                          style: GoogleFonts.vt323(color: _Y2K.white30, fontSize: 14, fontWeight: FontWeight.bold))
                            .animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 60),

                        // ── 8-DIGIT OTP INPUT (Hidden Field UX) ──
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: 0,
                                child: SizedBox(
                                  width: 1, height: 1,
                                  child: TextField(
                                    controller: _otpCtrl,
                                    focusNode: _focusNode,
                                    keyboardType: TextInputType.number,
                                    maxLength: 8,
                                    autofocus: true,
                                    onChanged: (val) {
                                      if (val.length == 8) _verify();
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ),
                              
                              GestureDetector(
                                onTap: () => _focusNode.requestFocus(),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ...List.generate(4, (i) => _VisualOTPBox(
                                      digit: _otpCtrl.text.length > i ? _otpCtrl.text[i] : '',
                                      isFocused: _otpCtrl.text.length == i && _focusNode.hasFocus,
                                      cursorAnim: _cursorCtrl,
                                    )),
                                    Container(margin: const EdgeInsets.symmetric(horizontal: 8), width: 10, height: 2, color: _Y2K.cyan.withOpacity(0.3)),
                                    ...List.generate(4, (i) {
                                      final idx = i + 4;
                                      return _VisualOTPBox(
                                        digit: _otpCtrl.text.length > idx ? _otpCtrl.text[idx] : '',
                                        isFocused: _otpCtrl.text.length == idx && _focusNode.hasFocus,
                                        cursorAnim: _cursorCtrl,
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),

                        const SizedBox(height: 60),

                        // ── EXECUTE BUTTON ──
                        GestureDetector(
                          onTap: isLoading ? null : _verify,
                          child: AnimatedContainer(
                            duration: 200.ms,
                            height: 64, width: double.infinity,
                            decoration: BoxDecoration(
                              color: _Y2K.cyan,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: _Y2K.pink, offset: Offset(5, 5))],
                            ),
                            alignment: Alignment.center,
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 3)
                                : Text('Verify Now', style: GoogleFonts.silkscreen(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black, letterSpacing: 1.5)),
                          ),
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: () async {
                              _showPixelToast('Requesting new code...', isError: false);
                              await ref.read(authProvider.notifier).resendOTP(widget.email);
                            },
                            child: Text('[ Request New Code ]', style: GoogleFonts.silkscreen(color: _Y2K.lime, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ).animate().fadeIn(delay: 600.ms),
                        
                        SizedBox(height: bottomInset > 0 ? 20 : 40),
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
      Container(width: 6, height: 32, color: _Y2K.cyan),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: GoogleFonts.silkscreen(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2))),
    ],
  );
}

class _VisualOTPBox extends StatelessWidget {
  final String digit; final bool isFocused; final AnimationController cursorAnim;
  const _VisualOTPBox({required this.digit, required this.isFocused, required this.cursorAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: _Y2K.surface, 
        border: Border.all(color: isFocused ? _Y2K.lime : _Y2K.cyan.withOpacity(0.5), width: 2), 
        boxShadow: [
          if (isFocused) const BoxShadow(color: _Y2K.lime, offset: Offset(3, 3))
          else BoxShadow(color: _Y2K.cyan.withOpacity(0.2), offset: const Offset(2, 2))
        ],
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (digit.isEmpty && isFocused)
            FadeTransition(
              opacity: cursorAnim,
              child: Container(width: 14, height: 2, color: _Y2K.lime),
            ),
          Text(digit, style: GoogleFonts.vt323(color: _Y2K.lime, fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SecurityLevelTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(border: Border.all(color: _Y2K.pink, width: 1)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.security, color: _Y2K.pink, size: 12),
      const SizedBox(width: 4),
      Text('SEC_LEVEL: MAX', style: GoogleFonts.vt323(color: _Y2K.pink, fontSize: 10, fontWeight: FontWeight.bold)),
    ]),
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
            color: isError ? const Color(0xFFFF00FF) : const Color(0xFFCCFF00),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(color: isError ? const Color(0xFF00FFFF) : const Color(0xFFFF00FF), offset: const Offset(4, 4)),
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

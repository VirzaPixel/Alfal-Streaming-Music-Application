import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _particleController;
  late final AnimationController _progressController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _particleController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AColors.bg,
      body: Stack(
        children: [
          // ── Layer 1: Animated Glow Background ────────────────────
          Positioned.fill(child: _AnimatedGlowBackground(controller: _bgController, size: size)),

          // ── Layer 2: Floating Particles ───────────────────────────
          Positioned.fill(child: _FloatingParticles(controller: _particleController, size: size)),

          // ── Layer 3: Main Content ─────────────────────────────────
          Positioned.fill(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // ── Logo + Glow Pulse ──────────────────────────────
                _LogoPulse(pulseController: _pulseController),

                const SizedBox(height: 48),

                // Brand removed as requested
                const SizedBox(height: 14),

                // ── Tagline ────────────────────────────────────────
                Text(
                  'WITH GOOD MUSIC TASTE,',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: Colors.white30,
                    letterSpacing: 5,
                    fontWeight: FontWeight.w700,
                  ),
                )
                .animate()
                .fadeIn(delay: 1000.ms, duration: 800.ms),

                const SizedBox(height: 4),

                Text(
                  'COMES AN EFFORTLESS SOUL',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: Colors.white30,
                    letterSpacing: 5,
                    fontWeight: FontWeight.w700,
                  ),
                )
                .animate()
                .fadeIn(delay: 1200.ms, duration: 800.ms),

                const Spacer(flex: 2),

                // ── Progress Bar ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (_, __) {
                          return Container(
                            height: 2,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: _progressController.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: const LinearGradient(
                                      colors: [AColors.primary, AColors.primaryLight, Color(0xFF10B981)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AColors.primary.withOpacity(0.6),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms),

                      const SizedBox(height: 32),

                      Text(
                        'DEVELOPED BY VIRZA',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white12,
                          letterSpacing: 4,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 1400.ms, duration: 800.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo with Glow Pulse ──────────────────────────────────────────
class _LogoPulse extends StatelessWidget {
  final AnimationController pulseController;
  const _LogoPulse({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, child) {
        final pulseValue = pulseController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring 2
            Container(
              width: 170 + pulseValue * 20,
              height: 170 + pulseValue * 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AColors.primary.withOpacity(0.04 + pulseValue * 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Outer glow ring 1
            Container(
              width: 145 + pulseValue * 10,
              height: 145 + pulseValue * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AColors.primary.withOpacity(0.08 + pulseValue * 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Logo container
            child!,
          ],
        );
      },
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AColors.primary.withOpacity(0.35),
              blurRadius: 40,
              spreadRadius: 4,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.12),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const Center(
            child: Icon(Icons.music_note_rounded, color: Colors.white, size: 48),
          ),
        ),
      )
      .animate()
      .fadeIn(duration: 800.ms)
      .scale(
        begin: const Offset(0.4, 0.4),
        end: const Offset(1.0, 1.0),
        duration: 1000.ms,
        curve: Curves.easeOutBack,
      ),
    );
  }
}

// ── Animated Glow Background ──────────────────────────────────────
class _AnimatedGlowBackground extends StatelessWidget {
  final AnimationController controller;
  final Size size;
  const _AnimatedGlowBackground({required this.controller, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Stack(
          children: [
            Container(color: AColors.bg),
            // Top-left Indigo blob
            Positioned(
              left: -120 + math.sin(t * math.pi * 2) * 50,
              top: -80 + math.cos(t * math.pi * 2) * 60,
              child: _GlowOrb(color: AColors.primary.withOpacity(0.15), size: 500),
            ),
            // Bottom-right Violet blob
            Positioned(
              right: -80 + math.cos(t * math.pi * 2) * 40,
              bottom: -60 + math.sin(t * math.pi * 2) * 50,
              child: _GlowOrb(color: const Color(0xFF8B5CF6).withOpacity(0.10), size: 420),
            ),
            // Center Emerald subtle blob
            Positioned(
              left: size.width / 2 - 150 + math.sin(t * math.pi * 3) * 30,
              top: size.height / 2 - 100 + math.cos(t * math.pi * 3) * 25,
              child: _GlowOrb(color: const Color(0xFF10B981).withOpacity(0.05), size: 300),
            ),
            // Top-right accent
            Positioned(
              right: 40 + math.sin(t * math.pi * 2.5) * 30,
              top: 80 + math.cos(t * math.pi * 2.5) * 40,
              child: _GlowOrb(color: const Color(0xFFC026D3).withOpacity(0.06), size: 250),
            ),
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

// ── Floating Particles ────────────────────────────────────────────
class _FloatingParticles extends StatelessWidget {
  final AnimationController controller;
  final Size size;
  const _FloatingParticles({required this.controller, required this.size});

  static final List<_ParticleData> _particles = List.generate(18, (i) {
    final rng = math.Random(i * 7 + 13);
    return _ParticleData(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      radius: 1.2 + rng.nextDouble() * 2.4,
      speed: 0.3 + rng.nextDouble() * 0.7,
      phase: rng.nextDouble() * math.pi * 2,
      opacity: 0.08 + rng.nextDouble() * 0.18,
    );
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return CustomPaint(
          painter: _ParticlePainter(particles: _particles, t: t, size: size),
        );
      },
    );
  }
}

class _ParticleData {
  final double x, y, radius, speed, phase, opacity;
  const _ParticleData({
    required this.x, required this.y,
    required this.radius, required this.speed,
    required this.phase, required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_ParticleData> particles;
  final double t;
  final Size size;
  const _ParticlePainter({required this.particles, required this.t, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    for (final p in particles) {
      final dx = math.sin(t * math.pi * 2 * p.speed + p.phase) * 18;
      final dy = math.cos(t * math.pi * 2 * p.speed + p.phase * 1.3) * 22;

      final cx = p.x * canvasSize.width + dx;
      final cy = p.y * canvasSize.height + dy;

      final paint = Paint()
        ..color = AColors.primaryLight.withOpacity(p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(Offset(cx, cy), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}

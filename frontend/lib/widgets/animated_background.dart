import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme.dart';

class AAnimatedBackground extends StatefulWidget {
  const AAnimatedBackground({super.key});

  @override
  State<AAnimatedBackground> createState() => _AAnimatedBackgroundState();
}

class _AAnimatedBackgroundState extends State<AAnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        return Stack(
          children: [
            Container(color: AColors.bg),
            Positioned(
              left: -80 + math.sin(t * math.pi * 2) * 60,
              top: -100 + math.cos(t * math.pi * 2) * 50,
              child: RepaintBoundary(
                child: _GlowBlob(color: AColors.primary.withOpacity(0.12), size: 450),
              ),
            ),
            Positioned(
              right: -60 + math.cos(t * math.pi * 2) * 50,
              bottom: 100 + math.sin(t * math.pi * 2) * 60,
              child: RepaintBoundary(
                child: _GlowBlob(color: const Color(0xFF8B5CF6).withOpacity(0.08), size: 380),
              ),
            ),
            Positioned(
              left: size.width / 2 - 130 + math.sin(t * math.pi * 4) * 40,
              top: size.height / 2 - 130,
              child: RepaintBoundary(
                child: _GlowBlob(color: const Color(0xFF10B981).withOpacity(0.05), size: 260),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

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

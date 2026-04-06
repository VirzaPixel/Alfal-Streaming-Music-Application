import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AColors.primary.withValues(alpha: 0.3),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/logo/alfal_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 800.ms)
            .scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack, duration: 800.ms)
            .shimmer(delay: 1200.ms, duration: 1500.ms, color: Colors.white24),

            const SizedBox(height: 32),

            // App Name
            Text(
              'ALFAL',
              style: GoogleFonts.outfit(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 8,
              ),
            )
            .animate()
            .fadeIn(delay: 400.ms, duration: 800.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

            const SizedBox(height: 12),

            // Tagline
            Text(
              'With good music taste, comes an effortless soul',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
            )
            .animate()
            .fadeIn(delay: 800.ms, duration: 800.ms),
          ],
        ),
      ),
    );
  }
}

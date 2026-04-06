import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopNavbar extends StatelessWidget {
  final String title;
  final bool showLogo;

  const TopNavbar({
    super.key,
    this.title = 'Alfal',
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          if (showLogo) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo/alfal_logo.png',
                width: 32,
                height: 32,
                errorBuilder: (_, __, ___) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white24, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

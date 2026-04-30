import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopNavbar extends StatelessWidget {
  final String title;

  const TopNavbar({
    super.key,
    this.title = '',
  });

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.8,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

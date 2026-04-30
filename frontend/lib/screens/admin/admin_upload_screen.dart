import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import 'admin_import_screen.dart';

// Manual Upload tab removed — Magic Import (backed by Python agent) is the only method now.

class AdminUploadScreen extends ConsumerWidget {
  const AdminUploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AColors.bg,
      body: Stack(
        children: [
          // Background Aura
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AColors.primary.withOpacity(0.1),
              ),
            ),
          ).animate().fadeIn(duration: 1000.ms),

          Column(
            children: [
              _buildHeader(),
              // Magic Import langsung tanpa tab
              const Expanded(
                child: AdminImportScreen(isFragment: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Magic Import',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.2,
              ),
            ),
            Text(
              'Search & add tracks powered by Music Agent',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.white38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

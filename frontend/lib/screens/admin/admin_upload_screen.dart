import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import 'admin_import_screen.dart';
import 'admin_manual_upload_screen.dart';

class AdminUploadScreen extends ConsumerStatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  ConsumerState<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends ConsumerState<AdminUploadScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                AdminImportScreen(isFragment: true),
                AdminManualUploadScreen(isFragment: true),
              ],
            ),
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
        child: Row(
          children: [
             Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Music',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.2,
                  ),
                ),
                Text(
                  'Add new tracks to the library',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: AColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        indicatorColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: 'MAGIC IMPORT'),
          Tab(text: 'MANUAL'),
        ],
      ),
    );
  }
}

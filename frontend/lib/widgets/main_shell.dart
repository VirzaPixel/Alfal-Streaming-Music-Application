import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/playlist/playlist_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/admin/admin_upload_screen.dart';
import '../screens/admin/admin_user_management_screen.dart';
import 'animated_background.dart';
import 'mini_player.dart';

enum TabType { home, search, import, library, admin, profile }

final shellTabProvider = StateProvider<TabType>((ref) => TabType.home);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final Map<TabType, GlobalKey<NavigatorState>> _navKeys = {};

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(shellTabProvider);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final canUpload = user?.canUpload ?? false;
    final isAdmin = user?.isAdmin ?? false;
    
    final allTabs = [
      (type: TabType.home, icon: Icons.grid_view_rounded, label: 'Home', screen: const HomeScreen(), visible: true),
      (type: TabType.search, icon: Icons.search_rounded, label: 'Search', screen: const SearchScreen(), visible: true),
      (type: TabType.import, icon: Icons.auto_awesome_rounded, label: 'Import', screen: const AdminUploadScreen(), visible: canUpload),
      (type: TabType.library, icon: Icons.library_music_rounded, label: 'Library', screen: const PlaylistScreen(), visible: true),
      (type: TabType.admin, icon: Icons.admin_panel_settings_rounded, label: 'Admin', screen: const AdminUserManagementScreen(), visible: isAdmin),
      (type: TabType.profile, icon: Icons.person_rounded, label: 'Profile', screen: const ProfileScreen(), visible: true),
    ];
    
    final items = allTabs.where((t) => t.visible).toList();
    final currentTabIndex = items.indexWhere((e) => e.type == tab);
    final safeIndex = currentTabIndex != -1 ? currentTabIndex : 0;

    for (var tabType in TabType.values) {
       _navKeys.putIfAbsent(tabType, () => GlobalKey<NavigatorState>());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final tabType = ref.read(shellTabProvider);
        final NavigatorState? nav = _navKeys[tabType]?.currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (tabType != TabType.home) {
          ref.read(shellTabProvider.notifier).state = TabType.home;
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AColors.bg,
        resizeToAvoidBottomInset: false, 
        body: Stack(
          children: [
            const Positioned.fill(child: RepaintBoundary(child: AAnimatedBackground())),
            
            IndexedStack(
              index: safeIndex,
              children: items.map((e) => _buildTab(e.type, e.screen)).toList(),
            ),

            // Floating Navigation & Player Bar
            Positioned(
              left: 24,
              right: 24,
              bottom: 36, // Slightly adjusted
              child: SafeArea(
                child: RepaintBoundary(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MiniPlayer(),
                      const SizedBox(height: 16),
                      _PremiumNavBar(
                        currentIndex: safeIndex,
                        items: items.map((e) => (icon: e.icon, label: e.label)).toList(),
                        onTap: (i) {
                          final clickedType = items[i].type;
                          if (clickedType == tab) {
                            _navKeys[clickedType]?.currentState?.popUntil((r) => r.isFirst);
                          } else {
                            ref.read(shellTabProvider.notifier).state = clickedType;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(TabType type, Widget root) {
    return Navigator(
      key: _navKeys[type],
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (ctx) => Padding(
          padding: const EdgeInsets.only(bottom: 110), // Perfect fit for the NavBar height + bottom margin
          child: root,
        ),
        settings: settings,
      ),
    );
  }
}

class _PremiumNavBar extends StatelessWidget {
  final int currentIndex;
  final List<({IconData icon, String label})> items;
  final ValueChanged<int> onTap;
  const _PremiumNavBar({required this.currentIndex, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F).withOpacity(0.8), // Slightly more translucent
        borderRadius: BorderRadius.circular(36), // Pill shape to match MiniPlayer
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1), // Subtle edge
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4), // Replaced neon blue glow with clean shadow
            blurRadius: 30, 
            spreadRadius: -5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = currentIndex == i;
              return Expanded(
                child: _NavTab(
                  icon: items[i].icon,
                  label: items[i].label,
                  isActive: active,
                  onTap: () {
                    HapticFeedback.lightImpact(); // Softer haptic for smoother feel
                    onTap(i);
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavTab({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: AnimatedTheme(
                data: Theme.of(context).copyWith(
                  iconTheme: IconThemeData(
                    color: isActive ? const Color(0xFF00E5FF) : Colors.white30,
                    size: 22,
                  ),
                ),
                child: Icon(icon),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? Colors.white : Colors.white38,
                letterSpacing: 1.2,
              ),
              child: Text(label.toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }
}

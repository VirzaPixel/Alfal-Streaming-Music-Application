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
              left: 12,
              right: 12,
              bottom: 0,
              child: SafeArea(
                child: RepaintBoundary(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MiniPlayer(),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 12),
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
          // Ensure content is never blocked by the floating navigation bar (MiniPlayer + NavBar)
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom > 0 ? 0 : 180),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // Reduced from 30 for performance
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AColors.bg.withOpacity(0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = currentIndex == i;
              return Expanded(
                child: _NavTab(
                  icon: items[i].icon,
                  label: items[i].label,
                  isActive: active,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavTab({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween(begin: 1.0, end: 0.9).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 24,
              color: widget.isActive ? AColors.primary : Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w500,
                color: widget.isActive ? AColors.primary : Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

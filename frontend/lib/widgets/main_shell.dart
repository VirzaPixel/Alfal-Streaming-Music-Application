import 'dart:math' as math;
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
import 'mini_player.dart';

enum TabType { home, search, import, library, profile }

final shellTabProvider = StateProvider<TabType>((ref) => TabType.home);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> 
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  
  final Map<int, GlobalKey<NavigatorState>> _navKeys = {};

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(shellTabProvider);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final canUpload = user?.canUpload ?? false;
    
    final items = [
      (type: TabType.home, icon: Icons.grid_view_rounded, label: 'Home', screen: const HomeScreen()),
      (type: TabType.search, icon: Icons.search_rounded, label: 'Search', screen: const SearchScreen()),
      if (canUpload)
        (type: TabType.import, icon: Icons.auto_awesome_rounded, label: 'Import', screen: const AdminUploadScreen()),
      (type: TabType.library, icon: Icons.library_music_rounded, label: 'Library', screen: const PlaylistScreen()),
      (type: TabType.profile, icon: Icons.person_rounded, label: 'Profile', screen: const ProfileScreen()),
    ];

    final currentTabIndex = items.indexWhere((e) => e.type == tab);
    final safeIndex = currentTabIndex != -1 ? currentTabIndex : 0;

    for (int i = 0; i < items.length; i++) {
       _navKeys.putIfAbsent(i, () => GlobalKey<NavigatorState>());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final tabType = ref.read(shellTabProvider);
        final safeIdx = items.indexWhere((e) => e.type == tabType);
        final NavigatorState? nav = _navKeys[safeIdx]?.currentState;
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
            Positioned.fill(child: _AnimatedBackground(controller: _bgController)),
            
            IndexedStack(
              index: safeIndex,
              children: items.asMap().entries.map((e) => _buildTab(e.key, e.value.screen)).toList(),
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
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
                        _navKeys[i]?.currentState?.popUntil((r) => r.isFirst);
                      } else {
                        ref.read(shellTabProvider.notifier).state = clickedType;
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, Widget root) {
    return Navigator(
      key: _navKeys[index],
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => root,
        settings: settings,
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Stack(
          children: [
            Container(color: AColors.bg),
            Positioned(
              left: -80 + math.sin(t * math.pi * 2) * 60,
              top: -100 + math.cos(t * math.pi * 2) * 50,
              child: _GlowBlob(
                  color: AColors.primary.withValues(alpha: 0.12), size: 450),
            ),
            Positioned(
              right: -60 + math.cos(t * math.pi * 2) * 50,
              bottom: 100 + math.sin(t * math.pi * 2) * 60,
              child: _GlowBlob(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                  size: 380),
            ),
            Positioned(
              left: size.width / 2 - 130 + math.sin(t * math.pi * 4) * 40,
              top: size.height / 2 - 130,
              child: _GlowBlob(
                  color: const Color(0xFF10B981).withValues(alpha: 0.05),
                  size: 260),
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

class _PremiumNavBar extends StatelessWidget {
  final int currentIndex;
  final List<({IconData icon, String label})> items;
  final ValueChanged<int> onTap;
  const _PremiumNavBar({required this.currentIndex, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: AColors.bg.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.06), width: 1.5),
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
  const _NavTab(
      {required this.icon,
      required this.label,
      required this.isActive,
      required this.onTap});

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
    _scaleAnim = Tween(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: widget.isActive
                      ? AColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                child: Icon(
                  widget.icon,
                  size: 24,
                  color: widget.isActive
                      ? AColors.primary
                      : Colors.white.withValues(alpha: 0.25),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w500,
                  color: widget.isActive
                      ? AColors.primary
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

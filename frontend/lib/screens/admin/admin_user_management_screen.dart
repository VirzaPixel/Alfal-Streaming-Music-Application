import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';

class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState
    extends ConsumerState<AdminUserManagementScreen> {
  final _adminService = AdminService();
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _usersFuture = _adminService.listUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AColors.surface,
              AColors.surface.withValues(alpha: 0.8),
              Colors.black,
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon:
                      const Icon(Icons.refresh_rounded, color: Colors.white70),
                  onPressed: _refresh,
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                title: Text(
                  'User Systems',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
            FutureBuilder<List<UserModel>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                        child:
                            CircularProgressIndicator(color: AColors.primary)),
                  );
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AColors.error, size: 48),
                          const SizedBox(height: 16),
                          Text('System Link Failure',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                          Text(snapshot.error.toString(),
                              style: GoogleFonts.outfit(
                                  color: AColors.textSec, fontSize: 13)),
                          const SizedBox(height: 24),
                          TextButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry Connection'),
                            style: TextButton.styleFrom(
                                foregroundColor: AColors.primary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final users = snapshot.data ?? [];

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = users[index];
                        return _UserTile(
                          user: user,
                          onRoleUpdate: (newRole) async {
                            try {
                              await _adminService.updateUserRole(
                                  user.id, newRole);
                              _refresh();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'Updated ${user.username} to $newRole'),
                                  backgroundColor: AColors.accent,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ));
                                HapticFeedback.mediumImpact();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: AColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ));
                              }
                            }
                          },
                        ).animate().fadeIn(delay: (index * 40).ms).slideX(
                            begin: 0.05, end: 0, curve: Curves.easeOutCubic);
                      },
                      childCount: users.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final Function(String) onRoleUpdate;

  const _UserTile({required this.user, required this.onRoleUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AColors.premiumGradient,
              boxShadow: [
                BoxShadow(
                  color: AColors.primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user.username.substring(0, 1).toUpperCase(),
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: GoogleFonts.outfit(
                      color: AColors.textSec,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Role Bubble
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showRolePicker(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _getRoleColor(user.role).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.role.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: _getRoleColor(user.role).withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.unfold_more_rounded,
                      color: _getRoleColor(user.role).withValues(alpha: 0.6),
                      size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.amber;
      case 'creator':
        return AColors.primary;
      case 'user':
        return Colors.blueAccent;
      default:
        return Colors.white54;
    }
  }

  void _showRolePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Authority Level',
                style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Manage permissions for ${user.username}',
                style: GoogleFonts.outfit(
                    color: AColors.textSec,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            _RoleOption(
                label: 'Guest',
                sub: 'Explore & playback only',
                icon: Icons.person_outline_rounded,
                color: Colors.white54,
                onTap: () => _update(context, 'guest')),
            _RoleOption(
                label: 'User',
                sub: 'Personalized library & playlists',
                icon: Icons.person_rounded,
                color: Colors.blueAccent,
                onTap: () => _update(context, 'user')),
            _RoleOption(
                label: 'Creator',
                sub: 'System publishing permissions',
                icon: Icons.auto_awesome_rounded,
                color: AColors.primary,
                onTap: () => _update(context, 'creator')),
            _RoleOption(
                label: 'Admin',
                sub: 'Full infrastructure control',
                icon: Icons.admin_panel_settings_rounded,
                color: Colors.amber,
                onTap: () => _update(context, 'admin')),
          ],
        ),
      ),
    );
  }

  void _update(BuildContext context, String role) {
    Navigator.pop(context);
    onRoleUpdate(role);
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final String sub;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleOption({
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  Text(sub,
                      style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white12),
          ],
        ),
      ),
    );
  }
}


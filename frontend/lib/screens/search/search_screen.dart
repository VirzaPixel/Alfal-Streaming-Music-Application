import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/theme.dart';
import '../../models/song_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/a_text_field.dart';
import '../../widgets/song_options_sheet.dart';
import '../../widgets/song_tile.dart';
import '../../widgets/top_navbar.dart';

import '../profile/profile_screen.dart';

// ── Shared Recent Search Provider ──
final recentSearchesProvider = StateProvider<List<dynamic>>((ref) => []);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final recentSongs = ref.watch(recentSearchesProvider);
    
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final canUpload = user?.canUpload ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopNavbar(),

            // ── Search Input ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ATextField(
                      controller: _ctrl,
                      hint: 'Search songs, artists, or creators...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      suffixIcon: query.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _ctrl.clear();
                                ref.read(searchQueryProvider.notifier).state = '';
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            )
                          : null,
                      onChanged: (v) =>
                          ref.read(searchQueryProvider.notifier).state = v,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: AnimatedSwitcher(
                duration: 300.ms,
                child: query.isEmpty
                    ? _buildInitialState(recentSongs, canUpload)
                    : resultsAsync.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator(
                                color: AColors.primary)),
                        error: (_, __) => Center(
                          child: Text('Failed to load search results.',
                              style: GoogleFonts.outfit(
                                  color: Colors.white38)),
                        ),
                        data: (results) {
                          if (results.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final currentRecents =
                                  ref.read(recentSearchesProvider);
                              final first = results.first;
                              if (currentRecents.length < 10) {
                                bool exists = false;
                                if (first is SongModel) {
                                  exists = currentRecents.any((s) => s is SongModel && s.id == first.id);
                                } else if (first is UserModel) {
                                  exists = currentRecents.any((u) => u is UserModel && u.id == first.id);
                                }
                                
                                if (!exists) {
                                  ref.read(recentSearchesProvider.notifier).state = [first, ...currentRecents];
                                }
                              }
                            });
                          }
                          return results.isEmpty
                              ? const _EmptyView()
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 120),
                                  itemCount: results.length,
                                  itemBuilder: (_, i) {
                                    final item = results[i];
                                    if (item is UserModel) {
                                        return _UserTile(user: item).animate().fadeIn(delay: (i * 30).ms);
                                    }
                                    final song = item as SongModel;
                                    return SongTile(
                                      song: song,
                                      queue: results.whereType<SongModel>().toList(),
                                      onMoreTap: () => showModalBottomSheet(
                                        context: context,
                                        useRootNavigator: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) =>
                                            SongOptionsSheet(song: song),
                                      ),
                                    ).animate().fadeIn(delay: (i * 30).ms);
                                  },
                                );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(List<dynamic> recentSongs, bool canUpload) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
      children: [
        if (recentSongs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(recentSearchesProvider.notifier).state = [],
                  child: Text('Clear',
                      style: GoogleFonts.outfit(
                          color: AColors.primaryLight, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          ...recentSongs.asMap().entries.map((entry) {
             final item = entry.value;
             if (item is UserModel) {
               return _UserTile(user: item).animate().fadeIn(delay: (entry.key * 30).ms).slideX(begin: 0.04, end: 0);
             }
             return SongTile(
                song: item as SongModel,
                queue: recentSongs.whereType<SongModel>().toList(),
              ).animate().fadeIn(delay: (entry.key * 30).ms).slideX(begin: 0.04, end: 0);
          }),
          const SizedBox(height: 32),
        ],
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(targetUserId: user.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: user.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: user.avatarUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover)
                  : Container(
                      width: 48,
                      height: 48,
                      color: Colors.white10,
                      child: const Icon(Icons.person, color: Colors.white24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.username,
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(user.role.toUpperCase(),
                      style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: AColors.primaryLight,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 48, color: Colors.white.withValues(alpha: 0.1)),
          ),
          const SizedBox(height: 24),
          Text(
            'No matches found',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

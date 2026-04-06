import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../playlist/playlist_detail_screen.dart';
import '../playlist/liked_songs_screen.dart';
import '../../widgets/top_navbar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isGuest = auth.user?.isGuest == true;
    final playlistsAsync = ref.watch(playlistsProvider);
    final player = ref.watch(playerProvider);
    final currentSong = player.currentSong;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TopNavbar(),
            Expanded(
              child: isGuest
                  ? _buildGuestDashboard(context, auth, currentSong)
                  : _buildUserDashboard(context, ref, auth, playlistsAsync, currentSong),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestDashboard(BuildContext context, AuthState auth, dynamic currentSong) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AColors.primary.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset('assets/logo/alfal_logo.png', fit: BoxFit.cover),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    'WELCOME',
                    style: GoogleFonts.outfit(
                        color: AColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3),
                  ).animate().fadeIn(),
                  const SizedBox(height: 12),
                  Text(
                    'ALFAL Music World',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Sign in to your account for full access, or check out our premium audio experience.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white30,
                      fontSize: 16,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 48),
                  _buildAuthButtons(context),
                  const SizedBox(height: 24),
                  
                  // Same text links as Login for consistency
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
                        children: const [
                          TextSpan(text: "Don't have an account?  "),
                          TextSpan(
                            text: 'Sign Up now',
                            style: TextStyle(color: AColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  
                  const SizedBox(height: 80),
                  
                  Text(
                    'DEVELOPED BY VIRZA',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.1),
                      letterSpacing: 4,
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDashboard(
    BuildContext context,
    WidgetRef ref,
    AuthState auth,
    AsyncValue<List<dynamic>> playlistsAsync,
    dynamic currentSong,
  ) {
    final suggestedAsync = ref.watch(suggestedSongsProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Personalized Greeting ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: GoogleFonts.outfit(
                      color: Colors.white24,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 4),
                Text(
                  auth.user?.username ?? 'Listener',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2),
                ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1, end: 0),
              ],
            ),
          ),
        ),

        // ── Quick Access Grid ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            delegate: SliverChildListDelegate([
              _QuickAccessTile(
                label: 'Liked Songs',
                icon: Icons.favorite_rounded,
                color: Colors.redAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LikedSongsScreen())),
              ),
              // Get first 3 playlists
              ...playlistsAsync.maybeWhen(
                data: (list) => list.take(3).map((p) => _QuickAccessTile(
                      label: p.name,
                      image: p.coverUrl,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistId: p.id))),
                    )),
                orElse: () => [],
              )
            ]),
          ),
        ),

        // ── Suggested For You ──
        SliverToBoxAdapter(
          child: _HomeSection(
            title: 'Suggested For You',
            onSeeAll: () {},
            child: suggestedAsync.when(
              loading: () => const _HorizontalLoading(),
              error: (_, __) => const SizedBox.shrink(),
              data: (songs) => Container(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: songs.length,
                  itemBuilder: (_, i) => _SuggestedSongCard(song: songs[i]),
                ),
              ),
            ),
          ),
        ),

        // ── Your Playlists ──
        SliverToBoxAdapter(
          child: _HomeSection(
            title: 'Your Playlists',
            onSeeAll: () => Navigator.pushNamed(context, '/playlists'),
            child: playlistsAsync.when(
              data: (playlists) => playlists.isEmpty
                  ? _EmptyPlaylists()
                  : SizedBox(
                      height: 230,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: playlists.length,
                        itemBuilder: (context, i) => _PlaylistCard(playlist: playlists[i])
                            .animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.1, end: 0),
                      ),
                    ),
              loading: () => const _HorizontalLoading(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    if (hour < 21) return 'GOOD EVENING';
    return 'GOOD NIGHT';
  }


  Widget _buildAuthButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _AuthButton(
              label: 'Sign In',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _AuthButton(
              label: 'Sign Up',
              isOutline: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.15, end: 0);
  }

}

class _HomeSection extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;
  const _HomeSection({required this.title, required this.child, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text('All',
                      style: GoogleFonts.outfit(
                          color: Colors.white24,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? image;
  final Color? color;
  final VoidCallback onTap;

  const _QuickAccessTile({
    required this.label,
    this.icon,
    this.image,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color?.withValues(alpha: 0.1) ?? Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  image: image != null
                      ? DecorationImage(
                          image: NetworkImage(image!), fit: BoxFit.cover)
                      : null,
                ),
                child: image == null
                    ? Icon(icon ?? Icons.music_note_rounded,
                        color: color ?? Colors.white24, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestedSongCard extends ConsumerWidget {
  final dynamic song;
  const _SuggestedSongCard({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(playerProvider.notifier).playSong(song, sourceName: 'Suggested For You');
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                    image: NetworkImage(song.coverUrl), fit: BoxFit.cover),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(4, 6),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalLoading extends StatelessWidget {
  const _HorizontalLoading();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 150,
      child: Center(child: CircularProgressIndicator(color: AColors.primary)),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final dynamic playlist;
  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(playlistId: playlist.id),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'playlist_cover_${playlist.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(4, 8),
                    ),
                  ],
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05)),
                      image: playlist.coverUrl != null
                          ? DecorationImage(
                              image: NetworkImage(playlist.coverUrl!),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: playlist.coverUrl == null
                        ? Center(
                            child: Icon(Icons.playlist_play_rounded,
                                color: Colors.white.withValues(alpha: 0.1),
                                size: 48))
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              '${playlist.songs?.length ?? 0} songs',
              style: GoogleFonts.outfit(
                  color: Colors.white24,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlaylists extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), shape: BoxShape.circle),
              child: Icon(Icons.auto_awesome_mosaic_rounded, color: Colors.white.withValues(alpha: 0.05), size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'No playlists yet',
              style: GoogleFonts.outfit(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isOutline;

  const _AuthButton({
    required this.label,
    required this.onTap,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isOutline ? null : AColors.primaryGradient,
          color: isOutline ? Colors.white.withValues(alpha: 0.04) : null,
          border: isOutline ? Border.all(color: Colors.white.withValues(alpha: 0.08)) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }
}

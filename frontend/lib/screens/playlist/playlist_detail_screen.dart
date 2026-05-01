import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/cloudinary_service.dart';

import '../../config/theme.dart';
import '../../models/playlist_model.dart';
import '../../models/song_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/song_options_sheet.dart';
import '../../widgets/song_tile.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final int playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistDetailProvider(playlistId));
    final player = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          playlistAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AColors.primary),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(e.toString(),
                      style: GoogleFonts.outfit(color: AColors.textSec)),
                ],
              ),
            ),
            data: (playlist) {
              final songs = playlist.songs;
              final palette = [
                const Color(0xFF6366F1),
                const Color(0xFF8B5CF6)
              ];

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Dynamic Header ──
                  SliverAppBar(
                    expandedHeight: 400,
                    pinned: true,
                    stretch: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [
                        StretchMode.zoomBackground,
                        StretchMode.blurBackground
                      ],
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image or Gradient Background
                          if (playlist.coverUrl != null &&
                              playlist.coverUrl!.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: playlist.coverUrl!,
                              fit: BoxFit.cover,
                            ),

                          // Dark overlay for readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.2),
                                  Colors.black.withOpacity(0.4), // Softer overlay so grid is fully visible!
                                ],
                              ),
                            ),
                          ),

                          // Content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 60),
                                // Playlist Artwork Card
                                Hero(
                                  tag: 'playlist_${playlist.id}',
                                  child: Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(36),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 30,
                                          offset: const Offset(0, 15),
                                        )
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(36),
                                      child: playlist.coverUrl != null && playlist.coverUrl!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: playlist.coverUrl!,
                                            fit: BoxFit.cover,
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(36),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.02),
                                                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                                                  borderRadius: BorderRadius.circular(36),
                                                ),
                                                child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 64),
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  playlist.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
                                if (playlist.description != null && playlist.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, left: 32, right: 32),
                                    child: Text(
                                      playlist.description!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white38,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ).animate().fadeIn(delay: 300.ms),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: Text(
                                    '${songs.length} TRACKS',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: AColors.primaryLight,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 400.ms),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Action Bar (Glass effect) ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (songs.isNotEmpty) {
                                  HapticFeedback.heavyImpact();
                                  final isThisPlaylistPlaying =
                                      player.sourceName == playlist.name;

                                  if (isThisPlaylistPlaying && player.hasSong) {
                                    ref
                                        .read(playerProvider.notifier)
                                        .togglePlayPause();
                                  } else {
                                    ref.read(playerProvider.notifier).playSong(
                                          songs.first,
                                          queue: songs,
                                          sourceName: playlist.name,
                                        );
                                  }
                                }
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: player.sourceName == playlist.name
                                      ? null
                                      : AColors.primaryGradient,
                                  color: player.sourceName == playlist.name
                                      ? Colors.white.withOpacity(0.05)
                                      : null,
                                  borderRadius: BorderRadius.circular(20),
                                  border: player.sourceName == playlist.name
                                      ? Border.all(color: Colors.white.withOpacity(0.1))
                                      : null,
                                  boxShadow: player.sourceName == playlist.name
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: AColors.primary.withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      player.sourceName == playlist.name &&
                                              player.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      player.sourceName == playlist.name
                                          ? (player.isPlaying
                                              ? 'PAUSE'
                                              : 'RESUME')
                                          : 'PLAY ALL',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Shuffle Button (Smart Toggle)
                          GestureDetector(
                            onTap: () {
                              if (songs.isEmpty) return;
                              final isThisPlaylistPlaying = player.sourceName == playlist.name;

                              if (isThisPlaylistPlaying && player.hasSong) {
                                // If already playing this playlist, just toggle the mode (Mati/Nyala)
                                HapticFeedback.selectionClick();
                                ref.read(playerProvider.notifier).toggleShuffle();
                              } else {
                                // If not playing, start a new shuffled session
                                HapticFeedback.heavyImpact();
                                final mutable = List<SongModel>.from(songs)..shuffle();
                                ref.read(playerProvider.notifier).setShuffle(true);
                                ref.read(playerProvider.notifier).playSong(
                                  mutable.first,
                                  queue: mutable,
                                  sourceName: playlist.name,
                                );
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: player.shuffle 
                                    ? AColors.primary.withOpacity(0.2) 
                                    : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: player.shuffle 
                                        ? AColors.primary.withOpacity(0.5) 
                                        : Colors.white.withOpacity(0.1)),
                              ),
                              child: Icon(Icons.shuffle_rounded,
                                  color: player.shuffle ? AColors.primary : Colors.white, 
                                  size: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Replay/Repeat Button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(playerProvider.notifier).toggleRepeat();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: player.repeatMode != RepeatMode.off
                                    ? AColors.primary.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: player.repeatMode != RepeatMode.off
                                      ? AColors.primary.withOpacity(0.5)
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Icon(
                                player.repeatMode == RepeatMode.one
                                    ? Icons.repeat_one_rounded
                                    : Icons.repeat_rounded,
                                color: player.repeatMode != RepeatMode.off
                                    ? AColors.primary
                                    : Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Edit/More Info
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showEditDialog(context, ref, playlist);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.08)),
                              ),
                              child: const Icon(Icons.mode_edit_outline_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Delete Button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _confirmDelete(context, ref, playlist);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: AColors.error.withOpacity(0.2)),
                              ),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: AColors.error, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Songs List ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 240),
                    sliver: songs.isEmpty
                        ? SliverToBoxAdapter(
                            child: _EmptyPlaylistState(),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => SongTile(
                                song: songs[i],
                                queue: songs,
                                sourceName: playlist.name,
                                onMoreTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    useRootNavigator: true,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (_) => SongOptionsSheet(
                                      song: songs[i],
                                      currentPlaylistId: playlistId,
                                    ),
                                  );
                                },
                              )
                                  .animate()
                                  .fadeIn(delay: (i * 40).ms)
                                  .slideX(begin: 0.1, end: 0),
                              childCount: songs.length,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),

        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, PlaylistModel playlist) {
    showDialog(
      context: context,
      builder: (ctx) => _EditPlaylistDialog(playlist: playlist),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, PlaylistModel playlist) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AColors.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AColors.error, size: 36),
              ),
              const SizedBox(height: 24),
              Text('Delete Playlist?',
                  style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: AColors.textSec, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _DialogBtn(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(ctx),
                      isSecondary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogBtn(
                      label: 'Delete',
                      onTap: () async {
                        await ref
                            .read(playlistServiceProvider)
                            .deletePlaylist(playlist.id);
                        ref.invalidate(playlistsProvider);
                        if (context.mounted) {
                          Navigator.pop(ctx); // Close dialog
                          Navigator.pop(context); // Close detail screen
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditPlaylistDialog extends ConsumerStatefulWidget {
  final PlaylistModel playlist;
  const _EditPlaylistDialog({required this.playlist});

  @override
  ConsumerState<_EditPlaylistDialog> createState() => _EditPlaylistDialogState();
}

class _EditPlaylistDialogState extends ConsumerState<_EditPlaylistDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  File? _localImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.playlist.name);
    _descCtrl = TextEditingController(text: widget.playlist.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Playlist',
                      style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.3)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Preview Artwork - Fixed UI Layout
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    clipBehavior: Clip.none, // Allow icon to pop out slightly without being cut
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AColors.primary.withOpacity(0.15), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AColors.primary.withOpacity(0.15),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _localImage != null 
                                ? (kIsWeb 
                                    ? Image.network(_localImage!.path, fit: BoxFit.cover) 
                                    : Image.file(_localImage!, fit: BoxFit.cover))
                                : (widget.playlist.coverUrl != null && widget.playlist.coverUrl!.isNotEmpty 
                                    ? CachedNetworkImage(imageUrl: widget.playlist.coverUrl!, fit: BoxFit.cover) 
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.01)],
                                          ),
                                        ),
                                        child: Center(child: Icon(Icons.music_note_rounded, color: Colors.white.withOpacity(0.1), size: 50)),
                                      )),
                              if (_isSaving)
                                Container(
                                  color: Colors.black.withOpacity(0.7),
                                  child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!_isSaving)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              _buildField('Playlist Name', _nameCtrl, icon: Icons.title_rounded),
              const SizedBox(height: 24),
              _buildField('Description', _descCtrl, maxLines: 3, icon: Icons.description_rounded),
              const SizedBox(height: 40),
              
              Row(
                children: [
                  Expanded(
                    child: _DialogBtn(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(context),
                      isSecondary: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DialogBtn(
                      label: _isSaving ? 'Saving...' : 'Save',
                      onTap: _isSaving ? () {} : _handleSave,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (file == null) return;
    setState(() => _localImage = File(file.path));
  }

  Future<void> _handleSave() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    try {
      String? finalCoverUrl = widget.playlist.coverUrl;
      String? oldCoverUrl = widget.playlist.coverUrl;

      // 1. Upload cover if changed
      if (_localImage != null) {
        final cloudinary = CloudinaryPublic(
          dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'dkkyvggnz',
          dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'alfal_app',
        );
        final res = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _localImage!.path,
            resourceType: CloudinaryResourceType.Auto,
            folder: 'alfal_cover_playlist',
          ),
        );
        finalCoverUrl = res.secureUrl;
      }

      // 2. Update Supabase
      await ref.read(playlistServiceProvider).updatePlaylist(
            widget.playlist.id,
            name: _nameCtrl.text.trim(),
            desc: _descCtrl.text.trim(),
            coverUrl: finalCoverUrl,
          );

      // 3. Cleanup: Hapus cover lama jika ganti cover baru
      if (_localImage != null && oldCoverUrl != null) {
        CloudinaryService.deleteImage(oldCoverUrl);
      }

      ref.invalidate(playlistDetailProvider(widget.playlist.id));
      ref.invalidate(playlistsProvider);
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildField(String label, TextEditingController ctrl, {int maxLines = 1, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: maxLines > 1 ? (maxLines * 12.0) : 0),
                child: Icon(icon, color: AColors.primary.withOpacity(0.5), size: 18),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 50),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              hintStyle: GoogleFonts.outfit(color: Colors.white24),
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  const _DialogBtn(
      {required this.label, required this.onTap, this.isSecondary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSecondary ? Colors.white.withOpacity(0.06) : AColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSecondary
              ? []
              : [
                  BoxShadow(
                      color: AColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6))
                ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _EmptyPlaylistState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(Icons.library_music_rounded,
              size: 56, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            'Playlist is empty',
            style: GoogleFonts.outfit(color: AColors.textSec, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Go find some music to add!',
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }
}


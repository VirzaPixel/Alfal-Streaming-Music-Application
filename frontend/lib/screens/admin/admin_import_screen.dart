import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/magic_import_service.dart';
import '../../config/theme.dart';

class AdminImportScreen extends StatefulWidget {
  final bool isFragment;
  const AdminImportScreen({super.key, this.isFragment = false});

  @override
  State<AdminImportScreen> createState() => _AdminImportScreenState();
}

class _AdminImportScreenState extends State<AdminImportScreen> {
  final _searchCtrl = TextEditingController();
  final _service = MagicImportService();
  
  List<Map<String, dynamic>> _results = [];
  Map<int, String> _loadingStates = {};
  Set<String> _existingKeys = {}; // "title|||artist" lowercase yang sudah ada di DB
  bool _isSearching = false;
  bool _serverOnline = false;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    final online = await _service.isServerOnline();
    if (mounted) setState(() => _serverOnline = online);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _isSearching = true;
      _results = [];
      _loadingStates = {};
      _existingKeys = {};
    });

    try {
      final res = await _service.searchMetadata(q);
      setState(() => _results = res);

      // Batch-check ke Supabase: mana yang sudah ada di DB
      if (res.isNotEmpty) {
        final existing = await _service.batchCheckExists(res);
        if (mounted) setState(() => _existingKeys = existing);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: GoogleFonts.outfit(fontSize: 13)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _startImport(int index) async {
    if (_loadingStates.containsKey(index)) return;

    final song = _results[index];
    try {
      await _service.importSong(
        song,
        onProgress: (status) => setState(() => _loadingStates[index] = status),
      );
      setState(() => _loadingStates[index] = 'SUCCESS! ✨');
    } catch (e) {
      setState(() => _loadingStates[index] = 'FAILED: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFragment) {
      return Column(
        children: [
            _serverBanner(),
            _searchBar(),
            Expanded(
              child: _isSearching 
                ? const Center(child: CircularProgressIndicator(color: AColors.primary))
                : _results.isEmpty ? _emptyState() : _list(),
            ),
          ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (!widget.isFragment) _auras(),
          SafeArea(
            child: Column(
              children: [
                _header(),
                _serverBanner(),
                _searchBar(),
                Expanded(
                  child: _isSearching 
                    ? const Center(child: CircularProgressIndicator(color: AColors.primary))
                    : _results.isEmpty ? _emptyState() : _list(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _serverBanner() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _serverOnline
          ? Container(
              key: const ValueKey('online'),
              margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                  const SizedBox(width: 8),
                  Text(
                    'Music Agent Online — Full MP3 Mode',
                    style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _checkServer,
                    child: const Icon(Icons.refresh_rounded, color: Colors.greenAccent, size: 16),
                  ),
                ],
              ),
            )
          : Container(
              key: const ValueKey('offline'),
              margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Agent Offline. Jalankan: python scripts/agent_server.py',
                      style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: _checkServer,
                    child: const Icon(Icons.refresh_rounded, color: Colors.orangeAccent, size: 16),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _auras() => Positioned.fill(
    child: Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.8, -0.6),
          radius: 1.5,
          colors: [Color(0xFF1E1E3A), Color(0xFF030303)],
        ),
      ),
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.all(28),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (Navigator.canPop(context))
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28))
        else
          const SizedBox(width: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: AColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Text('MAGIC IMPORT', style: GoogleFonts.outfit(color: AColors.primaryLight, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 3)),
        ),
      ],
    ),
  );

  Widget _searchBar() => Padding(
    padding: const EdgeInsets.only(left: 28, right: 28, top: 25, bottom: 10),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onSubmitted: (_) => _onSearch(),
        cursorColor: AColors.primary,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Search for any track...',
          hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 16),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 25, right: 15),
            child: const Icon(Icons.auto_fix_high_rounded, color: AColors.primary, size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 22),
        ),
      ),
    ),
  );

  Widget _list() => ListView.builder(
    padding: const EdgeInsets.fromLTRB(28, 20, 28, 140),
    itemCount: _results.length,
    itemBuilder: (ctx, i) {
      final song = _results[i];
      final status = _loadingStates[i];
      final isDone = status == 'SUCCESS! ✨';
      final isError = status?.startsWith('FAILED') ?? false;

      // Cek apakah lagu sudah ada di DB
      final songKey = '${song['title'] ?? ''}|||${song['artist'] ?? ''}'.toLowerCase();
      final alreadyInDB = _existingKeys.contains(songKey);

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: alreadyInDB
              ? Colors.purple.withOpacity(0.06)
              : isDone
                  ? Colors.green.withOpacity(0.08)
                  : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: alreadyInDB
                ? Colors.purple.withOpacity(0.25)
                : isDone
                    ? Colors.green.withOpacity(0.2)
                    : Colors.white.withOpacity(0.08),
          ),
          boxShadow: [
            if (isDone)
              BoxShadow(
                color: Colors.green.withOpacity(0.05),
                blurRadius: 15,
              )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // ✅ Null-safe cover image dengan fallback placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (song['cover_url'] as String?)?.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: song['cover_url'] as String,
                        width: 56, height: 56, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _coverPlaceholder(),
                      )
                    : _coverPlaceholder(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Null-safe title & artist
                      Text(
                        song['title'] as String? ?? 'Unknown Title',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song['artist'] as String? ?? 'Unknown Artist',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (alreadyInDB)
                  // Badge ungu: sudah ada di library
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.library_music_rounded, color: Colors.purpleAccent, size: 14),
                        const SizedBox(width: 5),
                        Text('In Library', style: GoogleFonts.outfit(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  )
                else if (status == null)
                  IconButton(onPressed: () => _startImport(i), icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 30))
                else if (isDone)
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 30)
                else if (isError)
                  IconButton(onPressed: () => _startImport(i), icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent))
                else
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AColors.primary)),
              ],
            ),
            if (status != null && !isDone)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  status,
                  style: GoogleFonts.outfit(fontSize: 11, color: isError ? Colors.redAccent : AColors.primaryLight, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ).animate().fadeIn(delay: (i * 40).ms).slideY(begin: 0.1, end: 0);
    },
  );

  Widget _coverPlaceholder() => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(
      color: AColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.music_note_rounded, color: AColors.primary, size: 28),
  );

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AColors.primary.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.rocket_launch_rounded, size: 56, color: AColors.primary)
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 2.seconds, color: Colors.white24)
            .shake(hz: 2, curve: Curves.easeInOut),
        ),
        const SizedBox(height: 32),
        Text(
          'Magic is waiting...',
          style: GoogleFonts.outfit(
            color: Colors.white, 
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter a song name to begin search',
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
  );
}

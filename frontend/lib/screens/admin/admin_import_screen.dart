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
  Map<int, String> _loadingStates = {}; // Index -> Status text
  bool _isSearching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() { _isSearching = true; _results = []; });
    try {
      final res = await _service.searchMetadata(q);
      setState(() => _results = res);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
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
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: _searchCtrl,
        onSubmitted: (_) => _onSearch(),
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          hintText: 'Search for any track...',
          hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 16),
          prefixIcon: const Icon(Icons.auto_fix_high_rounded, color: AColors.primary, size: 24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(22),
        ),
      ),
    ),
  );

  Widget _list() => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
    itemCount: _results.length,
    itemBuilder: (ctx, i) {
      final song = _results[i];
      final status = _loadingStates[i];
      final isDone = status == 'SUCCESS! ✨';
      final isError = status?.startsWith('FAILED') ?? false;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDone ? Colors.green.withOpacity(0.05) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isDone ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: song['cover_url'], width: 56, height: 56, fit: BoxFit.cover)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song['title'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16), maxLines: 1),
                      Text(song['artist'], style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13), maxLines: 1),
                    ],
                  ),
                ),
                if (status == null)
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
                child: Text(status, style: GoogleFonts.outfit(fontSize: 10, color: isError ? Colors.redAccent : AColors.primaryLight, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ).animate().fadeIn(delay: (i * 40).ms).slideY(begin: 0.1, end: 0);
    },
  );

  Widget _emptyState() => Center(
    child: Opacity(
      opacity: 0.2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rocket_launch_rounded, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          Text('Enter a song name to begin magic', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
        ],
      ),
    ),
  );
}

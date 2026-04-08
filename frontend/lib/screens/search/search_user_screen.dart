import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../services/connection_service.dart';
import '../profile/profile_screen.dart'; // Existing profile screen
import '../../config/theme.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final _searchCtrl = TextEditingController();
  final _service = ConnectionService();
  List<UserModel> _results = [];
  bool _isLoading = false;

  void _onSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final res = await _service.searchUsers(q);
      // Double safety: filter out any admin that might slip through
      setState(() => _results = res.where((u) => u.role != 'admin').toList());
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Mask internal role names — admins never visible, others shown generically
  String _maskRole(String role) {
    switch (role.toLowerCase()) {
      case 'creator': return 'CREATOR';
      case 'user': return 'MEMBER';
      default: return 'MEMBER';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _searchBar(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AColors.primary))
                : _results.isEmpty 
                  ? _emptyState()
                  : _resultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.all(24),
    child: Row(
      children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
        const SizedBox(width: 12),
        Text('Accounts', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    ),
  );

  Widget _searchBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchCtrl,
        onSubmitted: (_) => _onSearch(),
        style: GoogleFonts.outfit(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search username...',
          hintStyle: GoogleFonts.outfit(color: Colors.white24),
          prefixIcon: const Icon(Icons.search_rounded, color: AColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    ),
  );

  Widget _resultsList() => ListView.builder(
    padding: const EdgeInsets.all(24),
    itemCount: _results.length,
    itemBuilder: (ctx, i) {
      final user = _results[i];
      return GestureDetector(
        onTap: () {
          // Navigate to Other User Profile
          Navigator.push(context, MaterialPageRoute(builder: (ctx) => ProfileScreen(targetUserId: user.id)));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _avatar(user.avatarUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(_maskRole(user.role), style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, letterSpacing: 1)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ],
          ),
        ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.1, end: 0),
      );
    },
  );

  Widget _avatar(String? url) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: url != null 
      ? CachedNetworkImage(imageUrl: url, width: 44, height: 44, fit: BoxFit.cover)
      : Container(width: 44, height: 44, color: Colors.white10, child: const Icon(Icons.person, color: Colors.white24)),
  );

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.people_alt_rounded, size: 64, color: Colors.white10),
        const SizedBox(height: 16),
        Text('Discover ALFAL users', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 16)),
      ],
    ),
  );
}

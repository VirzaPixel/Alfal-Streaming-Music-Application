import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../config/theme.dart';
import '../../widgets/a_text_field.dart';

class AdminManualUploadScreen extends ConsumerStatefulWidget {
  final bool isFragment;
  const AdminManualUploadScreen({super.key, this.isFragment = false});

  @override
  ConsumerState<AdminManualUploadScreen> createState() => _AdminManualUploadScreenState();
}

class _AdminManualUploadScreenState extends ConsumerState<AdminManualUploadScreen> {
  final _helperUrlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _albumCtrl = TextEditingController();
  final _audioUrlCtrl = TextEditingController();
  final _coverUrlCtrl = TextEditingController();
  final _genreCtrl = TextEditingController(text: 'Music');

  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _helperUrlCtrl.dispose();
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _albumCtrl.dispose();
    _audioUrlCtrl.dispose();
    _coverUrlCtrl.dispose();
    _genreCtrl.dispose();
    super.dispose();
  }

  Future<void> _grabMetadataManual(String url) async {
    if (url.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      String? oembedUrl;
      if (url.contains('spotify.com')) {
        oembedUrl = 'https://open.spotify.com/oembed?url=$url';
      } else if (url.contains('youtube.com') || url.contains('youtu.be')) {
        oembedUrl = 'https://www.youtube.com/oembed?url=$url&format=json';
      } else if (url.contains('soundcloud.com')) {
        oembedUrl = 'https://soundcloud.com/oembed?url=$url';
      }
      
      if (oembedUrl == null) throw 'Unsupported link';

      final res = await http.get(Uri.parse(oembedUrl));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        String rawTitle = data['title'] ?? '';
        String cover = data['thumbnail_url'] ?? '';

        String artist = 'Various Artists';
        String title = rawTitle;
        if (rawTitle.contains(' by ')) {
          final parts = rawTitle.split(' by ');
          title = parts[0].trim();
          artist = parts[1].trim();
        } else if (rawTitle.contains(' - ')) {
          final parts = rawTitle.split(' - ');
          artist = parts[0].trim();
          title = parts[1].trim();
        }

        setState(() {
          _titleCtrl.text = title;
          _artistCtrl.text = artist;
          _coverUrlCtrl.text = cover;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadAudio() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
      if (file == null) return;

      setState(() => _isLoading = true);
      
      final cloudinary = CloudinaryPublic(
        dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '', 
        dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '', 
        cache: false
      );
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Auto),
      );

      setState(() {
        _audioUrlCtrl.text = response.secureUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Upload failed. Use an external link if the file is too large.";
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_titleCtrl.text.isEmpty || _artistCtrl.text.isEmpty || _audioUrlCtrl.text.isEmpty) {
      setState(() => _error = "Title, Artist, and Audio are required.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('songs').insert({
        'title': _titleCtrl.text.trim(),
        'artist': _artistCtrl.text.trim(),
        'album': _albumCtrl.text.trim(),
        'genre': _genreCtrl.text.trim(),
        'cover_url': _coverUrlCtrl.text.trim(),
        'audio_url': _audioUrlCtrl.text.trim(),
        'play_count': 0,
      });

      setState(() {
        _isLoading = false;
        _success = "SUCCESS! ${_titleCtrl.text} added manually.";
        _titleCtrl.clear();
        _audioUrlCtrl.clear();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (!widget.isFragment)
          SliverAppBar(
            expandedHeight: 120,
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Manual Upload', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white, letterSpacing: -1)),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Smart Helper (Link Grabber) ---
                Text('SMART HELPER (OPTIONAL)',
                    style: GoogleFonts.outfit(
                        color: AColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08))),
                        child: TextField(
                          controller: _helperUrlCtrl,
                          onSubmitted: (v) => _grabMetadataManual(v),
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                              hintText: 'Paste link to auto-fill metadata...',
                              hintStyle: TextStyle(color: Colors.white24),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _grabMetadataManual(_helperUrlCtrl.text),
                      child: Container(
                        height: 52,
                        width: 80,
                        decoration: BoxDecoration(
                            color: AColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16)),
                        child: Center(
                            child: _isLoading && _helperUrlCtrl.text.isNotEmpty
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: AColors.primary))
                                : const Text('GRAB',
                                    style: TextStyle(
                                        color: AColors.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                if (_error != null)
                  _Banner(text: _error!, isError: true).animate().shake(),
                if (_success != null)
                  _Banner(text: _success!, isError: false).animate().fadeIn(),

                Text('SONG INFORMATION',
                    style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5)),
                const SizedBox(height: 24),
                ATextField(label: 'Song Title', controller: _titleCtrl),
                const SizedBox(height: 16),
                ATextField(label: 'ArtistName', controller: _artistCtrl),
                const SizedBox(height: 16),
                ATextField(label: 'Album', controller: _albumCtrl),
                const SizedBox(height: 16),
                ATextField(label: 'Cover Art URL', controller: _coverUrlCtrl),
                const SizedBox(height: 16),
                _buildAudioInput(),
                const SizedBox(height: 48),
                _buildSubmitButton(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.isFragment) return content;

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
              Colors.black
            ],
          ),
        ),
        child: content,
      ),
    );
  }

  Widget _buildAudioInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AUDIO FILE / URL', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
                child: TextField(
                  controller: _audioUrlCtrl,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(hintText: 'Paste URL or Upload File', hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _uploadAudio,
              child: Container(
                height: 52, width: 52,
                decoration: BoxDecoration(color: AColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.upload_file_rounded, color: AColors.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleUpload,
      child: Container(
        height: 64, width: double.infinity,
        decoration: BoxDecoration(
          gradient: AColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Center(
          child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : Text('PUBLISH SONG', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final bool isError;
  const _Banner({required this.text, required this.isError});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: (isError ? AColors.error : AColors.primary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: (isError ? AColors.error : AColors.primary).withValues(alpha: 0.2))),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: isError ? AColors.error : AColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.outfit(color: isError ? AColors.error : Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

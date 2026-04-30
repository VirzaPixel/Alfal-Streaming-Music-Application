import 'package:flutter_dotenv/flutter_dotenv.dart';

// ── Supabase Configuration ───────────────────────────────────────────
// These credentials are now securely pulled from the .env file.
final String kSupabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
final String kSupabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

// ── Cloudinary Configuration ──────────────────────────────────────────
final String kCloudinaryName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
final String kCloudinaryPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

// ── Storage Optimization ──────────────────────────────────────────────
const String kSongsBucket = 'songs';
const String kCoversBucket = 'covers';
const String kAvatarsBucket = 'avatars';

/// Computes the public URL for assets stored in Supabase Storage.
String getStorageUrl(String bucket, String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '$kSupabaseUrl/storage/v1/object/public/$bucket/$path';
}

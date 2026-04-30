import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  /// Menghapus foto dari Cloudinary secara langsung dari Flutter (Versi Authenticated)
  static Future<void> deleteImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    if (!imageUrl.contains('cloudinary.com')) return;

    try {
      final publicId = _extractPublicId(imageUrl);
      if (publicId == null) return;

      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      final apiKey = dotenv.env['CLOUDINARY_API_KEY'];
      final apiSecret = dotenv.env['CLOUDINARY_API_SECRET'];

      if (cloudName == null || apiKey == null || apiSecret == null) {
        debugPrint('Cloudinary config is missing in .env');
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Membuat Signature SHA-1 (Syarat Cloudinary untuk hapus)
      // Rumus: public_id=xxx&timestamp=xxxSECRET
      final signatureSource = "public_id=$publicId&timestamp=$timestamp$apiSecret";
      final signature = sha1.convert(utf8.encode(signatureSource)).toString();

      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy'),
        body: {
          'public_id': publicId,
          'timestamp': timestamp.toString(),
          'api_key': apiKey,
          'signature': signature,
        },
      );

      final result = jsonDecode(response.body);
      debugPrint('Cloudinary Delete Result: $result');
    } catch (e) {
      debugPrint('Gagal menghapus foto lama secara langsung: $e');
    }
  }

  /// Mengambil Public ID dari URL Cloudinary
  static String? _extractPublicId(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      int uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return null;

      // Mendeteksi apakah URL mengandung versi (v12345678)
      // Normalnya versi ada di uploadIndex + 1
      int idStartIndex = uploadIndex + 1;
      if (pathSegments[idStartIndex].startsWith('v') && 
          pathSegments[idStartIndex].length > 5) {
        idStartIndex++; // Loncat versi jika ada
      }

      List<String> idSegments = pathSegments.sublist(idStartIndex);
      String lastSegment = idSegments.last;
      
      if (lastSegment.contains('.')) {
        idSegments[idSegments.length - 1] = lastSegment.split('.').first;
      }
      
      return idSegments.join('/');
    } catch (e) {
      return null;
    }
  }
}

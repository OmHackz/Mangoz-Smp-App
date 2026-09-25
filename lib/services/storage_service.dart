import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'supabase_service.dart';

const _uuid = Uuid();

/// Uploads avatars, chat images, voice notes and group images to
/// Supabase Storage buckets: avatars, chat-images, voice-messages,
/// group-images.
class StorageService {
  StorageService._();

  static SupabaseClient get _client => SupabaseService.client;

  static String _ext(String path, String fallback) {
    final parts = path.split('.');
    if (parts.length < 2) return fallback;
    final ext = parts.last.toLowerCase().split('?').first;
    if (ext.length > 5 || ext.isEmpty) return fallback;
    return ext;
  }

  /// Downscale + recompress images client-side before upload.
  static Future<Uint8List> compressImage(
    Uint8List bytes, {
    int maxDimension = 1280,
    int quality = 82,
  }) async {
    try {
      final decoded = await Future(() => img.decodeImage(bytes));
      if (decoded == null) return bytes;
      final longest = decoded.width > decoded.height
          ? decoded.width
          : decoded.height;
      if (longest <= maxDimension) {
        final encoded = img.encodeJpg(decoded, quality: quality);
        return Uint8List.fromList(encoded);
      }
      final scale = maxDimension / longest;
      final resized = img.copyResize(
        decoded,
        width: (decoded.width * scale).round(),
        height: (decoded.height * scale).round(),
      );
      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (_) {
      return bytes;
    }
  }

  static Future<String> _uploadBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
    bool upsert = true,
  }) async {
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: upsert),
        );
    // Buckets are private by default; use a signed URL valid for 1 year so
    // chat media stays accessible without public exposure.
    const expiresIn = 365 * 24 * 3600;
    try {
      final signed =
          await _client.storage.from(bucket).createSignedUrl(path, expiresIn);
      return signed;
    } catch (_) {
      // Fallback to public URL if bucket is public.
      return _client.storage.from(bucket).getPublicUrl(path);
    }
  }

  static Future<String> uploadAvatar(String userId, Uint8List bytes,
      {String sourcePath = 'avatar.jpg'}) async {
    final compressed = await compressImage(bytes,
        maxDimension: 512, quality: 85);
    final ext = _ext(sourcePath, 'jpg');
    final path = '$userId/avatar_${_uuid.v4()}.$ext';
    final mimeType = lookupMimeType(sourcePath) ?? 'image/jpeg';
    return _uploadBytes(
      bucket: 'avatars',
      path: path,
      bytes: compressed,
      contentType: mimeType,
    );
  }

  static Future<void> removeAvatarUrl(String avatarUrl) async {
    // Best-effort: signed URLs embed the path; nothing to delete reliably.
    // Avatar rows are simply overwritten. Intentionally no-op.
  }

  static Future<String> uploadChatImage(Uint8List bytes,
      {String sourcePath = 'image.jpg'}) async {
    final compressed = await compressImage(bytes);
    final ext = _ext(sourcePath, 'jpg');
    final userId = _client.auth.currentUser?.id ?? 'anon';
    final path = '$userId/${_uuid.v4()}.$ext';
    final mimeType = lookupMimeType(sourcePath) ?? 'image/jpeg';
    return _uploadBytes(
      bucket: 'chat-images',
      path: path,
      bytes: compressed,
      contentType: mimeType,
    );
  }

  static Future<String> uploadVoiceMessage(Uint8List bytes,
      {int durationSeconds = 0}) async {
    final userId = _client.auth.currentUser?.id ?? 'anon';
    final path = '$userId/${_uuid.v4()}.m4a';
    return _uploadBytes(
      bucket: 'voice-messages',
      path: path,
      bytes: bytes,
      contentType: 'audio/m4a',
    );
  }

  static Future<String> uploadGroupImage(Uint8List bytes,
      {String sourcePath = 'group.jpg'}) async {
    final compressed = await compressImage(bytes,
        maxDimension: 512, quality: 85);
    final ext = _ext(sourcePath, 'jpg');
    final path = 'groups/${_uuid.v4()}.$ext';
    final mimeType = lookupMimeType(sourcePath) ?? 'image/jpeg';
    return _uploadBytes(
      bucket: 'group-images',
      path: path,
      bytes: compressed,
      contentType: mimeType,
    );
  }

  /// Download bytes (used when media auto-download is on, for caching).
  static Future<Uint8List?> downloadBytes(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) return res.bodyBytes;
      return null;
    } catch (_) {
      return null;
    }
  }

  static String decodeStorageError(Object e) {
    final msg = e.toString();
    if (msg.contains('Bucket not found')) {
      return 'Storage bucket missing. Run supabase/schema.sql.';
    }
    return msg.replaceFirst(RegExp(r'^.*Exception:\s*'), '');
  }

  /// Exposed for tests / diagnostics.
  static String debugEncode(Uint8List bytes) => base64Encode(bytes);
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// A published GitHub release.
class GithubRelease {
  final String tag;
  final String name;
  final String htmlUrl;
  final String? apkUrl;
  final String? notes;
  final DateTime? publishedAt;

  const GithubRelease({
    required this.tag,
    required this.name,
    required this.htmlUrl,
    this.apkUrl,
    this.notes,
    this.publishedAt,
  });

  String get versionLabel => tag.replaceFirst(RegExp(r'^[vV]'), '');

  factory GithubRelease.fromJson(Map<String, dynamic> json) {
    String? apk;
    final assets = json['assets'];
    if (assets is List) {
      for (final a in assets) {
        final url = (a as Map)['browser_download_url'] as String?;
        final name = (a['name'] as String?) ?? '';
        if (url != null && name.toLowerCase().endsWith('.apk')) {
          apk = url;
          break;
        }
      }
    }
    DateTime? published;
    try {
      final raw = json['published_at'] as String?;
      if (raw != null) published = DateTime.parse(raw);
    } catch (_) {}
    return GithubRelease(
      tag: (json['tag_name'] as String?) ?? '',
      name: (json['name'] as String?) ?? (json['tag_name'] as String?) ?? '',
      htmlUrl: (json['html_url'] as String?) ?? '',
      apkUrl: apk,
      notes: json['body'] as String?,
      publishedAt: published,
    );
  }
}

/// Result of an update check: a newer release exists.
class UpdateInfo {
  final GithubRelease release;
  final String currentVersion;

  const UpdateInfo({required this.release, required this.currentVersion});
}

/// Checks github.com releases for a newer build. Never throws — returns
/// null when there is no update, no network, or rate-limited.
class UpdateService {
  UpdateService._();

  static const _lastCheckKey = 'update_last_check_ms';
  static const _throttle = Duration(hours: 24);

  static Future<GithubRelease?> fetchLatestRelease() async {
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/${AppConfig.githubOwner}/${AppConfig.githubRepo}/releases/latest',
      );
      final res = await http.get(
        uri,
        headers: {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body);
      if (json is! Map<String, dynamic>) return null;
      final release = GithubRelease.fromJson(json);
      if (release.tag.isEmpty) return null;
      return release;
    } catch (_) {
      return null;
    }
  }

  static List<int> _parts(String version) {
    return version
        .trim()
        .replaceFirst(RegExp(r'^[vV]'), '')
        .split('.')
        .map((e) => int.tryParse(RegExp(r'\d+').firstMatch(e)?.group(0) ?? '0') ?? 0)
        .toList();
  }

  /// True when [latest] is a newer semantic version than [current].
  static bool isNewer(String latest, String current) {
    final l = _parts(latest);
    final c = _parts(current);
    final len = l.length > c.length ? l.length : c.length;
    for (var i = 0; i < len; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv != cv) return lv > cv;
    }
    return false;
  }

  /// Returns update info when a newer release exists, else null.
  /// Throttled to once per day unless [force] is true.
  static Future<UpdateInfo?> checkForUpdate({bool force = false}) async {
    try {
      if (!force) {
        final prefs = await SharedPreferences.getInstance();
        final last = prefs.getInt(_lastCheckKey) ?? 0;
        if (DateTime.now().millisecondsSinceEpoch - last <
            _throttle.inMilliseconds) {
          return null;
        }
      }
      final release = await fetchLatestRelease();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _lastCheckKey, DateTime.now().millisecondsSinceEpoch);
      if (release == null) return null;
      final info = await PackageInfo.fromPlatform();
      if (isNewer(release.tag, info.version)) {
        return UpdateInfo(release: release, currentVersion: info.version);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

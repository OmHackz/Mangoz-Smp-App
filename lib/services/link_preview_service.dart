import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

/// Rich link preview fetched from page metadata.
class LinkPreview {
  final String url;
  final String domain;
  final String? title;
  final String? description;
  final String? imageUrl;

  const LinkPreview({
    required this.url,
    required this.domain,
    this.title,
    this.description,
    this.imageUrl,
  });

  bool get isEmpty => title == null && description == null && imageUrl == null;
}

/// Fetches OpenGraph / meta tags with graceful fallback to a plain link.
/// Never throws — returns null when metadata cannot be retrieved.
class LinkPreviewService {
  LinkPreviewService._();

  static final Map<String, LinkPreview?> _cache = {};

  static String domainOf(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return url;
    }
  }

  static Future<LinkPreview?> fetch(String url) async {
    if (_cache.containsKey(url)) return _cache[url];
    try {
      final uri = Uri.parse(url);
      if (!(uri.scheme == 'http' || uri.scheme == 'https')) return null;
      final res = await http
          .get(uri, headers: {'User-Agent': 'MangoZSMP/1.0'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final contentType = res.headers['content-type'] ?? '';
      if (!contentType.contains('html') && res.body.length > 500000) {
        return null;
      }
      final doc = html_parser.parse(res.body);
      String? meta(String property) {
        final el = doc.querySelector(
            'meta[property="$property"], meta[name="$property"]');
        return el?.attributes['content']?.trim().isEmpty == true
            ? null
            : el?.attributes['content']?.trim();
      }

      final pageTitle =
          doc.querySelector('title')?.text.trim();
      final title = meta('og:title') ??
          (pageTitle?.isEmpty == true ? null : pageTitle);
      final description =
          meta('og:description') ?? meta('description') ?? meta('twitter:description');
      var image = meta('og:image') ?? meta('twitter:image');
      if (image != null && image.isNotEmpty) {
        try {
          image = uri.resolve(image).toString();
        } catch (_) {}
      }
      final preview = LinkPreview(
        url: url,
        domain: domainOf(url),
        title: title?.isEmpty == true ? null : title,
        description: description?.isEmpty == true ? null : description,
        imageUrl: image?.isEmpty == true ? null : image,
      );
      if (preview.isEmpty) {
        _cache[url] = null;
        return null;
      }
      _cache[url] = preview;
      return preview;
    } catch (_) {
      _cache[url] = null;
      return null;
    }
  }

  static void clearCache() => _cache.clear();
}

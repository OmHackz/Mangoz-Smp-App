/// Map URL helpers: normalization + validation. Never hardcoded in UI.
class MapService {
  MapService._();

  /// Normalize user input into a loadable URL. Supports HTTP and HTTPS.
  static String normalize(String input) {
    var v = input.trim();
    if (v.isEmpty) return v;
    if (!v.contains('://')) v = 'http://$v';
    // Strip trailing slash for consistency (WebView handles either).
    if (v.endsWith('/') && v.length > 'http://x'.length) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }

  static String? validate(String input) {
    final v = input.trim();
    if (v.isEmpty) return 'Map URL is required.';
    final uri = Uri.tryParse(normalize(v));
    if (uri == null || uri.host.isEmpty) return 'Map URL is invalid.';
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'Map URL must start with http:// or https://.';
    }
    return null;
  }

  static Uri toUri(String input) => Uri.parse(normalize(input));
}

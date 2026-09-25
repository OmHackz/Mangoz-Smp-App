/// Centralized server configuration. Never hardcode hosts elsewhere.
class ServerConfig {
  final String javaHost;
  final int javaPort;
  final String bedrockHost;
  final int bedrockPort;
  final String mapUrl;
  final Duration statusRefreshInterval;

  const ServerConfig({
    this.javaHost = 'mangozsmp.seedloaf.gg',
    this.javaPort = 56928,
    this.bedrockHost = 'mangozsmp.seedloaf.gg',
    this.bedrockPort = 54992,
    this.mapUrl = 'http://mangozsmp.seedloaf.gg:51260',
    this.statusRefreshInterval = const Duration(seconds: 60),
  });

  String get javaAddress => '$javaHost:$javaPort';
  String get bedrockAddress => '$bedrockHost:$bedrockPort';

  ServerConfig copyWith({
    String? javaHost,
    int? javaPort,
    String? bedrockHost,
    int? bedrockPort,
    String? mapUrl,
    Duration? statusRefreshInterval,
  }) {
    return ServerConfig(
      javaHost: javaHost ?? this.javaHost,
      javaPort: javaPort ?? this.javaPort,
      bedrockHost: bedrockHost ?? this.bedrockHost,
      bedrockPort: bedrockPort ?? this.bedrockPort,
      mapUrl: mapUrl ?? this.mapUrl,
      statusRefreshInterval:
          statusRefreshInterval ?? this.statusRefreshInterval,
    );
  }

  Map<String, dynamic> toJson() => {
        'javaHost': javaHost,
        'javaPort': javaPort,
        'bedrockHost': bedrockHost,
        'bedrockPort': bedrockPort,
        'mapUrl': mapUrl,
        'statusRefreshIntervalSeconds': statusRefreshInterval.inSeconds,
      };

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      javaHost: json['javaHost'] as String? ?? 'mangozsmp.seedloaf.gg',
      javaPort: (json['javaPort'] as num?)?.toInt() ?? 56928,
      bedrockHost: json['bedrockHost'] as String? ?? 'mangozsmp.seedloaf.gg',
      bedrockPort: (json['bedrockPort'] as num?)?.toInt() ?? 54992,
      mapUrl: json['mapUrl'] as String? ?? 'http://mangozsmp.seedloaf.gg:51260',
      statusRefreshInterval: Duration(
        seconds: (json['statusRefreshIntervalSeconds'] as num?)?.toInt() ?? 60,
      ),
    );
  }

  /// Basic validation used by Settings before saving.
  String? validate() {
    if (javaHost.trim().isEmpty) return 'Java hostname is required.';
    if (bedrockHost.trim().isEmpty) return 'Bedrock hostname is required.';
    if (javaPort <= 0 || javaPort > 65535) return 'Java port is invalid.';
    if (bedrockPort <= 0 || bedrockPort > 65535) {
      return 'Bedrock port is invalid.';
    }
    final uri = Uri.tryParse(mapUrl.trim());
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return 'Map URL must be http(s)://host[:port].';
    }
    if (statusRefreshInterval.inSeconds < 15) {
      return 'Refresh interval must be at least 15 seconds.';
    }
    return null;
  }
}

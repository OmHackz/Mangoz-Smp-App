enum ServerEdition { java, bedrock }

/// Result of a single server status check. Never faked — offline means the
/// status API / probe actually failed or reported offline.
class ServerStatus {
  final ServerEdition edition;
  final String host;
  final int port;
  final bool online;
  final int playersOnline;
  final int playersMax;
  final int? pingMs;
  final String? version;
  final String? motd;
  final DateTime lastChecked;
  final String? error;

  const ServerStatus({
    required this.edition,
    required this.host,
    required this.port,
    required this.online,
    this.playersOnline = 0,
    this.playersMax = 0,
    this.pingMs,
    this.version,
    this.motd,
    required this.lastChecked,
    this.error,
  });

  String get address => '$host:$port';

  String get playersLabel => '$playersOnline / $playersMax players';

  String get pingLabel => pingMs == null ? 'Ping: —' : 'Ping: $pingMs ms';

  factory ServerStatus.offline({
    required ServerEdition edition,
    required String host,
    required int port,
    String? error,
  }) {
    return ServerStatus(
      edition: edition,
      host: host,
      port: port,
      online: false,
      lastChecked: DateTime.now(),
      error: error ?? 'Unable to connect',
    );
  }
}

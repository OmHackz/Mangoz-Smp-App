import 'dart:async';

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/app_config.dart';
import '../models/server_status.dart';

/// Clean abstraction for Minecraft server status. The UI never cares whether
/// the data comes from a direct probe or a status API — this implementation
/// uses the public mcsrvstat.us API which works on mobile without raw
/// TCP/UDP sockets, plus local HTTP latency as the ping measurement.
abstract class ServerStatusService {
  Future<ServerStatus> checkJavaServer(String host, int port);
  Future<ServerStatus> checkBedrockServer(String host, int port);
}

class McSrvStatStatusService implements ServerStatusService {
  final http.Client _http;
  final Duration timeout;

  McSrvStatStatusService(
      {http.Client? httpClient,
      this.timeout = AppConfig.statusTimeout})
      : _http = httpClient ?? http.Client();

  @override
  Future<ServerStatus> checkJavaServer(String host, int port) async {
    final started = DateTime.now();
    final address = '$host:$port';
    final uri = Uri.parse('https://api.mcsrvstat.us/3/$address');
    try {
      final res =
          await _http.get(uri).timeout(timeout);
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      if (res.statusCode != 200) {
        return ServerStatus.offline(
          edition: ServerEdition.java,
          host: host,
          port: port,
          error: 'Status API returned ${res.statusCode}',
        );
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final online = json['online'] == true;
      if (!online) {
        final debug = json['debug'] as Map<String, dynamic>?;
        return ServerStatus.offline(
          edition: ServerEdition.java,
          host: host,
          port: port,
          error: _debugReason(debug) ?? 'Server offline',
        );
      }
      final players = json['players'] as Map<String, dynamic>?;
      final version = json['version'];
      final motd = json['motd'];
      return ServerStatus(
        edition: ServerEdition.java,
        host: host,
        port: port,
        online: true,
        playersOnline:
            (players?['online'] as num?)?.toInt() ?? 0,
        playersMax: (players?['max'] as num?)?.toInt() ?? 0,
        pingMs: elapsed,
        version: version is String
            ? version
            : (version as Map?)?['name']?.toString(),
        motd: _motdToString(motd),
        lastChecked: DateTime.now(),
      );
    } on TimeoutException {
      return ServerStatus.offline(
        edition: ServerEdition.java,
        host: host,
        port: port,
        error: 'Timed out — server may be offline.',
      );
    } catch (e) {
      return ServerStatus.offline(
        edition: ServerEdition.java,
        host: host,
        port: port,
        error: 'Unable to connect (${_shortError(e)}).',
      );
    }
  }

  @override
  Future<ServerStatus> checkBedrockServer(String host, int port) async {
    final started = DateTime.now();
    final address = '$host:$port';
    final uri = Uri.parse('https://api.mcsrvstat.us/bedrock/3/$address');
    try {
      final res =
          await _http.get(uri).timeout(timeout);
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      if (res.statusCode != 200) {
        return ServerStatus.offline(
          edition: ServerEdition.bedrock,
          host: host,
          port: port,
          error: 'Status API returned ${res.statusCode}',
        );
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final online = json['online'] == true;
      if (!online) {
        final debug = json['debug'] as Map<String, dynamic>?;
        return ServerStatus.offline(
          edition: ServerEdition.bedrock,
          host: host,
          port: port,
          error: _debugReason(debug) ?? 'Server offline',
        );
      }
      final players = json['players'] as Map<String, dynamic>?;
      final version = json['version'];
      final motd = json['motd'];
      return ServerStatus(
        edition: ServerEdition.bedrock,
        host: host,
        port: port,
        online: true,
        playersOnline:
            (players?['online'] as num?)?.toInt() ?? 0,
        playersMax: (players?['max'] as num?)?.toInt() ?? 0,
        pingMs: elapsed,
        version: version is String
            ? version
            : (version as Map?)?['name']?.toString(),
        motd: _motdToString(motd),
        lastChecked: DateTime.now(),
      );
    } on TimeoutException {
      return ServerStatus.offline(
        edition: ServerEdition.bedrock,
        host: host,
        port: port,
        error: 'Timed out — server may be offline.',
      );
    } catch (e) {
      return ServerStatus.offline(
        edition: ServerEdition.bedrock,
        host: host,
        port: port,
        error: 'Unable to connect (${_shortError(e)}).',
      );
    }
  }

  String? _debugReason(Map<String, dynamic>? debug) {
    if (debug == null) return null;
    // mcsrvstat debug contains query/error hints.
    final err = debug['error'] ?? debug['queryerror'];
    if (err is Map && err['message'] is String) {
      return err['message'] as String;
    }
    if (err is String && err.isNotEmpty) return err;
    return null;
  }

  String _motdToString(dynamic motd) {
    if (motd == null) return '';
    if (motd is String) return motd.trim();
    if (motd is Map) {
      final clean = motd['clean'];
      if (clean is List) return clean.join('\n').trim();
      if (clean is String) return clean.trim();
      final raw = motd['raw'];
      if (raw is List) return raw.join('\n').trim();
      if (raw is String) return raw.trim();
    }
    return motd.toString().trim();
  }

  String _shortError(Object e) {
    final s = e.toString();
    if (s.contains('SocketException')) return 'no route to host';
    if (s.length > 80) return '${s.substring(0, 80)}…';
    return s;
  }
}

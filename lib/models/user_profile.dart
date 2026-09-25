/// Public user profile stored in `profiles`.
class UserProfile {
  final String id;
  final String username;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSeen;
  final bool isOnline;

  const UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
    this.lastSeen,
    this.isOnline = false,
  });

  String get displayHandle => '@$username';

  String get initial {
    if (username.isEmpty) return '?';
    return username[0].toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v as String);
      } catch (_) {
        return null;
      }
    }

    return UserProfile(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'unknown',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      lastSeen: parseDate(json['last_seen']),
      isOnline: _computeOnline(parseDate(json['last_seen'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'avatar_url': avatarUrl,
      };

  static bool _computeOnline(DateTime? lastSeen) {
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen).inMinutes < 5;
  }

  UserProfile copyWith({
    String? username,
    String? avatarUrl,
    DateTime? lastSeen,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: _computeOnline(lastSeen ?? this.lastSeen),
    );
  }

  /// Client-side username validation (server enforces uniqueness).
  static String? validateUsername(String value) {
    final v = value.trim().replaceFirst(RegExp(r'^@'), '');
    if (v.isEmpty) return 'Username is required.';
    if (v.length < 3) return 'Username must be at least 3 characters.';
    if (v.length > 24) return 'Username must be 24 characters or fewer.';
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(v)) {
      return 'Only letters, numbers and underscore.';
    }
    return null;
  }

  static String normalizeUsername(String value) =>
      value.trim().replaceFirst(RegExp(r'^@'), '');
}

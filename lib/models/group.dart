/// Group member row joined with profile for display.
class GroupMember {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;

  const GroupMember({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.role = 'member',
    required this.joinedAt,
  });

  bool get isAdmin => role == 'admin' || role == 'owner';

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v as String).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }

    final profile = json['profiles'] as Map<String, dynamic>?;
    return GroupMember(
      userId: json['user_id'] as String? ?? '',
      username: (profile?['username'] as String?) ??
          (json['username'] as String?) ??
          'unknown',
      avatarUrl: (profile?['avatar_url'] as String?) ??
          (json['avatar_url'] as String?),
      role: json['role'] as String? ?? 'member',
      joinedAt: parseDate(json['joined_at']),
    );
  }
}

/// Lightweight group descriptor (backed by a `Chat` of type group).
class Group {
  final String id;
  final String name;
  final String? imageUrl;
  final String? description;
  final String? createdBy;
  final int memberCount;

  const Group({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    this.createdBy,
    this.memberCount = 0,
  });
}

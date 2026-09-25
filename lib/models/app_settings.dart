/// Persisted user preferences. Every field is wired to real behavior.
class AppSettings {
  final String themeMode; // system | light | dark
  final bool linkPreviewsEnabled;
  final bool mediaAutoDownload;
  final bool enterToSend;
  final bool messageSounds;
  final bool vibration;
  final bool chatNotifications;
  final bool groupNotifications;
  final bool serverNotifications;
  final bool showOnlineStatus;
  final String profileVisibility; // everyone | contacts | nobody
  final String whoCanMessage; // everyone | contacts
  final double messageTextScale;
  final bool oreIntensityHigh;

  const AppSettings({
    this.themeMode = 'system',
    this.linkPreviewsEnabled = true,
    this.mediaAutoDownload = true,
    this.enterToSend = false,
    this.messageSounds = true,
    this.vibration = true,
    this.chatNotifications = true,
    this.groupNotifications = true,
    this.serverNotifications = true,
    this.showOnlineStatus = true,
    this.profileVisibility = 'everyone',
    this.whoCanMessage = 'everyone',
    this.messageTextScale = 1.0,
    this.oreIntensityHigh = true,
  });

  AppSettings copyWith({
    String? themeMode,
    bool? linkPreviewsEnabled,
    bool? mediaAutoDownload,
    bool? enterToSend,
    bool? messageSounds,
    bool? vibration,
    bool? chatNotifications,
    bool? groupNotifications,
    bool? serverNotifications,
    bool? showOnlineStatus,
    String? profileVisibility,
    String? whoCanMessage,
    double? messageTextScale,
    bool? oreIntensityHigh,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      linkPreviewsEnabled: linkPreviewsEnabled ?? this.linkPreviewsEnabled,
      mediaAutoDownload: mediaAutoDownload ?? this.mediaAutoDownload,
      enterToSend: enterToSend ?? this.enterToSend,
      messageSounds: messageSounds ?? this.messageSounds,
      vibration: vibration ?? this.vibration,
      chatNotifications: chatNotifications ?? this.chatNotifications,
      groupNotifications: groupNotifications ?? this.groupNotifications,
      serverNotifications: serverNotifications ?? this.serverNotifications,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      whoCanMessage: whoCanMessage ?? this.whoCanMessage,
      messageTextScale: messageTextScale ?? this.messageTextScale,
      oreIntensityHigh: oreIntensityHigh ?? this.oreIntensityHigh,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'linkPreviewsEnabled': linkPreviewsEnabled,
        'mediaAutoDownload': mediaAutoDownload,
        'enterToSend': enterToSend,
        'messageSounds': messageSounds,
        'vibration': vibration,
        'chatNotifications': chatNotifications,
        'groupNotifications': groupNotifications,
        'serverNotifications': serverNotifications,
        'showOnlineStatus': showOnlineStatus,
        'profileVisibility': profileVisibility,
        'whoCanMessage': whoCanMessage,
        'messageTextScale': messageTextScale,
        'oreIntensityHigh': oreIntensityHigh,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: json['themeMode'] as String? ?? 'system',
      linkPreviewsEnabled: json['linkPreviewsEnabled'] as bool? ?? true,
      mediaAutoDownload: json['mediaAutoDownload'] as bool? ?? true,
      enterToSend: json['enterToSend'] as bool? ?? false,
      messageSounds: json['messageSounds'] as bool? ?? true,
      vibration: json['vibration'] as bool? ?? true,
      chatNotifications: json['chatNotifications'] as bool? ?? true,
      groupNotifications: json['groupNotifications'] as bool? ?? true,
      serverNotifications: json['serverNotifications'] as bool? ?? true,
      showOnlineStatus: json['showOnlineStatus'] as bool? ?? true,
      profileVisibility: json['profileVisibility'] as String? ?? 'everyone',
      whoCanMessage: json['whoCanMessage'] as String? ?? 'everyone',
      messageTextScale:
          (json['messageTextScale'] as num?)?.toDouble() ?? 1.0,
      oreIntensityHigh: json['oreIntensityHigh'] as bool? ?? true,
    );
  }
}

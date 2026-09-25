/// Central application configuration. No secrets here.
class AppConfig {
  const AppConfig._();

  static const String appName = 'MangoZ SMP';
  static const String appVersion = '0.1.1';
  static const int appBuildNumber = 2;

  static const String serverDisplayName = 'MangoZ SMP';

  // Feature flags — server owner can flip these at build time via
  // --dart-define if needed, otherwise defaults apply.
  static const bool enableVoiceMessages =
      bool.fromEnvironment('FEATURE_VOICE', defaultValue: true);
  static const bool enableLinkPreviews =
      bool.fromEnvironment('FEATURE_LINK_PREVIEW', defaultValue: true);
  static const bool enableGroups =
      bool.fromEnvironment('FEATURE_GROUPS', defaultValue: true);

  static const Duration statusRefreshDefault = Duration(seconds: 60);
  static const Duration statusTimeout = Duration(seconds: 12);

  static const int minesweeperTapThreshold = 7;
}

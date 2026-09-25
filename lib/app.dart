import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

import 'providers/app_providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/profile_picture_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/username_screen.dart';
import 'screens/chats/chat_screen.dart';
import 'screens/chats/chat_settings_screen.dart';
import 'screens/chats/chats_screen.dart';
import 'screens/chats/group_info_screen.dart';
import 'screens/chats/new_chat_screen.dart';
import 'screens/chats/new_group_screen.dart';
import 'screens/games/minesweeper_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/home/main_shell.dart';
import 'screens/map/server_map_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/user_profile_screen.dart';
import 'screens/server/server_screen.dart';
import 'screens/settings/account_settings_screen.dart';
import 'screens/settings/app_settings_screen.dart';
import 'screens/settings/appearance_settings_screen.dart';
import 'screens/settings/chat_settings_screen.dart';
import 'screens/settings/notification_settings_screen.dart';
import 'screens/settings/privacy_settings_screen.dart';
import 'screens/settings/server_settings_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

/// Root app: Ore theme + Material theme + named routes.
class MangoZApp extends ConsumerWidget {
  const MangoZApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final controller = OreThemeController(
      brightness: themeMode == ThemeMode.light
          ? Brightness.light
          : themeMode == ThemeMode.dark
              ? Brightness.dark
              : WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );

    return OreThemeBuilder(
      controller: controller,
      builder: (context, oreData, brightness) {
        // Keep Ore controller in sync with settings when system changes.
        final resolved = themeMode == ThemeMode.system
            ? brightness
            : (themeMode == ThemeMode.light
                ? Brightness.light
                : Brightness.dark);
        if (controller.brightness != resolved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.brightness = resolved;
          });
        }
        return MaterialApp(
          title: 'MangoZ SMP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          initialRoute: '/splash',
          onGenerateRoute: _routes,
        );
      },
    );
  }

  Route<dynamic>? _routes(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/splash':
        page = const SplashScreen();
        break;
      case '/login':
        page = const LoginScreen();
        break;
      case '/register':
        page = const RegisterScreen();
        break;
      case '/username':
        page = const UsernameScreen();
        break;
      case '/profile-picture':
        page = const ProfilePictureScreen();
        break;
      case '/home':
        page = const MainShell();
        break;
      case '/chats':
        page = const ChatsScreen();
        break;
      case '/chat':
        final id = settings.arguments as String? ?? '';
        page = ChatScreen(conversationId: id);
        break;
      case '/new-chat':
        page = const NewChatScreen();
        break;
      case '/new-group':
        page = const NewGroupScreen();
        break;
      case '/group-info':
        final id = settings.arguments as String? ?? '';
        page = GroupInfoScreen(conversationId: id);
        break;
      case '/chat-settings':
        final id = settings.arguments as String? ?? '';
        page = ChatSettingsScreen(conversationId: id);
        break;
      case '/global-chat-settings':
        page = const ChatSettingsPage();
        break;
      case '/map':
        page = const ServerMapScreen();
        break;
      case '/server':
        page = const ServerScreen();
        break;
      case '/dashboard':
        page = const DashboardScreen();
        break;
      case '/profile':
        page = const ProfileScreen();
        break;
      case '/user-profile':
        final id = settings.arguments as String? ?? '';
        page = UserProfileScreen(userId: id);
        break;
      case '/settings':
        page = const SettingsScreen();
        break;
      case '/account-settings':
        page = const AccountSettingsScreen();
        break;
      case '/appearance-settings':
        page = const AppearanceSettingsScreen();
        break;
      case '/notification-settings':
        page = const NotificationSettingsScreen();
        break;
      case '/privacy-settings':
        page = const PrivacySettingsScreen();
        break;
      case '/server-settings':
        page = const ServerSettingsScreen();
        break;
      case '/app-settings':
        page = const AppSettingsScreen();
        break;
      case '/minesweeper':
        page = const MinesweeperScreen();
        break;
      default:
        page = const SplashScreen();
    }
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}

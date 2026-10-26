import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'providers/player_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/startup_screen.dart';
import 'services/playlist_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final storageService = await StorageService.init();
  final playlistService = PlaylistService(storageService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(storageService),
        ),
        ChangeNotifierProvider<PlaylistProvider>(
          create: (_) => PlaylistProvider(playlistService, storageService),
        ),
        ChangeNotifierProvider<PlayerProvider>(create: (_) => PlayerProvider()),
      ],
      child: const ZainIPTVApp(),
    ),
  );
}

class ZainIPTVApp extends StatelessWidget {
  static const appTitle = "ZAIN'S IPTV";

  const ZainIPTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const StartupScreen(),
    );
  }
}

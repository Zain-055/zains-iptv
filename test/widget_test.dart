import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zains_iptv/main.dart';
import 'package:zains_iptv/providers/player_provider.dart';
import 'package:zains_iptv/providers/playlist_provider.dart';
import 'package:zains_iptv/providers/settings_provider.dart';
import 'package:zains_iptv/services/playlist_service.dart';
import 'package:zains_iptv/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App renders StartupScreen with ZAIN\'S IPTV title', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final playlistService = PlaylistService(storageService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(storageService),
          ),
          ChangeNotifierProvider<PlaylistProvider>(
            create: (_) => PlaylistProvider(playlistService, storageService),
          ),
          ChangeNotifierProvider<PlayerProvider>(
            create: (_) => PlayerProvider(),
          ),
        ],
        child: const ZainIPTVApp(),
      ),
    );

    await tester.pump();

    expect(find.text("ZAIN'S IPTV"), findsOneWidget);
  });
}

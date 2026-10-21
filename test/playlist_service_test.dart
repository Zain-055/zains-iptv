import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zains_iptv/services/playlist_service.dart';
import 'package:zains_iptv/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'combines channels and categories from multiple playlist URLs',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final storageService = StorageService(preferences);
      final requestedUrls = <Uri>[];
      final client = MockClient((request) async {
        requestedUrls.add(request.url);
        final channelName = request.url.pathSegments.last;
        final category = channelName == 'news.m3u' ? 'News' : 'Sports';
        return http.Response(
          '#EXTM3U\n#EXTINF:-1 group-title="$category",$channelName\n'
          'https://streams.example.com/$channelName\n',
          200,
        );
      });
      final service = PlaylistService(storageService, client: client);

      try {
        final result = await service.loadFromUrls([
          'https://playlists.example.com/news.m3u',
          'https://playlists.example.com/sports.m3u',
        ]);

        expect(result.playlist.channels, hasLength(2));
        expect(result.playlist.categories, containsAll(['News', 'Sports']));
        expect(
          storageService.getSavedSourcePathOrUrl(),
          'https://playlists.example.com/news.m3u\n'
          'https://playlists.example.com/sports.m3u',
        );
        expect(requestedUrls.map((uri) => uri.host), [
          'playlists.example.com',
          'playlists.example.com',
        ]);
      } finally {
        client.close();
      }
    },
  );

  test(
    'keeps unavailable HTTP streams from URL playlists selectable',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final storageService = StorageService(preferences);
      final playlistContent = '''
#EXTM3U
#EXTINF:-1 group-title="News",Available News
https://streams.example.com/live.m3u8
#EXTINF:-1 group-title="Sports",Unavailable Sports
https://streams.example.com/dead.m3u8
''';
      final requestedUrls = <Uri>[];
      final client = MockClient((request) async {
        requestedUrls.add(request.url);
        if (request.url.path == '/channels.m3u') {
          return http.Response(playlistContent, 200);
        }
        return http.Response('Not found', 404);
      });
      final service = PlaylistService(storageService, client: client);

      try {
        final result = await service.loadFromUrl(
          'https://playlists.example.com/channels.m3u',
        );

        expect(result.playlist.channels.map((channel) => channel.name), [
          'Available News',
          'Unavailable Sports',
        ]);
        expect(result.playlist.categories, ['News', 'Sports']);
        expect(result.errorMessage, isNull);
        expect(requestedUrls.map((uri) => uri.host), ['playlists.example.com']);
      } finally {
        client.close();
      }
    },
  );

  test('keeps unavailable local playlist streams selectable', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storageService = StorageService(preferences);
    final directory = await Directory.systemTemp.createTemp(
      'zains-iptv-playlist-test-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    const playlistContent = '''
#EXTM3U
#EXTINF:-1 group-title="News",Available News
https://streams.example.com/live.m3u8
#EXTINF:-1 group-title="Sports",Unavailable Sports
https://streams.example.com/dead.m3u8
''';
    final file = File('${directory.path}${Platform.pathSeparator}channels.m3u');
    await file.writeAsString(playlistContent);
    final requestedUrls = <Uri>[];
    final client = MockClient((request) async {
      requestedUrls.add(request.url);
      return http.Response('Not found', 404);
    });
    final service = PlaylistService(storageService, client: client);

    try {
      final result = await service.loadFromFile(file.path);

      expect(result.playlist.channels.map((channel) => channel.name), [
        'Available News',
        'Unavailable Sports',
      ]);
      expect(await file.readAsString(), playlistContent);
      expect(result.errorMessage, isNull);
      expect(requestedUrls, isEmpty);
    } finally {
      client.close();
    }
  });
}

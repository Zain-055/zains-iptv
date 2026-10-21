import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zains_iptv/models/channel.dart';
import 'package:zains_iptv/models/playlist.dart';
import 'package:zains_iptv/providers/playlist_provider.dart';
import 'package:zains_iptv/services/playlist_service.dart';
import 'package:zains_iptv/services/storage_service.dart';

class FakePlaylistService implements PlaylistService {
  final Playlist samplePlaylist;
  List<String>? receivedUrls;

  FakePlaylistService(this.samplePlaylist);

  @override
  void dispose() {}

  @override
  Future<PlaylistLoadResult> loadFromFile(String filePath) async {
    return PlaylistLoadResult(playlist: samplePlaylist);
  }

  @override
  Future<PlaylistLoadResult> loadFromUrl(String url) async {
    return PlaylistLoadResult(playlist: samplePlaylist);
  }

  @override
  Future<PlaylistLoadResult> loadFromUrls(List<String> urls) async {
    receivedUrls = urls;
    return PlaylistLoadResult(playlist: samplePlaylist);
  }

  @override
  Future<PlaylistLoadResult?> loadSavedPlaylist() async {
    return PlaylistLoadResult(playlist: samplePlaylist);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late Playlist samplePlaylist;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    storageService = StorageService(prefs);

    samplePlaylist = Playlist(
      sourceType: PlaylistSourceType.url,
      sourcePathOrUrl: 'https://example.com/playlist.m3u',
      name: 'Test Playlist',
      loadedAt: DateTime.now(),
      channels: const [
        Channel(
          id: 'ch_1',
          name: 'BBC News',
          url: 'https://stream1.com',
          groupTitle: 'News',
        ),
        Channel(
          id: 'ch_2',
          name: 'CNN',
          url: 'https://stream2.com',
          groupTitle: 'News',
        ),
        Channel(
          id: 'ch_3',
          name: 'ESPN',
          url: 'https://stream3.com',
          groupTitle: 'Sports',
        ),
      ],
      categories: const ['News', 'Sports'],
    );
  });

  test(
    'PlaylistProvider filters channels by category and search query correctly',
    () async {
      final fakeService = FakePlaylistService(samplePlaylist);
      final provider = PlaylistProvider(fakeService, storageService);

      await provider.initializeAndLoadSaved();

      expect(provider.status, equals(PlaylistStatus.loaded));
      expect(provider.allChannels.length, equals(3));
      expect(provider.channelNumberFor(provider.allChannels[0]), equals(1));
      expect(provider.channelNumberFor(provider.allChannels[2]), equals(3));

      // Category filter
      provider.selectCategory('News');
      expect(provider.filteredChannels.length, equals(2));
      expect(provider.filteredChannels[0].name, equals('BBC News'));

      // Search query filter
      provider.setSearchQuery('ESPN');
      expect(provider.filteredChannels.length, equals(1));
      expect(provider.filteredChannels[0].name, equals('ESPN'));
      expect(
        provider.channelNumberFor(provider.filteredChannels[0]),
        equals(3),
      );

      // Reset search query & test favorites
      provider.setSearchQuery('');
      final channelToFavorite = provider.allChannels[0];
      await provider.toggleFavorite(channelToFavorite);

      provider.selectCategory('Favorites');
      expect(provider.filteredChannels.length, equals(1));
      expect(provider.filteredChannels[0].name, equals('BBC News'));
    },
  );

  test('PlaylistProvider loads multiple playlist URLs', () async {
    final fakeService = FakePlaylistService(samplePlaylist);
    final provider = PlaylistProvider(fakeService, storageService);
    final urls = [
      'https://example.com/news.m3u',
      'https://example.com/sports.m3u',
    ];

    final loaded = await provider.loadFromUrls(urls);

    expect(loaded, isTrue);
    expect(fakeService.receivedUrls, equals(urls));
    expect(provider.allChannels.length, equals(3));
  });
}

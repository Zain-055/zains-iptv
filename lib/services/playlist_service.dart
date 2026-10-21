import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/playlist.dart';
import 'm3u_parser.dart';
import 'storage_service.dart';

class PlaylistLoadResult {
  final Playlist playlist;
  final bool isFromCache;
  final String? errorMessage;

  const PlaylistLoadResult({
    required this.playlist,
    this.isFromCache = false,
    this.errorMessage,
  });
}

class PlaylistService {
  final StorageService _storageService;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  PlaylistService(this._storageService, {http.Client? client})
    : _httpClient = client ?? http.Client(),
      _ownsHttpClient = client == null;

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  /// Load M3U playlist from a remote URL.
  Future<PlaylistLoadResult> loadFromUrl(String url) async {
    return loadFromUrls([url]);
  }

  /// Load and combine channels from multiple remote playlists.
  Future<PlaylistLoadResult> loadFromUrls(List<String> urls) async {
    final cleanUrls = urls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();
    if (cleanUrls.isEmpty) {
      throw Exception('Enter at least one playlist URL.');
    }

    final results = await Future.wait(
      cleanUrls.map((url) async {
        try {
          return (playlist: await _fetchUrl(url), error: null as String?);
        } catch (e) {
          return (
            playlist: null,
            error: '$url: ${e.toString().replaceAll('Exception: ', '')}',
          );
        }
      }),
    );

    final playlists = results
        .where((result) => result.playlist != null)
        .map((result) => result.playlist!)
        .toList();
    final failures = results
        .where((result) => result.error != null)
        .map((result) => result.error!)
        .toList();

    if (playlists.isEmpty) {
      final cachedJson = await _storageService.readCachedPlaylistJson();
      if (cachedJson != null) {
        try {
          final cachedPlaylist = Playlist.fromJson(cachedJson);
          return PlaylistLoadResult(
            playlist: cachedPlaylist,
            isFromCache: true,
            errorMessage: 'Unable to refresh playlists. Using the saved playlist.',
          );
        } catch (e) {
          throw Exception('Unable to read the saved playlist: $e');
        }
      }
      throw Exception('Unable to load any playlist:\n${failures.join('\n')}');
    }

    final channels = playlists.expand((playlist) => playlist.channels).toList();
    final playlistName = playlists.length == 1
        ? playlists.single.name
        : '${playlists.length} Playlists';
    final combinedPlaylist = Playlist(
      sourceType: PlaylistSourceType.url,
      sourcePathOrUrl: cleanUrls.join('\n'),
      name: playlistName,
      loadedAt: DateTime.now(),
      channels: channels,
      categories: playlists
          .expand((playlist) => playlist.categories)
          .toSet()
          .toList()
        ..sort(),
    );
    await _storageService.savePlaylistMetadata(
      sourceType: 'url',
      sourcePathOrUrl: cleanUrls.join('\n'),
      name: playlistName,
    );
    await _storageService.saveCachedPlaylistJson(combinedPlaylist.toJson());

    return PlaylistLoadResult(
      playlist: combinedPlaylist,
      errorMessage: _combineMessages([
        if (failures.isNotEmpty)
          'Some playlists could not be loaded:\n${failures.join('\n')}',
      ]),
    );
  }

  Future<Playlist> _fetchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw Exception(
        'Invalid playlist URL. Enter a valid HTTP or HTTPS address.',
      );
    }

    final headers = {
      'User-Agent': 'ZainsIPTV/1.0 (Android/TV)',
      'Accept': '*/*',
    };
    final response = await _httpClient
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Server returned status code ${response.statusCode}');
    }

    if (response.body.isEmpty) {
      throw Exception('No channels were found in this playlist.');
    }

    final parseResult = await M3uParser.parseAsync(response.body);
    if (parseResult.channels.isEmpty) {
      throw Exception('No channels were found in this playlist.');
    }

    return Playlist(
      sourceType: PlaylistSourceType.url,
      sourcePathOrUrl: url,
      name: uri.host,
      loadedAt: DateTime.now(),
      channels: parseResult.channels,
      categories: parseResult.categories,
    );
  }

  /// Load M3U playlist from a local device file.
  Future<PlaylistLoadResult> loadFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Selected file does not exist.');
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        throw Exception('The selected file is empty.');
      }

      final parseResult = await M3uParser.parseAsync(content);
      if (parseResult.channels.isEmpty) {
        throw Exception('No channels were found in this playlist file.');
      }

      final fileName = file.path.split(Platform.pathSeparator).last;
      final parsedPlaylist = Playlist(
        sourceType: PlaylistSourceType.file,
        sourcePathOrUrl: filePath,
        name: fileName,
        loadedAt: DateTime.now(),
        channels: parseResult.channels,
        categories: parseResult.categories,
      );
      // Persist metadata and local JSON cache
      await _storageService.savePlaylistMetadata(
        sourceType: 'file',
        sourcePathOrUrl: filePath,
        name: fileName,
      );
      await _storageService.saveCachedPlaylistJson(parsedPlaylist.toJson());

      return PlaylistLoadResult(
        playlist: parsedPlaylist,
        isFromCache: false,
      );
    } catch (e) {
      // Check cached fallback
      final cachedJson = await _storageService.readCachedPlaylistJson();
      if (cachedJson != null) {
        try {
          return PlaylistLoadResult(
            playlist: Playlist.fromJson(cachedJson),
            isFromCache: true,
            errorMessage: 'Unable to access the playlist file. Using the saved playlist.',
          );
        } catch (_) {}
      }

      throw Exception(
        'Unable to load playlist file: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// Attempt to load the saved playlist automatically on app launch.
  Future<PlaylistLoadResult?> loadSavedPlaylist() async {
    if (!_storageService.hasSavedPlaylist()) {
      return null;
    }

    final cachedJson = await _storageService.readCachedPlaylistJson();
    if (cachedJson != null) {
      try {
        return PlaylistLoadResult(
          playlist: Playlist.fromJson(cachedJson),
          isFromCache: true,
        );
      } catch (_) {
        // A corrupt cache should not prevent reloading the saved source.
      }
    }

    final sourceType = _storageService.getSavedSourceType();
    final sourcePath = _storageService.getSavedSourcePathOrUrl();

    if (sourcePath == null || sourcePath.isEmpty) {
      return null;
    }

    if (sourceType == 'url') {
      try {
        final urls = sourcePath
            .split('\n')
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList();
        return await loadFromUrls(urls);
      } catch (_) {
        // Fallback to cached file
        final cachedJson = await _storageService.readCachedPlaylistJson();
        if (cachedJson != null) {
          try {
            return PlaylistLoadResult(
              playlist: Playlist.fromJson(cachedJson),
              isFromCache: true,
              errorMessage: 'Unable to refresh playlists. Using the saved playlist.',
            );
          } catch (_) {}
        }
      }
    } else if (sourceType == 'file') {
      try {
        return await loadFromFile(sourcePath);
      } catch (_) {
        // Fallback to cached file
        final cachedJson = await _storageService.readCachedPlaylistJson();
        if (cachedJson != null) {
          try {
            return PlaylistLoadResult(
              playlist: Playlist.fromJson(cachedJson),
              isFromCache: true,
              errorMessage: 'Unable to reload the playlist file. Using the saved playlist.',
            );
          } catch (_) {}
        }
      }
    }

    return null;
  }

  String? _combineMessages(List<String?> messages) {
    final nonEmptyMessages = messages.whereType<String>().toList();
    return nonEmptyMessages.isEmpty ? null : nonEmptyMessages.join('\n');
  }
}

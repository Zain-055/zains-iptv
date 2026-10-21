import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keySourceType = 'playlist_source_type';
  static const String _keySourcePathOrUrl = 'playlist_source_path_or_url';
  static const String _keyPlaylistName = 'playlist_name';
  static const String _keyFavoriteIds = 'favorite_channel_ids';
  static const String _keyLastChannelId = 'last_channel_id';
  static const String _keyRecentlyWatchedIds = 'recently_watched_ids';
  static const String _keyAutoPlay = 'pref_auto_play';
  static const String _keyStartFullscreen = 'pref_start_fullscreen';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Cached Playlist File Management ---

  Future<File> _getCachedPlaylistFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/cached_playlist.json');
  }

  Future<void> saveCachedPlaylistJson(String jsonString) async {
    try {
      final file = await _getCachedPlaylistFile();
      await file.writeAsString(jsonString, flush: true);
    } catch (e) {
      // Fallback or ignore write errors gracefully
    }
  }

  Future<String?> readCachedPlaylistJson() async {
    try {
      final file = await _getCachedPlaylistFile();
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> clearCachedPlaylistFile() async {
    try {
      final file = await _getCachedPlaylistFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  // --- Saved Playlist Settings ---

  Future<void> savePlaylistMetadata({
    required String sourceType,
    required String sourcePathOrUrl,
    required String name,
  }) async {
    await _prefs.setString(_keySourceType, sourceType);
    await _prefs.setString(_keySourcePathOrUrl, sourcePathOrUrl);
    await _prefs.setString(_keyPlaylistName, name);
  }

  String? getSavedSourceType() => _prefs.getString(_keySourceType);
  String? getSavedSourcePathOrUrl() => _prefs.getString(_keySourcePathOrUrl);
  String? getSavedPlaylistName() => _prefs.getString(_keyPlaylistName);

  Future<void> clearPlaylistMetadata() async {
    await _prefs.remove(_keySourceType);
    await _prefs.remove(_keySourcePathOrUrl);
    await _prefs.remove(_keyPlaylistName);
    await clearCachedPlaylistFile();
  }

  bool hasSavedPlaylist() {
    final sourceType = getSavedSourceType();
    final path = getSavedSourcePathOrUrl();
    return sourceType != null && path != null && path.isNotEmpty;
  }

  // --- Favorites ---

  List<String> getFavoriteChannelIds() {
    return _prefs.getStringList(_keyFavoriteIds) ?? [];
  }

  Future<void> saveFavoriteChannelIds(List<String> ids) async {
    await _prefs.setStringList(_keyFavoriteIds, ids);
  }

  // --- Recently Watched & Last Selected Channel ---

  String? getLastChannelId() => _prefs.getString(_keyLastChannelId);

  Future<void> saveLastChannelId(String id) async {
    await _prefs.setString(_keyLastChannelId, id);
    await addRecentlyWatchedId(id);
  }

  List<String> getRecentlyWatchedIds() {
    return _prefs.getStringList(_keyRecentlyWatchedIds) ?? [];
  }

  Future<void> addRecentlyWatchedId(String id) async {
    final list = getRecentlyWatchedIds();
    list.remove(id);
    list.insert(0, id);
    if (list.length > 50) {
      list.removeRange(50, list.length);
    }
    await _prefs.setStringList(_keyRecentlyWatchedIds, list);
  }

  // --- Preferences ---

  bool getAutoPlay() => _prefs.getBool(_keyAutoPlay) ?? true;
  Future<void> setAutoPlay(bool value) async => await _prefs.setBool(_keyAutoPlay, value);

  bool getStartFullscreen() => _prefs.getBool(_keyStartFullscreen) ?? true;
  Future<void> setStartFullscreen(bool value) async => await _prefs.setBool(_keyStartFullscreen, value);

}

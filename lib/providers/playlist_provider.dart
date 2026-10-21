import 'package:flutter/foundation.dart';

import '../models/channel.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import '../services/storage_service.dart';

enum PlaylistStatus { initial, loading, loaded, error }

class PlaylistProvider extends ChangeNotifier {
  final PlaylistService _playlistService;
  final StorageService _storageService;

  PlaylistStatus _status = PlaylistStatus.initial;
  Playlist? _playlist;
  String? _errorMessage;
  bool _isFromCache = false;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  Set<String> _favoriteIds = {};
  List<String> _recentlyWatchedIds = [];
  Channel? _selectedChannel;
  Map<Channel, int> _channelNumbers = {};

  PlaylistProvider(this._playlistService, this._storageService) {
    _loadFavoritesAndRecentlyWatched();
  }

  @override
  void dispose() {
    _playlistService.dispose();
    super.dispose();
  }

  PlaylistStatus get status => _status;
  Playlist? get playlist => _playlist;
  String? get errorMessage => _errorMessage;
  bool get isFromCache => _isFromCache;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  Set<String> get favoriteIds => _favoriteIds;
  Channel? get selectedChannel => _selectedChannel;

  void _loadFavoritesAndRecentlyWatched() {
    _favoriteIds = _storageService.getFavoriteChannelIds().toSet();
    _recentlyWatchedIds = _storageService.getRecentlyWatchedIds();
  }

  Future<bool> initializeAndLoadSaved() async {
    _status = PlaylistStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _playlistService.loadSavedPlaylist();
      if (result != null) {
        _applyLoadResult(result);
        return true;
      } else {
        _status = PlaylistStatus.initial;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = PlaylistStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadFromUrl(String url) async {
    return loadFromUrls([url]);
  }

  Future<bool> loadFromUrls(List<String> urls) async {
    _status = PlaylistStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _playlistService.loadFromUrls(urls);
      _applyLoadResult(result);
      return true;
    } catch (e) {
      _status = PlaylistStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadFromFile(String filePath) async {
    _status = PlaylistStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _playlistService.loadFromFile(filePath);
      _applyLoadResult(result);
      return true;
    } catch (e) {
      _status = PlaylistStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshPlaylist() async {
    if (_playlist == null) return;

    if (_playlist!.sourceType == PlaylistSourceType.url) {
      await loadFromUrl(_playlist!.sourcePathOrUrl);
    } else {
      await loadFromFile(_playlist!.sourcePathOrUrl);
    }
  }

  Future<void> refreshPlaylistInBackground() async {
    final playlist = _playlist;
    if (playlist == null) return;

    try {
      final result = playlist.sourceType == PlaylistSourceType.url
          ? await _playlistService.loadFromUrls(
              playlist.sourcePathOrUrl.split('\n'),
            )
          : await _playlistService.loadFromFile(playlist.sourcePathOrUrl);
      _applyLoadResult(result);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> clearPlaylist() async {
    await _storageService.clearPlaylistMetadata();
    _playlist = null;
    _channelNumbers = {};
    _status = PlaylistStatus.initial;
    _errorMessage = null;
    _selectedCategory = 'All';
    _searchQuery = '';
    _selectedChannel = null;
    notifyListeners();
  }

  void _applyLoadResult(PlaylistLoadResult result) {
    _playlist = result.playlist;
    _channelNumbers = {
      for (var index = 0; index < _playlist!.channels.length; index++)
        _playlist!.channels[index]: index + 1,
    };
    _isFromCache = result.isFromCache;
    _errorMessage = result.errorMessage;
    _status = PlaylistStatus.loaded;

    // Restore last selected channel if possible
    final lastId = _storageService.getLastChannelId();
    if (lastId != null && _playlist!.channels.isNotEmpty) {
      try {
        _selectedChannel = _playlist!.channels.firstWhere(
          (c) => c.id == lastId,
          orElse: () => _playlist!.channels.first,
        );
      } catch (_) {
        _selectedChannel = _playlist!.channels.first;
      }
    }

    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectChannel(Channel channel) {
    _selectedChannel = channel;
    _storageService.saveLastChannelId(channel.id);
    _recentlyWatchedIds = _storageService.getRecentlyWatchedIds();
    notifyListeners();
  }

  Future<void> toggleFavorite(Channel channel) async {
    if (_favoriteIds.contains(channel.id)) {
      _favoriteIds.remove(channel.id);
    } else {
      _favoriteIds.add(channel.id);
    }
    await _storageService.saveFavoriteChannelIds(_favoriteIds.toList());
    notifyListeners();
  }

  bool isFavorite(Channel channel) => _favoriteIds.contains(channel.id);

  int? channelNumberFor(Channel channel) {
    return _channelNumbers[channel];
  }

  List<Channel> get allChannels {
    if (_playlist == null) return [];
    return _playlist!.channels.map((c) {
      return c.copyWith(isFavorite: _favoriteIds.contains(c.id));
    }).toList();
  }

  List<String> get categories {
    final list = <String>['All', 'Favorites', 'Recently Watched'];
    if (_playlist != null) {
      list.addAll(_playlist!.categories);
    }
    return list;
  }

  List<Channel> get filteredChannels {
    var channels = allChannels;

    // Apply search filter if active (searches globally across all channels)
    if (_searchQuery.trim().isNotEmpty) {
      return channels.where(_matchesSearch).toList();
    }

    // Apply category filter when search is not active
    return _filterByCategory(channels, _selectedCategory);
  }

  List<Channel> channelsForCategory(String category) {
    var channels = allChannels;
    if (_searchQuery.trim().isNotEmpty) {
      channels = channels.where(_matchesSearch).toList();
    }
    return _filterByCategory(channels, category);
  }

  bool _matchesSearch(Channel channel) {
    final query = _searchQuery.trim().toLowerCase();
    return channel.name.toLowerCase().contains(query) ||
        (channel.tvgName?.toLowerCase().contains(query) ?? false) ||
        channel.groupTitle.toLowerCase().contains(query);
  }

  List<Channel> _filterByCategory(List<Channel> channels, String category) {
    if (category == 'Favorites') {
      channels = channels.where((channel) => channel.isFavorite).toList();
    } else if (category == 'Recently Watched') {
      final recentSet = _recentlyWatchedIds.toSet();
      channels = channels.where((c) => recentSet.contains(c.id)).toList();
      channels.sort(
        (a, b) => _recentlyWatchedIds
            .indexOf(a.id)
            .compareTo(_recentlyWatchedIds.indexOf(b.id)),
      );
    } else if (category != 'All') {
      channels = channels.where((c) => c.groupTitle == category).toList();
    }

    return channels;
  }

  int getCategoryChannelCount(String category) {
    if (_playlist == null) return 0;
    if (category == 'All') return _playlist!.channels.length;
    if (category == 'Favorites') {
      return _playlist!.channels
          .where((channel) => _favoriteIds.contains(channel.id))
          .length;
    }
    if (category == 'Recently Watched') {
      return _playlist!.channels
          .where((channel) => _recentlyWatchedIds.contains(channel.id))
          .length;
    }
    return _playlist!.channels.where((c) => c.groupTitle == category).length;
  }
}

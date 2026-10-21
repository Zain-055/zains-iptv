import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/channel.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/channel_card.dart';
import 'player_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openPlayer(Channel channel) {
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    playlistProvider.selectChannel(channel);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(channel: channel),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearchOpen = !_isSearchOpen;
      if (!_isSearchOpen) {
        _searchController.clear();
        Provider.of<PlaylistProvider>(context, listen: false).setSearchQuery('');
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  Map<String, List<Channel>> _categoryRows(PlaylistProvider provider) {
    final rows = <String, List<Channel>>{};
    final categoryNames = provider.categories.skip(1).toSet();

    for (final channel in provider.allChannels) {
      categoryNames.add(channel.groupTitle);
    }

    for (final category in categoryNames) {
      final categoryChannels = provider.channelsForCategory(category);
      if (categoryChannels.isNotEmpty) {
        rows[category] = categoryChannels;
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final playlist = playlistProvider.playlist;
    final categoryRows = _categoryRows(playlistProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.tv_rounded, color: AppTheme.primaryAccent, size: 28),
            const SizedBox(width: 10),
            const Text(
              "ZAIN'S IPTV",
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
            ),
            if (playlistProvider.isFromCache) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.tertiary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.tertiary, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 14, color: colors.tertiary),
                    SizedBox(width: 6),
                    Text(
                      'Offline/Saved Playlist',
                      style: TextStyle(color: colors.tertiary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearchOpen ? Icons.close : Icons.search_rounded),
            tooltip: 'Search Channels',
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (playlistProvider.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: colors.tertiary.withValues(alpha: 0.12),
                child: Text(
                  playlistProvider.errorMessage!,
                  style: TextStyle(color: colors.tertiary, fontSize: 13),
                ),
              ),
            // Search Bar Header if active
            if (_isSearchOpen)
              Container(
                color: context.appSurface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: TextStyle(color: colors.onSurface, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search channel name, tvg name, or category...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: colors.onSurfaceVariant,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              playlistProvider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    playlistProvider.setSearchQuery(value);
                  },
                ),
              ),

            // Main Content Layout
            Expanded(
              child: playlistProvider.status == PlaylistStatus.loading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppTheme.primaryAccent),
                          SizedBox(height: 16),
                          Text(
                            'Loading channels...',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : (playlist == null || playlist.channels.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.tv_off_rounded, size: 64, color: colors.onSurfaceVariant),
                              const SizedBox(height: 16),
                              Text(
                                'No channels were found in this playlist.',
                                style: TextStyle(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  playlistProvider.clearPlaylist();
                                },
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Change Playlist'),
                              ),
                            ],
                          ),
                        )
                      : categoryRows.isEmpty
                          ? Center(
                              child: Text(
                                'No channels found.',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 24,
                              ),
                              itemCount: categoryRows.length,
                              itemBuilder: (context, index) {
                                final category = categoryRows.keys
                                    .elementAt(index);
                                final channels = categoryRows[category]!;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          0,
                                          20,
                                          10,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                category,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: colors.onSurface,
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${channels.length} channels',
                                              style: TextStyle(
                                                color:
                                                    colors.onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: 172,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          itemCount: channels.length,
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(width: 12),
                                          itemBuilder: (context, channelIndex) {
                                            final channel =
                                                channels[channelIndex];
                                            return ChannelCard(
                                              channel: channel,
                                              channelNumber:
                                                  playlistProvider
                                                      .channelNumberFor(
                                                        channel,
                                                      ),
                                              onTap: () =>
                                                  _openPlayer(channel),
                                              onFavoriteToggle: () {
                                                playlistProvider
                                                    .toggleFavorite(channel);
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

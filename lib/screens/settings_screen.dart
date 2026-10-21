import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/playlist_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/tv_focusable.dart';
import 'playlist_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final playlist = playlistProvider.playlist;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Playlist Section
            const _SectionHeader(title: 'PLAYLIST'),
            if (playlist != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.playlist_play_rounded, color: AppTheme.primaryAccent, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${playlist.channels.length} channels loaded (${playlist.sourceType.name.toUpperCase()})',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            _SettingsTile(
              icon: Icons.swap_horiz_rounded,
              title: 'Change Playlist',
              subtitle: 'Select or enter a different IPTV playlist',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PlaylistSetupScreen(isChangeMode: true),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.refresh_rounded,
              title: 'Reload Playlist',
              subtitle: 'Fetch fresh channel list from source',
              onTap: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                await playlistProvider.refreshPlaylist();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Playlist reloaded successfully')),
                );
              },
            ),
            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'Remove Playlist',
              subtitle: 'Clear saved playlist and return to setup screen',
              titleColor: AppTheme.errorRed,
              iconColor: AppTheme.errorRed,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Remove Playlist?'),
                    content: const Text('Are you sure you want to remove the saved playlist?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          playlistProvider.clearPlaylist();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const PlaylistSetupScreen()),
                            (route) => false,
                          );
                        },
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Playback Section
            const _SectionHeader(title: 'PLAYBACK'),
            _SwitchTile(
              icon: Icons.play_arrow_rounded,
              title: 'Auto Play',
              subtitle: 'Automatically start playback when selecting a channel',
              value: settingsProvider.autoPlay,
              onChanged: (val) => settingsProvider.setAutoPlay(val),
            ),
            const SizedBox(height: 8),
            _SwitchTile(
              icon: Icons.fullscreen_rounded,
              title: 'Start in Full Screen',
              subtitle: 'Open video player directly in fullscreen landscape',
              value: settingsProvider.startFullscreen,
              onChanged: (val) => settingsProvider.setStartFullscreen(val),
            ),

            const SizedBox(height: 24),

            // About Section
            const _SectionHeader(title: 'ABOUT'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tv_rounded, color: AppTheme.primaryAccent, size: 28),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ZAIN'S IPTV",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Version 1.0.2',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Simple, fast, cross-platform IPTV player designed for Android phones, tablets, and Android TV.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TvFocusable(
      onPressed: onTap,
      normalBackgroundColor: context.appCard,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? colors.primary, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor ?? colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TvFocusable(
      onPressed: () => onChanged(!value),
      normalBackgroundColor: context.appCard,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.primary,
          ),
        ],
      ),
    );
  }
}

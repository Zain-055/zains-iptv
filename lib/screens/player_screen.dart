import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../models/channel.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/tv_focusable.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final FocusNode _keyboardFocusNode = FocusNode();
  Timer? _channelNumberTimer;
  String _channelNumberInput = '';
  String? _channelNumberError;

  @override
  void initState() {
    super.initState();

    // Enable landscape orientation for video player
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    // Hide status/navigation bars in full screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPlayer(widget.channel);
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    // Restore orientation and system overlays
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _channelNumberTimer?.cancel();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _initPlayer(Channel channel) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    playerProvider.playChannel(channel, autoPlay: settingsProvider.autoPlay);
  }

  void _switchChannel(int direction) {
    final playlistProvider = Provider.of<PlaylistProvider>(
      context,
      listen: false,
    );
    final current =
        Provider.of<PlayerProvider>(context, listen: false).currentChannel ??
        playlistProvider.selectedChannel ??
        widget.channel;
    var channels = playlistProvider.filteredChannels;
    if (channels.isEmpty ||
        !channels.any((channel) => channel.id == current.id)) {
      channels = playlistProvider.playlist?.channels ?? [];
    }

    final currentIndex = channels.indexWhere((c) => c.id == current.id);
    if (channels.isNotEmpty) {
      final newIndex =
          (currentIndex < 0
              ? (direction > 0 ? 0 : channels.length - 1)
              : currentIndex + direction) %
          channels.length;
      final nextChannel = channels[newIndex];
      playlistProvider.selectChannel(nextChannel);
      _initPlayer(nextChannel);
    }
  }

  int? _digitForKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      return 0;
    }
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      return 1;
    }
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      return 2;
    }
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      return 3;
    }
    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      return 4;
    }
    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      return 5;
    }
    if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      return 6;
    }
    if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      return 7;
    }
    if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      return 8;
    }
    if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      return 9;
    }
    return null;
  }

  void _appendChannelDigit(int digit) {
    final playlist = Provider.of<PlaylistProvider>(
      context,
      listen: false,
    ).playlist;
    if (playlist == null || playlist.channels.isEmpty) return;

    final maxDigits = playlist.channels.length.toString().length;
    setState(() {
      if (_channelNumberInput.length >= maxDigits) {
        _channelNumberInput = '';
      }
      _channelNumberInput += digit.toString();
      _channelNumberError = null;
    });

    _channelNumberTimer?.cancel();
    _channelNumberTimer = Timer(
      const Duration(milliseconds: 900),
      _tuneToEnteredChannel,
    );
  }

  void _tuneToEnteredChannel() {
    if (!mounted || _channelNumberInput.isEmpty) return;

    final number = int.tryParse(_channelNumberInput);
    final playlistProvider = Provider.of<PlaylistProvider>(
      context,
      listen: false,
    );
    final channels = playlistProvider.playlist?.channels;

    if (number == null ||
        channels == null ||
        number < 1 ||
        number > channels.length) {
      setState(() {
        _channelNumberError = 'Channel $_channelNumberInput not found';
      });
      _channelNumberTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _channelNumberInput = '';
          _channelNumberError = null;
        });
      });
      return;
    }

    final channel = channels[number - 1];
    setState(() {
      _channelNumberInput = '';
      _channelNumberError = null;
    });
    playlistProvider.selectChannel(channel);
    _initPlayer(channel);
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final currentChannel = playerProvider.currentChannel ?? widget.channel;
    final isFav = playlistProvider.isFavorite(currentChannel);
    final videoFit = switch (playerProvider.aspectRatioMode) {
      AspectRatioMode.fit => BoxFit.contain,
      AspectRatioMode.fill => BoxFit.cover,
      AspectRatioMode.stretch => BoxFit.fill,
    };
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: (event) {
          playerProvider.resetOverlayTimer();

          if (event is KeyDownEvent) {
            final digit = _digitForKey(event.logicalKey);
            if (digit != null) {
              _appendChannelDigit(digit);
            } else if (event.logicalKey == LogicalKeyboardKey.enter &&
                _channelNumberInput.isNotEmpty) {
              _channelNumberTimer?.cancel();
              _tuneToEnteredChannel();
            } else if (event.logicalKey == LogicalKeyboardKey.backspace &&
                _channelNumberInput.isNotEmpty) {
              _channelNumberTimer?.cancel();
              setState(() {
                _channelNumberInput = _channelNumberInput.substring(
                  0,
                  _channelNumberInput.length - 1,
                );
                _channelNumberError = null;
              });
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _switchChannel(-1); // Previous channel
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _switchChannel(1); // Next channel
            } else if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause ||
                event.logicalKey == LogicalKeyboardKey.space) {
              playerProvider.togglePlayPause();
            }
          }
        },
        child: GestureDetector(
          onTap: () {
            playerProvider.toggleOverlay();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_channelNumberInput.isNotEmpty)
                Positioned(
                  top: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryAccent),
                    ),
                    child: Text(
                      _channelNumberError ?? 'Channel $_channelNumberInput',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Video View
              if (playerProvider.videoController != null &&
                  !playerProvider.hasError) ...[
                Center(
                  child: Video(
                    controller: playerProvider.videoController!,
                    fit: videoFit,
                    aspectRatio: playerProvider.videoAspectRatio,
                    controls: NoVideoControls,
                  ),
                ),
              ],

              // Buffering Progress Indicator
              if (playerProvider.isInitializing || playerProvider.isBuffering)
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryAccent),
                      SizedBox(height: 16),
                      Text(
                        'Connecting to live stream...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                        ),
                      ),
                    ],
                  ),
                ),

              // No-signal state; channel changes remain available while reconnecting.
              if (playerProvider.hasError)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      constraints: const BoxConstraints(maxWidth: 420),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.signal_wifi_connected_no_internet_4_rounded,
                            color: AppTheme.primaryAccent,
                            size: 52,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No signal',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${currentChannel.name} - reconnecting automatically',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TvFocusable(
                                autoFocus: true,
                                onPressed: () => _switchChannel(-1),
                                normalBackgroundColor: const Color(0xFF262626),
                                focusedBackgroundColor: AppTheme.primaryAccent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.skip_previous_rounded,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Previous',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              TvFocusable(
                                onPressed: () => _switchChannel(1),
                                normalBackgroundColor: const Color(0xFF262626),
                                focusedBackgroundColor: AppTheme.primaryAccent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: const Row(
                                  children: [
                                    Text(
                                      'Next',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.skip_next_rounded,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // On-Screen Controls Overlay
              if (playerProvider.showOverlay && !playerProvider.hasError)
                AnimatedOpacity(
                  opacity: playerProvider.showOverlay ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black87,
                          Colors.transparent,
                          Colors.black87,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Bar Header
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () {
                                playerProvider.disposeCurrentPlayer();
                                Navigator.of(context).pop();
                              },
                            ),
                            const SizedBox(width: 12),
                            if (currentChannel.tvgLogo != null &&
                                currentChannel.tvgLogo!.trim().isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  currentChannel.tvgLogo!.trim(),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.tv, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentChannel.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    currentChannel.groupTitle,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isFav
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: isFav
                                    ? AppTheme.favoriteGold
                                    : Colors.white,
                                size: 30,
                              ),
                              onPressed: () {
                                playlistProvider.toggleFavorite(currentChannel);
                              },
                            ),
                          ],
                        ),

                        // Bottom Bar Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.skip_previous_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                              tooltip: 'Previous Channel',
                              onPressed: () => _switchChannel(-1),
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              icon: Icon(
                                playerProvider.isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: AppTheme.primaryAccent,
                                size: 56,
                              ),
                              onPressed: () {
                                playerProvider.togglePlayPause();
                              },
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                              tooltip: 'Next Channel',
                              onPressed: () => _switchChannel(1),
                            ),
                            const SizedBox(width: 24),
                            IconButton(
                              icon: const Icon(
                                Icons.aspect_ratio_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              tooltip:
                                  'Aspect Ratio (${playerProvider.aspectRatioMode.name.toUpperCase()})',
                              onPressed: () {
                                playerProvider.toggleAspectRatio();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/channel.dart';

enum AspectRatioMode { fit, fill, stretch }

class PlayerProvider extends ChangeNotifier {
  static const _bufferingTimeout = Duration(seconds: 30);
  static const _stablePlaybackDuration = Duration(seconds: 60);
  static const _retryBaseDelaySeconds = 5;
  static const _retryMaxDelaySeconds = 60;
  static const _initializationTimeout = Duration(seconds: 30);

  Player? _player;
  VideoController? _videoController;
  final List<StreamSubscription<dynamic>> _playerSubscriptions = [];
  Channel? _currentChannel;
  bool _isInitializing = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _hasError = false;
  bool _showOverlay = true;
  bool _autoPlay = true;
  bool _isDisposed = false;
  int _playbackGeneration = 0;
  Timer? _overlayTimer;
  Timer? _retryTimer;
  Timer? _bufferingTimer;
  Timer? _stablePlaybackTimer;
  int _retryAttempt = 0;
  AspectRatioMode _aspectRatioMode = AspectRatioMode.fit;

  VideoController? get videoController => _videoController;
  Channel? get currentChannel => _currentChannel;
  bool get isInitializing => _isInitializing;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get hasError => _hasError;
  bool get showOverlay => _showOverlay;
  AspectRatioMode get aspectRatioMode => _aspectRatioMode;
  double get videoAspectRatio {
    final state = _player?.state;
    final width = state?.width;
    final height = state?.height;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return 16 / 9;
    }
    return width / height;
  }

  Future<void> playChannel(Channel channel, {bool autoPlay = true}) async {
    if (_isDisposed) return;
    final generation = ++_playbackGeneration;
    if (_currentChannel?.id != channel.id) {
      _retryAttempt = 0;
    }
    _autoPlay = autoPlay;
    _retryTimer?.cancel();
    _retryTimer = null;
    _cancelBufferingTimers();

    await _disposePlaybackResources();
    if (_isDisposed || generation != _playbackGeneration) return;

    _currentChannel = channel;
    _isInitializing = true;
    _hasError = false;
    _isBuffering = true;
    _showOverlay = true;
    notifyListeners();

    _startOverlayTimer();

    try {
      final player = Player();
      final videoController = VideoController(player);
      _player = player;
      _videoController = videoController;
      _listenToPlayer(player, generation);

      await player
          .open(
            Media(
              channel.url.trim(),
              httpHeaders: const {
                'User-Agent': 'ZainsIPTV/1.0',
                'Accept': '*/*',
              },
            ),
            play: autoPlay,
          )
          .timeout(_initializationTimeout);
      if (_isDisposed ||
          generation != _playbackGeneration ||
          !identical(_player, player)) {
        return;
      }

      if (autoPlay) {
        await videoController.waitUntilFirstFrameRendered.timeout(
          _initializationTimeout,
        );
      }

      if (_isDisposed ||
          generation != _playbackGeneration ||
          !identical(_player, player)) {
        return;
      }
      if (_hasError) return;
      _retryTimer?.cancel();
      _retryTimer = null;
      _bufferingTimer?.cancel();
      _bufferingTimer = null;
      _isInitializing = false;
      _isPlaying = player.state.playing;
      _isBuffering = player.state.buffering;
      if (_isBuffering) {
        _startBufferingTimer(generation);
      } else {
        _updateStablePlaybackTimer(generation);
      }
      notifyListeners();
    } catch (error, stackTrace) {
      if (_isDisposed || generation != _playbackGeneration) return;
      _handlePlaybackError(error, stackTrace, generation);
    }
  }

  void _listenToPlayer(Player player, int generation) {
    _playerSubscriptions
      ..add(
        player.stream.playing.listen((isPlaying) {
          if (!_isCurrentPlayer(player, generation)) return;
          if (_isPlaying != isPlaying) {
            _isPlaying = isPlaying;
            if (isPlaying) {
              _updateStablePlaybackTimer(generation);
            } else {
              _stablePlaybackTimer?.cancel();
              _stablePlaybackTimer = null;
            }
            notifyListeners();
          }
        }),
      )
      ..add(
        player.stream.buffering.listen((isBuffering) {
          if (!_isCurrentPlayer(player, generation)) return;
          if (_isBuffering == isBuffering) return;
          _isBuffering = isBuffering;
          if (isBuffering) {
            _startBufferingTimer(generation);
          } else {
            _bufferingTimer?.cancel();
            _bufferingTimer = null;
            _updateStablePlaybackTimer(generation);
          }
          notifyListeners();
        }),
      )
      ..add(
        player.stream.error.listen((message) {
          if (!_isCurrentPlayer(player, generation)) return;
          _handlePlaybackError(
            StateError(message),
            StackTrace.current,
            generation,
          );
        }),
      )
      ..add(
        player.stream.width.listen((_) {
          if (_isCurrentPlayer(player, generation)) notifyListeners();
        }),
      )
      ..add(
        player.stream.height.listen((_) {
          if (_isCurrentPlayer(player, generation)) notifyListeners();
        }),
      );
  }

  bool _isCurrentPlayer(Player player, int generation) =>
      !_isDisposed &&
      generation == _playbackGeneration &&
      identical(_player, player);

  void _handlePlaybackError(
    Object error,
    StackTrace stackTrace,
    int generation,
  ) {
    if (_isDisposed || generation != _playbackGeneration || _hasError) return;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'media player',
      ),
    );
    _cancelBufferingTimers();
    _isInitializing = false;
    _hasError = true;
    _isPlaying = false;
    _isBuffering = false;
    _scheduleRetry(generation);
    notifyListeners();
  }

  void _startBufferingTimer(int generation) {
    _stablePlaybackTimer?.cancel();
    _stablePlaybackTimer = null;
    if (_bufferingTimer != null) return;

    _bufferingTimer = Timer(_bufferingTimeout, () {
      _bufferingTimer = null;
      if (_isDisposed ||
          generation != _playbackGeneration ||
          _player?.state.buffering != true) {
        return;
      }

      _handlePlaybackError(
        TimeoutException('The live stream remained buffered too long.'),
        StackTrace.current,
        generation,
      );
    });
  }

  void _updateStablePlaybackTimer(int generation) {
    final player = _player;
    if (player == null || !player.state.playing || player.state.buffering) {
      _stablePlaybackTimer?.cancel();
      _stablePlaybackTimer = null;
      return;
    }
    if (_stablePlaybackTimer != null) return;

    _stablePlaybackTimer = Timer(_stablePlaybackDuration, () {
      _stablePlaybackTimer = null;
      if (_isDisposed ||
          generation != _playbackGeneration ||
          !identical(_player, player) ||
          !player.state.playing ||
          player.state.buffering) {
        return;
      }
      _retryAttempt = 0;
    });
  }

  void _cancelBufferingTimers() {
    _bufferingTimer?.cancel();
    _bufferingTimer = null;
    _stablePlaybackTimer?.cancel();
    _stablePlaybackTimer = null;
  }

  Future<void> togglePlayPause() async {
    final player = _player;
    if (player == null || _isInitializing) return;

    await player.playOrPause();
    _isPlaying = player.state.playing;
    resetOverlayTimer();
    notifyListeners();
  }

  void toggleAspectRatio() {
    switch (_aspectRatioMode) {
      case AspectRatioMode.fit:
        _aspectRatioMode = AspectRatioMode.fill;
        break;
      case AspectRatioMode.fill:
        _aspectRatioMode = AspectRatioMode.stretch;
        break;
      case AspectRatioMode.stretch:
        _aspectRatioMode = AspectRatioMode.fit;
        break;
    }
    resetOverlayTimer();
    notifyListeners();
  }

  void toggleOverlay() {
    _showOverlay = !_showOverlay;
    if (_showOverlay) {
      _startOverlayTimer();
    } else {
      _overlayTimer?.cancel();
    }
    notifyListeners();
  }

  void resetOverlayTimer() {
    _showOverlay = true;
    _startOverlayTimer();
    notifyListeners();
  }

  void _startOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 4), () {
      if (_isPlaying && !_hasError) {
        _showOverlay = false;
        notifyListeners();
      }
    });
  }

  Future<void> retry() async {
    if (_currentChannel != null) {
      _retryAttempt = 0;
      await playChannel(_currentChannel!, autoPlay: _autoPlay);
    }
  }

  void _scheduleRetry(int generation) {
    _retryTimer?.cancel();
    final retryDelay = math.min(
      _retryBaseDelaySeconds * (1 << math.min(_retryAttempt, 4)),
      _retryMaxDelaySeconds,
    );
    _retryAttempt = math.min(_retryAttempt + 1, 5);
    _retryTimer = Timer(Duration(seconds: retryDelay), () {
      if (_isDisposed || generation != _playbackGeneration) return;
      final channel = _currentChannel;
      if (channel != null) {
        playChannel(channel, autoPlay: _autoPlay);
      }
    });
  }

  Future<void> disposeCurrentPlayer() async {
    if (_isDisposed) return;
    ++_playbackGeneration;
    _retryTimer?.cancel();
    _retryTimer = null;
    _cancelBufferingTimers();
    _overlayTimer?.cancel();
    await _disposePlaybackResources();
    _isPlaying = false;
    _isBuffering = false;
    _isInitializing = false;
    _hasError = false;
    notifyListeners();
  }

  Future<void> _disposePlaybackResources() async {
    final player = _player;
    _player = null;
    _videoController = null;
    final subscriptions = List<StreamSubscription<dynamic>>.of(
      _playerSubscriptions,
    );
    _playerSubscriptions.clear();
    await Future.wait(
      subscriptions.map((subscription) => subscription.cancel()),
    );
    await player?.dispose();
  }

  @override
  void dispose() {
    _isDisposed = true;
    ++_playbackGeneration;
    _retryTimer?.cancel();
    _cancelBufferingTimers();
    _overlayTimer?.cancel();
    unawaited(
      _disposePlaybackResources().catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'media player cleanup',
          ),
        );
      }),
    );
    super.dispose();
  }
}

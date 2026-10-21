import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../models/channel.dart';

enum AspectRatioMode { fit, fill, stretch }

class PlayerProvider extends ChangeNotifier {
  static const _bufferingTimeout = Duration(seconds: 30);
  static const _stablePlaybackDuration = Duration(seconds: 60);
  static const _retryBaseDelaySeconds = 5;
  static const _retryMaxDelaySeconds = 60;

  VideoPlayerController? _controller;
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

  VideoPlayerController? get controller => _controller;
  Channel? get currentChannel => _currentChannel;
  bool get isInitializing => _isInitializing;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get hasError => _hasError;
  bool get showOverlay => _showOverlay;
  AspectRatioMode get aspectRatioMode => _aspectRatioMode;

  Future<void> playChannel(Channel channel, {bool autoPlay = true}) async {
    final generation = ++_playbackGeneration;
    if (_currentChannel?.id != channel.id) {
      _retryAttempt = 0;
    }
    _autoPlay = autoPlay;
    _retryTimer?.cancel();
    _retryTimer = null;
    _cancelBufferingTimers();

    final previousController = _controller;
    _controller = null;
    if (previousController != null) {
      previousController.removeListener(_onControllerUpdate);
      await previousController.dispose();
    }
    if (_isDisposed || generation != _playbackGeneration) return;

    _currentChannel = channel;
    _isInitializing = true;
    _hasError = false;
    _isBuffering = false;
    _showOverlay = true;
    notifyListeners();

    _startOverlayTimer();

    try {
      final uri = Uri.parse(channel.url.trim());
      final controller = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: const {
          'User-Agent': 'ZainsIPTV/1.0 (Android/TV)',
          'Accept': '*/*',
        },
      );
      _controller = controller;
      controller.addListener(_onControllerUpdate);

      await controller.initialize().timeout(const Duration(seconds: 20));
      if (_isDisposed ||
          generation != _playbackGeneration ||
          !identical(_controller, controller)) {
        return;
      }

      if (autoPlay) {
        await controller.play();
      }

      if (_isDisposed ||
          generation != _playbackGeneration ||
          !identical(_controller, controller)) {
        return;
      }
      _retryTimer?.cancel();
      _retryTimer = null;
      _isInitializing = false;
      _hasError = controller.value.hasError;
      _isPlaying = controller.value.isPlaying;
      _isBuffering = controller.value.isBuffering;
      if (_isBuffering) {
        _startBufferingTimer(generation, controller);
      } else {
        _updateStablePlaybackTimer(generation, controller);
      }
      if (_hasError) {
        _scheduleRetry(generation);
      }
      notifyListeners();
    } catch (error, stackTrace) {
      if (_isDisposed || generation != _playbackGeneration) return;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'video player',
        ),
      );
      _isInitializing = false;
      _hasError = true;
      _isPlaying = false;
      _isBuffering = false;
      _scheduleRetry(generation);
      notifyListeners();
    }
  }

  void _onControllerUpdate() {
    final controller = _controller;
    if (controller == null) return;

    final val = controller.value;
    final isNowPlaying = val.isPlaying;
    final isNowBuffering = val.isBuffering;
    final hasControllerError = val.hasError;

    if (hasControllerError) {
      if (_hasError) return;
      _cancelBufferingTimers();
      _hasError = true;
      _isInitializing = false;
      _isPlaying = false;
      _isBuffering = false;
      _scheduleRetry(_playbackGeneration);
      notifyListeners();
      return;
    }

    if (isNowBuffering) {
      _startBufferingTimer(_playbackGeneration, controller);
    } else {
      _bufferingTimer?.cancel();
      _bufferingTimer = null;
      _updateStablePlaybackTimer(_playbackGeneration, controller);
    }

    if (_isPlaying != isNowPlaying || _isBuffering != isNowBuffering) {
      _isPlaying = isNowPlaying;
      _isBuffering = isNowBuffering;
      notifyListeners();
    }
  }

  void _startBufferingTimer(int generation, VideoPlayerController controller) {
    _stablePlaybackTimer?.cancel();
    _stablePlaybackTimer = null;
    if (_bufferingTimer != null) return;

    _bufferingTimer = Timer(_bufferingTimeout, () {
      _bufferingTimer = null;
      if (_isDisposed ||
          generation != _playbackGeneration ||
          !identical(_controller, controller) ||
          !controller.value.isBuffering) {
        return;
      }

      _hasError = true;
      _isInitializing = false;
      _isPlaying = false;
      _isBuffering = false;
      _scheduleRetry(generation);
      notifyListeners();
    });
  }

  void _updateStablePlaybackTimer(
    int generation,
    VideoPlayerController controller,
  ) {
    if (!controller.value.isPlaying) {
      _stablePlaybackTimer?.cancel();
      _stablePlaybackTimer = null;
      return;
    }
    if (_stablePlaybackTimer != null) return;

    _stablePlaybackTimer = Timer(_stablePlaybackDuration, () {
      _stablePlaybackTimer = null;
      if (_isDisposed ||
          generation != _playbackGeneration ||
          !identical(_controller, controller) ||
          !controller.value.isPlaying ||
          controller.value.isBuffering) {
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
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_controller!.value.isPlaying) {
      await _controller!.pause();
    } else {
      await _controller!.play();
    }
    _isPlaying = _controller!.value.isPlaying;
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
    ++_playbackGeneration;
    _retryTimer?.cancel();
    _retryTimer = null;
    _cancelBufferingTimers();
    _overlayTimer?.cancel();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_onControllerUpdate);
      await controller.dispose();
    }
    _isPlaying = false;
    _isBuffering = false;
    _isInitializing = false;
    _hasError = false;
  }

  @override
  void dispose() {
    _isDisposed = true;
    ++_playbackGeneration;
    _retryTimer?.cancel();
    _cancelBufferingTimers();
    _overlayTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }
}

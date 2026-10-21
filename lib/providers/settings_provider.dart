import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;

  late bool _autoPlay;
  late bool _startFullscreen;

  SettingsProvider(this._storageService) {
    _autoPlay = _storageService.getAutoPlay();
    _startFullscreen = _storageService.getStartFullscreen();
  }

  bool get autoPlay => _autoPlay;
  bool get startFullscreen => _startFullscreen;

  Future<void> setAutoPlay(bool value) async {
    _autoPlay = value;
    await _storageService.setAutoPlay(value);
    notifyListeners();
  }

  Future<void> setStartFullscreen(bool value) async {
    _startFullscreen = value;
    await _storageService.setStartFullscreen(value);
    notifyListeners();
  }

}

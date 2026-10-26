import 'package:flutter_test/flutter_test.dart';
import 'package:zains_iptv/providers/player_provider.dart';

void main() {
  test(
    'player uses a widescreen fallback until stream dimensions are known',
    () {
      final provider = PlayerProvider();
      addTearDown(provider.dispose);

      expect(provider.videoAspectRatio, 16 / 9);
    },
  );

  test('aspect ratio mode cycles through fit, fill, and stretch', () {
    final provider = PlayerProvider();
    addTearDown(provider.dispose);

    expect(provider.aspectRatioMode, AspectRatioMode.fit);
    provider.toggleAspectRatio();
    expect(provider.aspectRatioMode, AspectRatioMode.fill);
    provider.toggleAspectRatio();
    expect(provider.aspectRatioMode, AspectRatioMode.stretch);
    provider.toggleAspectRatio();
    expect(provider.aspectRatioMode, AspectRatioMode.fit);
  });
}

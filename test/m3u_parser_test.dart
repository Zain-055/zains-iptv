import 'package:flutter_test/flutter_test.dart';
import 'package:zains_iptv/services/m3u_parser.dart';

void main() {
  group('M3uParser Tests', () {
    test('Parses simple M3U playlist correctly', () {
      const sampleM3u = '''
#EXTM3U
#EXTINF:-1 tvg-id="news1" tvg-name="BBC News" tvg-logo="https://example.com/bbc.png" group-title="News",BBC News
https://example.com/bbc.m3u8
#EXTINF:-1 tvg-id="sports1" tvg-name="ESPN" tvg-logo="https://example.com/espn.png" group-title="Sports",ESPN HD
http://example.com/espn.m3u8
#EXTINF:-1,Uncategorized Channel
https://example.com/stream3.m3u8
''';

      final result = M3uParser.parseSync(sampleM3u);

      expect(result.channels.length, equals(3));
      expect(result.channels[0].name, equals('BBC News'));
      expect(result.channels[0].groupTitle, equals('News'));
      expect(result.channels[0].tvgLogo, equals('https://example.com/bbc.png'));
      expect(result.channels[0].url, equals('https://example.com/bbc.m3u8'));

      expect(result.channels[1].name, equals('ESPN HD'));
      expect(result.channels[1].groupTitle, equals('Sports'));

      expect(result.channels[2].name, equals('Uncategorized Channel'));
      expect(result.channels[2].groupTitle, equals('Uncategorized'));

      expect(result.categories, containsAll(['News', 'Sports', 'Uncategorized']));
    });

    test('Gracefully ignores malformed M3U lines', () {
      const malformedM3u = '''
INVALID LINE
#EXTINF:-1, Valid Channel
https://example.com/valid.m3u8
RANDOM GARBAGE NO URL
#EXTM3U
#EXTINF:-1 tvg-id="" tvg-logo="",
https://example.com/stream2.m3u8
''';

      final result = M3uParser.parseSync(malformedM3u);

      expect(result.channels.length, equals(2));
      expect(result.channels[0].name, equals('Valid Channel'));
      expect(result.channels[0].url, equals('https://example.com/valid.m3u8'));
      expect(result.channels[1].url, equals('https://example.com/stream2.m3u8'));
    });
  });
}

import 'package:flutter/foundation.dart';
import '../models/channel.dart';

class M3uParserResult {
  final List<Channel> channels;
  final List<String> categories;

  const M3uParserResult({
    required this.channels,
    required this.categories,
  });
}

class M3uParser {
  /// Parse M3U string asynchronously in a background isolate to avoid UI thread lag.
  static Future<M3uParserResult> parseAsync(String m3uContent) async {
    return await compute(_parseInternal, m3uContent);
  }

  /// Internal synchronous parser function.
  static M3uParserResult _parseInternal(String m3uContent) {
    return parseSync(m3uContent);
  }

  /// Parse M3U content string synchronously.
  static M3uParserResult parseSync(String m3uContent) {
    final List<Channel> channels = [];
    final Set<String> categoriesSet = {};

    final lines = m3uContent.split(RegExp(r'\r?\n'));

    String? pendingName;
    String? pendingGroupTitle;
    String? pendingTvgId;
    String? pendingTvgName;
    String? pendingTvgLogo;

    int channelIndex = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        // Reset metadata for new channel
        pendingGroupTitle = 'Uncategorized';
        pendingTvgId = null;
        pendingTvgName = null;
        pendingTvgLogo = null;
        pendingName = null;

        // Extract attributes using regex
        final groupTitleMatch = RegExp(r'group-title="([^"]*)"', caseSensitive: false).firstMatch(line);
        if (groupTitleMatch != null && groupTitleMatch.group(1)!.trim().isNotEmpty) {
          pendingGroupTitle = groupTitleMatch.group(1)!.trim();
        }

        final tvgIdMatch = RegExp(r'tvg-id="([^"]*)"', caseSensitive: false).firstMatch(line);
        if (tvgIdMatch != null && tvgIdMatch.group(1)!.trim().isNotEmpty) {
          pendingTvgId = tvgIdMatch.group(1)!.trim();
        }

        final tvgNameMatch = RegExp(r'tvg-name="([^"]*)"', caseSensitive: false).firstMatch(line);
        if (tvgNameMatch != null && tvgNameMatch.group(1)!.trim().isNotEmpty) {
          pendingTvgName = tvgNameMatch.group(1)!.trim();
        }

        final tvgLogoMatch = RegExp(r'tvg-logo="([^"]*)"', caseSensitive: false).firstMatch(line);
        if (tvgLogoMatch != null && tvgLogoMatch.group(1)!.trim().isNotEmpty) {
          pendingTvgLogo = tvgLogoMatch.group(1)!.trim();
        }

        // Extract channel name (after last comma)
        final commaIndex = line.lastIndexOf(',');
        if (commaIndex != -1 && commaIndex < line.length - 1) {
          pendingName = line.substring(commaIndex + 1).trim();
        }
      } else if (line.startsWith('#EXTGRP:')) {
        // Alternative group header
        final group = line.substring(8).trim();
        if (group.isNotEmpty) {
          pendingGroupTitle = group;
        }
      } else if (!line.startsWith('#')) {
        // This line should be the stream URL
        final url = line.trim();
        if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('rtmp://') || url.startsWith('rtsp://') || url.contains('://') || url.contains('.')) {
          channelIndex++;
          final channelName = (pendingName != null && pendingName.isNotEmpty)
              ? pendingName
              : (pendingTvgName != null && pendingTvgName.isNotEmpty)
                  ? pendingTvgName
                  : 'Channel $channelIndex';

          final groupTitle = (pendingGroupTitle != null && pendingGroupTitle.isNotEmpty)
              ? pendingGroupTitle
              : 'Uncategorized';

          final channel = Channel(
            id: '${channelIndex}_${url.hashCode}',
            name: channelName,
            url: url,
            groupTitle: groupTitle,
            tvgId: pendingTvgId,
            tvgName: pendingTvgName,
            tvgLogo: pendingTvgLogo,
          );

          channels.add(channel);
          categoriesSet.add(groupTitle);

          // Clear pending state
          pendingName = null;
          pendingGroupTitle = null;
          pendingTvgId = null;
          pendingTvgName = null;
          pendingTvgLogo = null;
        }
      }
    }

    final sortedCategories = categoriesSet.toList()..sort();

    return M3uParserResult(
      channels: channels,
      categories: sortedCategories,
    );
  }
}

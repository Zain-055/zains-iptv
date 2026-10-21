import 'dart:convert';
import 'channel.dart';

enum PlaylistSourceType { file, url }

class Playlist {
  final PlaylistSourceType sourceType;
  final String sourcePathOrUrl;
  final String name;
  final DateTime loadedAt;
  final List<Channel> channels;
  final List<String> categories;

  const Playlist({
    required this.sourceType,
    required this.sourcePathOrUrl,
    required this.name,
    required this.loadedAt,
    required this.channels,
    required this.categories,
  });

  Map<String, dynamic> toMap() {
    return {
      'sourceType': sourceType.name,
      'sourcePathOrUrl': sourcePathOrUrl,
      'name': name,
      'loadedAt': loadedAt.toIso8601String(),
      'channels': channels.map((c) => c.toMap()).toList(),
      'categories': categories,
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    final channelsList = (map['channels'] as List<dynamic>?)
            ?.map((c) => Channel.fromMap(c as Map<String, dynamic>))
            .toList() ??
        [];

    final categoriesList = (map['categories'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return Playlist(
      sourceType: (map['sourceType'] == 'file')
          ? PlaylistSourceType.file
          : PlaylistSourceType.url,
      sourcePathOrUrl: map['sourcePathOrUrl'] ?? '',
      name: map['name'] ?? 'Saved Playlist',
      loadedAt: map['loadedAt'] != null
          ? DateTime.tryParse(map['loadedAt']) ?? DateTime.now()
          : DateTime.now(),
      channels: channelsList,
      categories: categoriesList,
    );
  }

  String toJson() => json.encode(toMap());

  factory Playlist.fromJson(String source) => Playlist.fromMap(json.decode(source));
}

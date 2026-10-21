import 'dart:convert';

class Channel {
  final String id;
  final String name;
  final String url;
  final String groupTitle;
  final String? tvgId;
  final String? tvgName;
  final String? tvgLogo;
  final bool isFavorite;

  const Channel({
    required this.id,
    required this.name,
    required this.url,
    this.groupTitle = 'Uncategorized',
    this.tvgId,
    this.tvgName,
    this.tvgLogo,
    this.isFavorite = false,
  });

  Channel copyWith({
    String? id,
    String? name,
    String? url,
    String? groupTitle,
    String? tvgId,
    String? tvgName,
    String? tvgLogo,
    bool? isFavorite,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      groupTitle: groupTitle ?? this.groupTitle,
      tvgId: tvgId ?? this.tvgId,
      tvgName: tvgName ?? this.tvgName,
      tvgLogo: tvgLogo ?? this.tvgLogo,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'groupTitle': groupTitle,
      'tvgId': tvgId,
      'tvgName': tvgName,
      'tvgLogo': tvgLogo,
      'isFavorite': isFavorite,
    };
  }

  factory Channel.fromMap(Map<String, dynamic> map) {
    return Channel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown Channel',
      url: map['url'] ?? '',
      groupTitle: map['groupTitle'] ?? 'Uncategorized',
      tvgId: map['tvgId'],
      tvgName: map['tvgName'],
      tvgLogo: map['tvgLogo'],
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Channel.fromJson(String source) => Channel.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Channel && other.id == id && other.url == url;
  }

  @override
  int get hashCode => id.hashCode ^ url.hashCode;
}

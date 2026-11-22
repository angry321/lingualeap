import 'dart:convert';
import 'segment.dart';

class MaterialItem {
  final int? id;
  final String title;
  final String sourceType; // 'text' or 'youtube'
  final String? youtubeId;
  final String segmentsJson;
  final int createdAt;

  const MaterialItem({
    this.id,
    required this.title,
    required this.sourceType,
    this.youtubeId,
    required this.segmentsJson,
    required this.createdAt,
  });

  bool get isYouTube => sourceType == 'youtube';
  bool get isText => sourceType == 'text';

  List<Segment> get segments {
    try {
      final decoded = jsonDecode(segmentsJson);
      if (decoded is List) {
        return decoded
            .map((item) => Segment.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'source_type': sourceType,
      'youtube_id': youtubeId,
      'segments_json': segmentsJson,
      'created_at': createdAt,
    };
  }

  factory MaterialItem.fromMap(Map<String, dynamic> map) {
    return MaterialItem(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'Untitled',
      sourceType: map['source_type'] as String? ?? 'text',
      youtubeId: map['youtube_id'] as String?,
      segmentsJson: map['segments_json'] as String? ?? '[]',
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
    );
  }

  MaterialItem copyWith({
    int? id,
    String? title,
    String? sourceType,
    String? youtubeId,
    String? segmentsJson,
    int? createdAt,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceType: sourceType ?? this.sourceType,
      youtubeId: youtubeId ?? this.youtubeId,
      segmentsJson: segmentsJson ?? this.segmentsJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

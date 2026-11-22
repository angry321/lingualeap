class Segment {
  final String text;
  final int startMs;
  final int durationMs;

  const Segment({
    required this.text,
    this.startMs = 0,
    this.durationMs = 0,
  });

  int get endMs => startMs + durationMs;

  factory Segment.fromJson(Map<String, dynamic> json) {
    return Segment(
      text: json['text'] as String? ?? '',
      startMs: (json['startMs'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'startMs': startMs,
      'durationMs': durationMs,
    };
  }

  Segment copyWith({
    String? text,
    int? startMs,
    int? durationMs,
  }) {
    return Segment(
      text: text ?? this.text,
      startMs: startMs ?? this.startMs,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}

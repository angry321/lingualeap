class WordItem {
  final int? id;
  final String lemma;
  final String originalForm;
  final String translation;
  final String partOfSpeech;
  final String explanation;
  final String contextSentence;
  final String status; // 'learning' or 'known'
  final int nextReviewAt;
  final int intervalDays;
  final double easeFactor;

  const WordItem({
    this.id,
    required this.lemma,
    required this.originalForm,
    required this.translation,
    required this.partOfSpeech,
    required this.explanation,
    required this.contextSentence,
    required this.status,
    required this.nextReviewAt,
    this.intervalDays = 0,
    this.easeFactor = 2.5,
  });

  bool get isLearning => status == 'learning';
  bool get isKnown => status == 'known';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'lemma': lemma.toLowerCase().trim(),
      'original_form': originalForm,
      'translation': translation,
      'part_of_speech': partOfSpeech,
      'explanation': explanation,
      'context_sentence': contextSentence,
      'status': status,
      'next_review_at': nextReviewAt,
      'interval_days': intervalDays,
      'ease_factor': easeFactor,
    };
  }

  factory WordItem.fromMap(Map<String, dynamic> map) {
    return WordItem(
      id: map['id'] as int?,
      lemma: (map['lemma'] as String? ?? '').toLowerCase().trim(),
      originalForm: map['original_form'] as String? ?? '',
      translation: map['translation'] as String? ?? '',
      partOfSpeech: map['part_of_speech'] as String? ?? '',
      explanation: map['explanation'] as String? ?? '',
      contextSentence: map['context_sentence'] as String? ?? '',
      status: map['status'] as String? ?? 'learning',
      nextReviewAt: (map['next_review_at'] as num?)?.toInt() ?? 0,
      intervalDays: (map['interval_days'] as num?)?.toInt() ?? 0,
      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
    );
  }

  WordItem copyWith({
    int? id,
    String? lemma,
    String? originalForm,
    String? translation,
    String? partOfSpeech,
    String? explanation,
    String? contextSentence,
    String? status,
    int? nextReviewAt,
    int? intervalDays,
    double? easeFactor,
  }) {
    return WordItem(
      id: id ?? this.id,
      lemma: lemma ?? this.lemma,
      originalForm: originalForm ?? this.originalForm,
      translation: translation ?? this.translation,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      explanation: explanation ?? this.explanation,
      contextSentence: contextSentence ?? this.contextSentence,
      status: status ?? this.status,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
    );
  }
}

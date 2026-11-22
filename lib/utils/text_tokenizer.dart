class Token {
  final String text;
  final bool isWord;
  final String cleanWord;

  const Token({
    required this.text,
    required this.isWord,
    required this.cleanWord,
  });
}

class TextTokenizer {
  // Regex to match unicode words including letters, numbers, and internal apostrophes/hyphens
  static final RegExp _tokenRegex = RegExp(
    r"[\p{L}\p{N}]+(?:['’\-][\p{L}\p{N}]+)*|[^\p{L}\p{N}\s]+|\s+",
    unicode: true,
  );

  static final RegExp _wordCheckRegex = RegExp(r"[\p{L}\p{N}]", unicode: true);

  /// Splits a sentence or line into words and non-word tokens
  static List<Token> tokenize(String input) {
    if (input.isEmpty) return const [];

    final matches = _tokenRegex.allMatches(input);
    final tokens = <Token>[];

    for (final match in matches) {
      final text = match.group(0) ?? '';
      if (text.isEmpty) continue;

      final isWord = _wordCheckRegex.hasMatch(text);
      final cleanWord = isWord ? text.toLowerCase().replaceAll(RegExp(r"[^\p{L}\p{N}]", unicode: true), '') : '';

      tokens.add(
        Token(
          text: text,
          isWord: isWord,
          cleanWord: cleanWord,
        ),
      );
    }

    return tokens;
  }

  /// Splits arbitrary large text into sentences/paragraphs for import as Segments
  static List<String> splitIntoSentences(String text) {
    final cleaned = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final paragraphs = cleaned.split(RegExp(r'\n{2,}'));
    final result = <String>[];

    // Sentence boundary regex
    final sentenceEndRegex = RegExp(r'(?<=[.!?…])\s+(?=[A-ZА-ЯЁ\p{Lu}])', unicode: true);

    for (final paragraph in paragraphs) {
      final trimmedPara = paragraph.trim();
      if (trimmedPara.isEmpty) continue;

      final lines = trimmedPara.split('\n');
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        final sentences = trimmedLine.split(sentenceEndRegex);
        for (final s in sentences) {
          final sTrimmed = s.trim();
          if (sTrimmed.isNotEmpty) {
            result.add(sTrimmed);
          }
        }
      }
    }

    return result;
  }
}

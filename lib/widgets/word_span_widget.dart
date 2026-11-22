import 'package:flutter/material.dart';
import '../models/word_item.dart';
import '../utils/text_tokenizer.dart';

class WordSpanWidget extends StatelessWidget {
  final Token token;
  final WordItem? savedWord;
  final double fontSize;
  final VoidCallback? onTap;

  const WordSpanWidget({
    super.key,
    required this.token,
    this.savedWord,
    required this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!token.isWord) {
      return Text(
        token.text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.6,
          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.85),
        ),
      );
    }

    final isLearning = savedWord?.status == 'learning';
    final isKnown = savedWord?.status == 'known';

    Color? backgroundColor;
    Color? borderColor;
    if (isLearning) {
      backgroundColor = Colors.amber.withOpacity(0.35);
      borderColor = Colors.amber.shade700.withOpacity(0.5);
    } else if (isKnown) {
      backgroundColor = Colors.green.withOpacity(0.18);
      borderColor = Colors.green.shade600.withOpacity(0.3);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.5),
        padding: EdgeInsets.symmetric(
          horizontal: isLearning || isKnown ? 3.0 : 1.0,
          vertical: 1.0,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
          border: borderColor != null ? Border.all(color: borderColor, width: 0.8) : null,
        ),
        child: Text(
          token.text,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.4,
            fontWeight: isLearning ? FontWeight.w600 : FontWeight.normal,
            color: isLearning
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.amber.shade200
                    : Colors.amber.shade900)
                : (isKnown
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.green.shade200
                        : Colors.green.shade900)
                    : Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ),
      ),
    );
  }
}

import '../models/word_item.dart';

enum ReviewRating {
  again, // 1
  hard,  // 3
  good,  // 4
  easy,  // 5
}

class SrsService {
  static const double minEaseFactor = 1.3;
  static const double defaultEaseFactor = 2.5;

  /// Update word after a flashcard review using SM-2 algorithm
  static WordItem processReview(WordItem word, ReviewRating rating) {
    int quality;
    switch (rating) {
      case ReviewRating.again:
        quality = 1;
        break;
      case ReviewRating.hard:
        quality = 3;
        break;
      case ReviewRating.good:
        quality = 4;
        break;
      case ReviewRating.easy:
        quality = 5;
        break;
    }

    int newInterval;
    double newEase = word.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEase < minEaseFactor) newEase = minEaseFactor;

    if (quality < 3) {
      // Failed / Again
      newInterval = 1;
    } else {
      // Success
      if (word.intervalDays == 0) {
        newInterval = (rating == ReviewRating.easy) ? 2 : 1;
      } else if (word.intervalDays == 1) {
        newInterval = (rating == ReviewRating.easy) ? 4 : 3;
      } else {
        newInterval = (word.intervalDays * newEase).round();
        if (rating == ReviewRating.easy) {
          newInterval = (newInterval * 1.3).round();
        }
      }
    }

    final now = DateTime.now();
    final nextReviewDate = now.add(Duration(days: newInterval));

    return word.copyWith(
      intervalDays: newInterval,
      easeFactor: double.parse(newEase.toStringAsFixed(2)),
      nextReviewAt: nextReviewDate.millisecondsSinceEpoch,
      status: 'learning',
    );
  }

  /// When a user simply clicks "Learning" on a word
  static WordItem markAsLearning(WordItem word) {
    final now = DateTime.now();
    final nextReviewDate = now.add(const Duration(days: 1));
    return word.copyWith(
      status: 'learning',
      intervalDays: 1,
      easeFactor: word.easeFactor > 0 ? word.easeFactor : defaultEaseFactor,
      nextReviewAt: nextReviewDate.millisecondsSinceEpoch,
    );
  }

  /// When a user clicks "Known" on a word
  static WordItem markAsKnown(WordItem word) {
    final now = DateTime.now();
    final nextReviewDate = now.add(const Duration(days: 180)); // 6 months
    return word.copyWith(
      status: 'known',
      intervalDays: 180,
      easeFactor: word.easeFactor > 0 ? word.easeFactor : defaultEaseFactor,
      nextReviewAt: nextReviewDate.millisecondsSinceEpoch,
    );
  }
}

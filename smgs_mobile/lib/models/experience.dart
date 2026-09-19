enum UserRole { visitor, staff, administrator }

class VisitorUser {
  const VisitorUser({
    required this.name,
    required this.email,
    this.role = UserRole.visitor,
  });
  final String name, email;
  final UserRole role;
}

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.points = 10,
  });
  final String question, explanation;
  final List<String> options;
  final int correctIndex, points;
}

class QuizResult {
  const QuizResult({
    required this.artifactId,
    required this.correct,
    required this.total,
    required this.points,
    required this.date,
  });
  final String artifactId;
  final int correct, total, points;
  final DateTime date;
  String? get badge => correct == total ? 'Người bạn của di sản' : null;
}

class TourRecord {
  const TourRecord({
    required this.id,
    required this.museumId,
    required this.date,
    required this.visitedIds,
    required this.skippedIds,
    required this.completed,
  });
  final String id, museumId;
  final DateTime date;
  final List<String> visitedIds, skippedIds;
  final bool completed;
}

class VisitRecord {
  VisitRecord({required this.id, required this.museumId, required this.date});
  final String id, museumId;
  final DateTime date;
  final Set<String> artifactIds = {};
  final List<QuizResult> quizzes = [];
  final List<TourRecord> tours = [];
}

class FeedbackEntry {
  const FeedbackEntry({
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.rating,
    required this.comment,
    required this.date,
  });
  final String targetType, targetId, targetName, rating, comment;
  final DateTime date;
}

enum DigitalServiceKind { guide, narration, tour, exhibition }

class PremiumOffer {
  const PremiumOffer({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.kind,
  });
  final String id, name, description;
  final int price;
  final DigitalServiceKind kind;
}

class ServicePurchase {
  const ServicePurchase({
    required this.id,
    required this.offer,
    required this.museumId,
    required this.date,
    required this.method,
  });
  final String id, museumId, method;
  final PremiumOffer offer;
  final DateTime date;
  bool isForDay(DateTime other) =>
      date.year == other.year &&
      date.month == other.month &&
      date.day == other.day;
}

String vietnameseDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String vietnamesePrice(int price) =>
    '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')} đ';

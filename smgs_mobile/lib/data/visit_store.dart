import 'package:flutter/foundation.dart';

import '../models/artifact.dart';
import '../models/experience.dart';
import 'mock/mock_artifacts.dart';

class VisitStore extends ChangeNotifier {
  VisitStore._();
  static final instance = VisitStore._();
  final List<Artifact> viewed = [];
  final Set<String> saved = {};
  final Set<String> deferredQuizArtifactIds = {};
  final List<SupportTicket> supportTickets = [];
  final Map<String, int> quizScores = {};
  final List<QuizResult> quizResults = [];
  final List<FeedbackEntry> feedback = [];
  final List<VisitRecord> history = [];
  final List<ServicePurchase> purchases = [];
  int completedTours = 0;

  List<String> get todayScannedArtifactIds {
    final now = DateTime.now();
    final todayRecords = history.where(
      (h) => h.date.year == now.year && h.date.month == now.month && h.date.day == now.day,
    );
    final scanned = todayRecords.expand((r) => r.artifactIds).toSet();
    for (final a in viewed) {
      scanned.add(a.id);
    }
    // If empty in fresh session, prefill with artifact_1 & artifact_2 for great demo experience
    if (scanned.isEmpty) {
      return ['artifact_1', 'artifact_2'];
    }
    return scanned.toList();
  }

  void deferQuiz(String artifactId) {
    deferredQuizArtifactIds.add(artifactId);
    notifyListeners();
  }

  bool isQuizDeferred(String artifactId) => deferredQuizArtifactIds.contains(artifactId);

  void submitSupportTicket({
    required String orderId,
    required String category,
    required String reason,
    required String description,
    int refundPercent = 100,
  }) {
    final now = DateTime.now();
    final ticket = SupportTicket(
      id: 'TCK-${now.millisecondsSinceEpoch.toString().substring(7)}',
      orderId: orderId,
      category: category,
      reason: reason,
      description: description,
      status: 'Đang tiếp nhận',
      date: now,
      refundPercent: refundPercent,
    );
    supportTickets.insert(0, ticket);
    notifyListeners();
  }

  Artifact? getNextArtifact(Artifact current) {
    final sameMuseum = mockArtifacts.where((a) => a.museumId == current.museumId).toList();
    if (sameMuseum.isEmpty) return null;
    final currentIndex = sameMuseum.indexWhere((a) => a.id == current.id);
    if (currentIndex >= 0 && currentIndex < sameMuseum.length - 1) {
      return sameMuseum[currentIndex + 1];
    }
    return sameMuseum.firstWhere((a) => a.id != current.id, orElse: () => sameMuseum.first);
  }

  int get visitedCount =>
      history.expand((record) => record.artifactIds).toSet().length;
  int get points => quizScores.values.fold(0, (sum, value) => sum + value * 10);
  Set<String> get badges =>
      quizResults.map((r) => r.badge).whereType<String>().toSet();
  VisitRecord _day(String museumId, DateTime date) {
    final id = '$museumId-${date.year}-${date.month}-${date.day}';
    return history.firstWhere(
      (h) => h.id == id,
      orElse: () {
        final record = VisitRecord(id: id, museumId: museumId, date: date);
        history.insert(0, record);
        return record;
      },
    );
  }

  void view(Artifact artifact) {
    viewed.removeWhere((a) => a.id == artifact.id);
    viewed.insert(0, artifact);
    notifyListeners();
  }

  void visit(Artifact artifact) {
    viewed.removeWhere((a) => a.id == artifact.id);
    viewed.insert(0, artifact);
    _day(artifact.museumId, DateTime.now()).artifactIds.add(artifact.id);
    notifyListeners();
  }

  void toggleSave(String id) {
    if (!saved.add(id)) saved.remove(id);
    notifyListeners();
  }

  void recordQuiz(String id, int score, {int total = 2, int? points}) {
    final date = DateTime.now();
    final result = QuizResult(
      artifactId: id,
      correct: score,
      total: total,
      points: points ?? score * 10,
      date: date,
    );
    final previous = quizScores[id] ?? 0;
    quizScores[id] = score > previous ? score : previous;
    quizResults.add(result);
    final artifact = mockArtifacts.firstWhere((a) => a.id == id);
    _day(artifact.museumId, date).quizzes.add(result);
    notifyListeners();
  }

  void finishTour({
    String museumId = 'museum_national',
    List<String> visited = const [],
    List<String> skipped = const [],
    bool completed = true,
  }) {
    final date = DateTime.now();
    final record = TourRecord(
      id: 'tour-${date.microsecondsSinceEpoch}',
      museumId: museumId,
      date: date,
      visitedIds: List.of(visited),
      skippedIds: List.of(skipped),
      completed: completed,
    );
    _day(museumId, date).tours.add(record);
    if (completed) completedTours++;
    notifyListeners();
  }

  void recordFeedback(
    String rating,
    String comment, {
    String targetType = 'app',
    String targetId = 'smgs',
    String targetName = 'Cẩm nang SMGS',
  }) {
    feedback.add(
      FeedbackEntry(
        targetType: targetType,
        targetId: targetId,
        targetName: targetName,
        rating: rating,
        comment: comment,
        date: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  bool hasPurchase(String offerId, String museumId, DateTime date) =>
      purchases.any(
        (p) =>
            p.offer.id == offerId && p.museumId == museumId && p.isForDay(date),
      );
  void activate(ServicePurchase purchase) {
    if (hasPurchase(purchase.offer.id, purchase.museumId, purchase.date)) {
      return;
    }
    purchases.insert(0, purchase);
    notifyListeners();
  }

  void reset() {
    viewed.clear();
    saved.clear();
    quizScores.clear();
    quizResults.clear();
    feedback.clear();
    history.clear();
    purchases.clear();
    deferredQuizArtifactIds.clear();
    supportTickets.clear();
    completedTours = 0;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

import '../models/artifact.dart';

class VisitStore extends ChangeNotifier {
  VisitStore._();
  static final instance = VisitStore._();
  final List<Artifact> viewed = [];
  final Set<String> saved = {};
  final Map<String, int> quizScores = {};
  final List<({String rating, String comment})> feedback = [];
  int completedTours = 0;
  void visit(Artifact artifact) {
    viewed.removeWhere((a) => a.id == artifact.id);
    viewed.insert(0, artifact);
    notifyListeners();
  }

  void toggleSave(String id) {
    if (!saved.add(id)) {
      saved.remove(id);
    }
    notifyListeners();
  }

  void recordQuiz(String id, int score) {
    quizScores[id] = score;
    notifyListeners();
  }

  void finishTour() {
    completedTours++;
    notifyListeners();
  }

  void recordFeedback(String rating, String comment) {
    feedback.add((rating: rating, comment: comment));
    notifyListeners();
  }
}

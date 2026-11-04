import 'package:flutter_test/flutter_test.dart';
import 'package:smgs_mobile/services/vision_api_service.dart';

void main() {
  test(
    'Ambiguous Vision result retains canonical candidates and their similarity',
    () {
      final result = VisionMatchResult.fromJson({
        'matched': false,
        'artifactId': null,
        'requiresConfirmation': true,
        'similarity': 0.88,
        'margin': 0.01,
        'candidates': [
          {'artifactId': 7, 'similarity': 0.88},
          {'artifactId': 9, 'similarity': 0.87},
        ],
      });
      expect(result.matched, isFalse);
      expect(result.requiresConfirmation, isTrue);
      expect(result.artifactId, isNull);
      expect(result.topCandidates.map((c) => c.artifactId), [7, 9]);
      expect(result.topCandidates.first.score, 0.88);
    },
  );
}

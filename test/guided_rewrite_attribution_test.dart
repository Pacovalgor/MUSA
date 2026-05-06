import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/musa/models/guided_rewrite.dart';

void main() {
  group('GuidedRewriteAction attribution', () {
    test('exposes stable feedback slugs per guided rewrite action', () {
      expect(
        GuidedRewriteAction.raiseTension.feedbackSlug,
        'guided-rewrite.raise-tension',
      );
      expect(
        GuidedRewriteAction.clarify.feedbackSlug,
        'guided-rewrite.clarify',
      );
      expect(
        GuidedRewriteAction.reduceExposition.feedbackSlug,
        'guided-rewrite.reduce-exposition',
      );
      expect(
        GuidedRewriteAction.naturalizeDialogue.feedbackSlug,
        'guided-rewrite.naturalize-dialogue',
      );
    });
  });
}

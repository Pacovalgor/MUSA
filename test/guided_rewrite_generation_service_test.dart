import 'package:flutter_test/flutter_test.dart';
import 'package:musa/modules/musa/models/guided_rewrite.dart';
import 'package:musa/modules/musa/services/guided_rewrite_generation_service.dart';

void main() {
  group('GuidedRewriteGenerationService', () {
    test('falls back to deterministic rewrite when model is not ready',
        () async {
      const service = GuidedRewriteGenerationService(
        modelClient: _FakeModelClient(isReady: false, response: ''),
      );

      final result = await service.rewrite(
        selection: 'Diane abrió la puerta. La carta estaba sobre la mesa.',
        action: GuidedRewriteAction.raiseTension,
      );

      expect(result.source, GuidedRewriteSource.deterministic);
      expect(result.suggestedText, contains('carta'));
    });

    test('uses local model output when it is compact and safe', () async {
      const service = GuidedRewriteGenerationService(
        modelClient: _FakeModelClient(
          isReady: true,
          response:
              'Diane abrió la puerta. La carta seguía sobre la mesa, quieta.',
        ),
      );

      final result = await service.rewrite(
        selection: 'Diane abrió la puerta. La carta estaba sobre la mesa.',
        action: GuidedRewriteAction.raiseTension,
      );

      expect(result.source, GuidedRewriteSource.localModel);
      expect(result.suggestedText, contains('quieta'));
      expect(result.safetyAudit.level, GuidedRewriteSafetyLevel.safe);
    });

    test('falls back when model introduces unsafe new names', () async {
      const service = GuidedRewriteGenerationService(
        modelClient: _FakeModelClient(
          isReady: true,
          response: 'Diane abrió la puerta. Clara esperaba junto a la carta.',
        ),
      );

      final result = await service.rewrite(
        selection: 'Diane abrió la puerta. La carta estaba sobre la mesa.',
        action: GuidedRewriteAction.raiseTension,
      );

      expect(result.source, GuidedRewriteSource.deterministic);
      expect(result.suggestedText, isNot(contains('Clara')));
      expect(result.editorComment, contains('fallback'));
    });

    test('builds prompts with strict output contract', () {
      final prompt = const GuidedRewritePromptBuilder().build(
        selection: 'Diane abrió la puerta.',
        action: GuidedRewriteAction.clarify,
      );

      expect(prompt, contains('Devuelve solo el texto reescrito'));
      expect(prompt, contains('No expliques'));
      expect(prompt, contains('Diane abrió la puerta.'));
    });
  });
}

class _FakeModelClient implements GuidedRewriteModelClient {
  const _FakeModelClient({
    required this.isReady,
    required this.response,
  });

  @override
  final bool isReady;

  final String response;

  @override
  Future<String> rewrite(GuidedRewriteModelRequest request) async {
    return response;
  }
}

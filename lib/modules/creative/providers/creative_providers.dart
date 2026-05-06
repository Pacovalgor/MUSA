import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/providers/workspace_providers.dart';
import '../models/creative_card.dart';

final activeCreativeCardsProvider = Provider<List<CreativeCard>>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.activeBookCreativeCards ??
      const [];
});

final visibleCreativeCardsProvider = Provider<List<CreativeCard>>((ref) {
  return ref
      .watch(activeCreativeCardsProvider)
      .where((card) => card.status != CreativeCardStatus.archived)
      .toList();
});

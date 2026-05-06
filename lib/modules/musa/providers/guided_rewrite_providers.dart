import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/guided_rewrite_planner.dart';

final guidedRewritePlannerProvider = Provider<GuidedRewritePlanner>((ref) {
  return const GuidedRewritePlanner();
});

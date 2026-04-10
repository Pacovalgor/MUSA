import 'package:flutter/foundation.dart';
import '../../../domain/ia/ia_interfaces.dart';
import '../../../domain/ia/engine_status.dart';
import '../../../domain/musa/musa_objects.dart';

class UnavailableIAService implements IAService {
  @override
  final ValueNotifier<EngineStatus> status = ValueNotifier(EngineStatus.unsupported);

  @override
  Stream<MusaSuggestion> processRequest(MusaRequest request) async* {
    // Return an error/empty suggestion immediately
    yield MusaSuggestion(
      id: "error",
      originalText: request.selection,
      suggestedText: "Motor de IA local no disponible.",
    );
  }

  @override
  void dispose() {
    status.dispose();
  }
}

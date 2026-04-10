import 'package:flutter/foundation.dart';
import '../musa/musa_objects.dart';
import 'engine_status.dart';

/// The core contract for any local IA engine in Musa.
abstract class IAService {
  /// Processes a request and returns a stream of chunks or a final suggestion.
  Stream<MusaResponse> processRequest(MusaRequest request);
  
  /// Current operational status of the local engine.
  ValueNotifier<EngineStatus> get status;
  
  void dispose();
}

/// Interface for preparing engine-specific prompts from a sovereign NarrativeContext.
abstract class MusaContextBuilder {
  String buildPrompt(MusaRequest request);
}

import '../../../domain/ia/ia_interfaces.dart';
import '../../../domain/musa/musa_objects.dart';

class DefaultContextBuilder implements MusaContextBuilder {
  @override
  String buildPrompt(MusaRequest request) {
    final summary = request.narrativeContext.projectSummary;
    final facts = request.narrativeContext.knownFacts.join(", ");

    return """
CONTEXTO GLOBAL:
Libro: ${request.narrativeContext.bookTitle}
Documento: ${request.documentTitle}
Resumen: $summary
Hechos: $facts

DOCUMENTO ACTUAL:
${request.documentContext}

SELECCIÓN A INTERVENIR:
${request.selection}

PREFERENCIAS DEL USUARIO:
${request.settings.editorialIntensityInstruction}
${request.settings.fragmentFidelityInstruction}
${request.settings.scopeProtectionInstruction}
${request.settings.preferredToneInstruction}
${request.settings.musaIntensityInstruction(request.musa)}

INSTRUCCIÓN:
${request.musa.promptContract}

Devuelve el texto mejorado de forma natural y literaria. Solo el texto.
"""
        .trim();
  }
}

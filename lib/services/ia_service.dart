abstract class IAService {
  Future<String> generateText(String prompt);
}

class MockIAService implements IAService {
  @override
  Future<String> generateText(String prompt) async {
    // Delay to simulate AI generation
    await Future.delayed(const Duration(seconds: 2));
    
    if (prompt.contains('Reescribir')) {
      return "Esta es una versión reescrita de tu texto con un estilo más refinado y editorial.";
    } else if (prompt.contains('Tensión')) {
      return "El aire se volvió denso, casi irrespirable. Cada paso resonaba como un martillazo en el silencio de la estancia.";
    }
    
    return "Musa ha procesado tu solicitud: Generando contenido creativo basado en el contexto de tu proyecto...";
  }
}

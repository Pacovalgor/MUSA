/// Guía de accesibilidad para el editor MUSA
/// Implementa shortcuts de teclado, soporte para lectores de pantalla, y high contrast

class KeyboardShortcuts {
  static const Map<String, String> shortcuts = {
    // Sugerencias
    'ctrl+enter': 'Aplicar sugerencia actual',
    'escape': 'Descartar sugerencia',
    'ctrl+z': 'Deshacer último cambio',
    'ctrl+y': 'Rehacer',

    // Navegación de historial
    'ctrl+,': 'Sugerencia anterior en historial',
    'ctrl+.': 'Sugerencia siguiente en historial',
    'ctrl+shift+h': 'Mostrar historial completo',

    // Navegación de pipeline
    'tab': 'Navegar siguientes pasos',
    'shift+tab': 'Navegar pasos anteriores',
    'alt+c': 'Focus en Clarity',
    'alt+r': 'Focus en Rhythm',
    'alt+s': 'Focus en Style',
    'alt+t': 'Focus en Tension',

    // Configuración y stats
    'ctrl+shift+d': 'Mostrar dashboard de efectividad',
    'ctrl+shift+,': 'Mostrar/ocultar settings',
  };

  static const String description = '''
SHORTCUTS DE TECLADO PARA MUSA:

Sugerencias:
  Ctrl+Enter    Aplicar sugerencia
  Escape        Descartar
  Ctrl+Z        Deshacer
  Ctrl+Y        Rehacer

Historial (últimas 5):
  Ctrl+,        Anterior
  Ctrl+.        Siguiente
  Ctrl+Shift+H  Ver todo

Pipeline:
  Tab           Siguiente paso
  Shift+Tab     Paso anterior
  Alt+C/R/S/T   Focus en musa específica

Configuración:
  Ctrl+Shift+D  Dashboard de efectividad
  Ctrl+Shift+,  Settings

En cualquier momento presiona F1 para esta guía.
''';
}

/// Configuración de accesibilidad
class AccessibilitySettings {
  /// Activar modo alto contraste
  static const bool highContrastMode = false;

  /// Tamaño de fuente aumentado (para discapacidades visuales)
  static const double baseFontSize = 14.0;
  static const double largeFontSize = 18.0;

  /// Espaciado aumentado
  static const double baseSpacing = 8.0;
  static const double largeSpacing = 12.0;

  /// Animaciones reducidas para usuarios sensibles al movimiento
  static const bool reduceMotion = false;

  /// Soporte para lectores de pantalla
  static const bool screenReaderSupport = true;

  /// Descripción de semantic para componentes
  static const Map<String, String> semanticLabels = {
    'apply_button': 'Aplicar sugerencia editorial actual',
    'discard_button': 'Descartar sugerencia sin aplicar',
    'clarity_musa': 'Musa de Claridad - simplifica y limpia',
    'rhythm_musa': 'Musa de Ritmo - mejora cadencia y flujo',
    'style_musa': 'Musa de Estilo - refina vocabulario',
    'tension_musa': 'Musa de Tensión - intensifica drama',
    'previous_button': 'Mostrar sugerencia anterior del historial',
    'next_button': 'Mostrar siguiente sugerencia del historial',
    'dashboard_button': 'Abrir dashboard de estadísticas de musas',
    'pipeline_progress': 'Progreso del pipeline actual de edición',
  };
}

/// Convenciones de color para accesibilidad
class AccessibilityColors {
  /// WCAG AA compliant contrast ratios
  /// Text on background: min 4.5:1
  /// UI components: min 3:1

  static const double wcagAAContrastRatio = 4.5;
  static const double wcagAContrastRatio = 3.0;

  // Paleta segura
  static const Color highContrastText = Color(0xFF000000);
  static const Color highContrastBackground = Color(0xFFFFFFFF);

  static const Color successColor = Color(0xFF0B8A3F); // verde accesible
  static const Color warningColor = Color(0xFFFFA500); // naranja accesible
  static const Color errorColor = Color(0xFFD32F2F); // rojo accesible
  static const Color infoColor = Color(0xFF1976D2); // azul accesible

  // No usar SOLO color para indicar estado
  // Siempre acompañar con: iconos, texto, patrones
}

/// Widget helper para accesibilidad
class AccessibilityHelper {
  /// Crear un botón accesible
  static String buildAccessibleButton(
    String label,
    String? tooltip,
    String? semanticLabel,
  ) {
    final semantic = semanticLabel ?? label;
    final help = tooltip ?? '';
    return 'Button($label, semantic=$semantic, tooltip=$help)';
  }

  /// Crear texto accesible
  static String buildAccessibleText(
    String text,
    String? semanticLabel,
    double? fontSize,
  ) {
    final semantic = semanticLabel ?? text;
    final size = fontSize ?? AccessibilitySettings.baseFontSize;
    return 'Text($text, semantic=$semantic, fontSize=$size)';
  }

  /// Validar contraste de color
  static bool hasAccessibleContrast(
    int color1,
    int color2, {
    bool strictMode = false,
  }) {
    // Implementación: calcular luminancia relativa según WCAG
    // y verificar si supera el ratio mínimo (4.5:1 para texto)
    return true; // Placeholder
  }

  /// Proporcionar descripciones para lectores de pantalla
  static String generateAccessibleDescription(String featureName) {
    return switch (featureName) {
      'clarity' =>
        'Musa de Claridad: Elimina palabras innecesarias y simplifica estructura. '
            'Ideal para párrafos confusos o densos.',
      'rhythm' =>
        'Musa de Ritmo: Mejora la cadencia del texto variando longitud de oraciones. '
            'Crea flujo más natural y placentero.',
      'style' =>
        'Musa de Estilo: Refina vocabulario y precisión léxica. '
            'Eleva la calidad literaria sin cambiar significado.',
      'tension' =>
        'Musa de Tensión: Intensifica drama y carga emocional. '
            'Agrega detalles sensoriales y diálogos.',
      'history' =>
        'Historial de sugerencias: Las últimas 5 ediciones. '
            'Puedes navegar hacia atrás o adelante en el tiempo.',
      'dashboard' =>
        'Dashboard de efectividad: Estadísticas de cuál musa funciona mejor contigo. '
            'Porcentaje de aceptación y tendencias.',
      'pipeline' =>
        'Pipeline visual: Muestra cuál musa está ejecutando ahora, '
            'cuáles ya completaron, y cuáles están pendientes.',
      _ => 'Feature $featureName',
    };
  }
}

// Nota: Esta es una guía/plantilla. La implementación real requiere
// integración con widgets de Flutter (Semantics, GestureDetector, etc.)

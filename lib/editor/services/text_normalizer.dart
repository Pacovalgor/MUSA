/// Normalizador de texto para análisis narrativo.
///
/// Provee:
/// - `stripAccents`: quita tildes y diéresis (ü→u), mantiene `ñ`. Tolera
///   variantes de escritura ("vergüenza" / "verguenza").
/// - `stem`: stemmer ligero de español (Snowball-light). Convergente para
///   conjugaciones regulares y plurales; NO maneja verbos con cambio de
///   raíz (perder→perdió, pedir→pidió).
/// - `stemmedContains` / `stemmedAnyContains`: matching tolerante a
///   morfología para tokens de una sola palabra. Para frases multi-palabra
///   hace fallback a `contains` insensible a tildes.
class TextNormalizer {
  /// Quita tildes y diéresis (ü→u, Ü→U); mantiene ñ/Ñ.
  static String stripAccents(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    for (final code in input.runes) {
      buffer.writeCharCode(_accentMap[code] ?? code);
    }
    return buffer.toString();
  }

  /// Stem ligero de español. Recorta sufijos verbales y nominales comunes
  /// para que las distintas formas de un verbo regular converjan al mismo
  /// stem. Limitaciones:
  ///   - No reconoce diptongos irregulares (perder→pierde→perdió queda en
  ///     dos stems distintos).
  ///   - No maneja participios irregulares (descubierto, hecho, dicho).
  ///   - Es heurístico: prefiere falsos negativos a falsos positivos.
  static String stem(String word) {
    var w = stripAccents(word.toLowerCase());
    if (w.length < 4) return w;

    for (final suffix in _suffixes) {
      if (w.length - suffix.length >= 3 && w.endsWith(suffix)) {
        return w.substring(0, w.length - suffix.length);
      }
    }
    return w;
  }

  /// True si en `haystack` hay alguna palabra cuyo stem coincide con el de
  /// `needle`. Si `needle` contiene espacios (frase multi-palabra), hace
  /// fallback a contains insensible a tildes.
  static bool stemmedContains(String haystack, String needle) {
    if (haystack.isEmpty || needle.isEmpty) return false;

    if (needle.contains(' ')) {
      return stripAccents(haystack.toLowerCase())
          .contains(stripAccents(needle.toLowerCase()));
    }

    final needleStem = stem(needle);
    if (needleStem.isEmpty) return false;
    final lowered = haystack.toLowerCase();
    for (final match in wordPattern.allMatches(lowered)) {
      if (stem(match.group(0)!) == needleStem) return true;
    }
    return false;
  }

  /// Versión multi-needle de `stemmedContains`.
  static bool stemmedAnyContains(String haystack, List<String> needles) {
    if (needles.isEmpty) return false;
    for (final needle in needles) {
      if (stemmedContains(haystack, needle)) return true;
    }
    return false;
  }

  /// Patrón para tokenizar palabras del español. Útil para callers que
  /// necesitan iterar matches y mirar contexto (ej. detectar negación).
  static final RegExp wordPattern =
      RegExp(r'[a-záéíóúñü]+', caseSensitive: false);

  // ─── internals ──────────────────────────────────────────────────

  /// Sufijos ordenados de más largo a más corto (greedy match).
  /// Cubre los casos más frecuentes de conjugación regular y plurales.
  static const List<String> _suffixes = <String>[
    // 6
    'aramos', 'eramos', 'iramos',
    'asemos', 'esemos', 'isemos',
    'aremos', 'eremos', 'iremos',
    'abamos',
    // 5
    'mente', 'antes', 'iendo', 'ieron', 'iamos',
    // 4
    'aron', 'aban', 'ando', 'arse', 'erse', 'irse', 'ente', 'ante',
    'ados', 'idos', 'adas', 'idas',
    'amos', 'emos', 'imos',
    // 3
    'ado', 'ido', 'ada', 'ida', 'aba', 'ian',
    // 2
    'ar', 'er', 'ir', 'an', 'en', 'as', 'es', 'ia', 'io',
    // 1
    's', 'o', 'a', 'e',
  ];

  /// Mapa de runas para `stripAccents`. Cubre vocales con tilde aguda y
  /// diéresis. Mantiene ñ/Ñ intactas.
  static const Map<int, int> _accentMap = <int, int>{
    0xE1: 0x61, // á → a
    0xE9: 0x65, // é → e
    0xED: 0x69, // í → i
    0xF3: 0x6F, // ó → o
    0xFA: 0x75, // ú → u
    0xFC: 0x75, // ü → u
    0xC1: 0x41, // Á → A
    0xC9: 0x45, // É → E
    0xCD: 0x49, // Í → I
    0xD3: 0x4F, // Ó → O
    0xDA: 0x55, // Ú → U
    0xDC: 0x55, // Ü → U
  };
}


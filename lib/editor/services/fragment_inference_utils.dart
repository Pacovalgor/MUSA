class FragmentInferenceUtils {
  static const topLevelGeography = <String>{
    'San Francisco',
    'Oakland',
    'Los Ángeles',
    'Los Angeles',
    'Mission District',
    'Bernal Heights',
  };

  static const monthWords = <String>{
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'setiembre',
    'octubre',
    'noviembre',
    'diciembre',
  };

  static const geographyDescriptorWords = <String>{
    'street',
    'st',
    'avenue',
    'ave',
    'road',
    'rd',
    'boulevard',
    'blvd',
    'district',
    'heights',
    'city',
    'park',
    'harbor',
    'harbour',
    'pier',
    'bay',
    'square',
    'plaza',
    'lane',
    'drive',
    'court',
    'way',
    'place',
    'center',
    'centre',
    'calle',
    'avenida',
    'carretera',
    'camino',
    'distrito',
    'barrio',
    'muelle',
    'parque',
    'puerto',
  };

  static const scenarioCoreWords = <String>[
    'callejón',
    'apartamento',
    'estudio',
    'redacción',
    'cafetería',
    'bar',
    'restaurante',
    'oficina',
    'hospital',
    'escena del crimen',
    'muelle',
    'taller',
    'almacén',
    'biblioteca',
    'laboratorio',
    'parque',
    'casa',
    'habitación',
    'despacho',
    'pasillo',
    'azotea',
    'garaje',
    'portal',
    'avenida',
    'calle',
    'carretera',
  ];

  static const blockedCharacterWords = <String>{
    'El',
    'La',
    'Los',
    'Las',
    'Un',
    'Una',
    'Uno',
    'Y',
    'Pero',
    'No',
    'Me',
    'Mi',
    'Yo',
    'Lo',
    'Le',
    'Se',
    'Ella',
    'Él',
    'Eso',
    'Esto',
    'Ese',
    'Esa',
    'Aquel',
    'Aquella',
    'Alguien',
    'Algo',
    'Nada',
    'Nadie',
    'Todo',
    'Todos',
    'Todas',
    'Otro',
    'Otra',
    'Otros',
    'Otras',
    'Desde',
    'Como',
    'Por',
    'Quiero',
    'Hoy',
    'Ayer',
    'Mañana',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
    'Norte',
    'Sur',
    'Este',
    'Oeste',
    'Mission',
    'San',
    'Francisco',
    'District',
    'Twitter',
    'X',
    'Instagram',
    'Google',
    'WhatsApp',
    'Entendido',
    'Vale',
    'Bien',
    'Hecho',
    'Claro',
    'Perfecto',
    'Exacto',
    'Noviembre',
    'Diciembre',
    'Enero',
    'Rápida',
    'Rapida',
    'Alta',
    'Central',
    'Noche',
  };

  static const commonNonEntityWords = <String>{
    'nada',
    'nadie',
    'algo',
    'alguien',
    'todo',
    'todos',
    'todas',
    'otro',
    'otra',
    'otros',
    'otras',
    'desde',
    'como',
    'por',
    'quiero',
    'hoy',
    'ayer',
    'mañana',
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
    'antes',
    'después',
    'siempre',
    'nunca',
    'solo',
    'sólo',
    'quizá',
    'quizas',
    'quizás',
    'líneas',
    'lineas',
    'formas',
    'sombras',
    'pasos',
    'ruidos',
    'señales',
    'detalles',
    'marcas',
    'notas',
    'grafitis',
    'grietas',
    'entendido',
    'vale',
    'bien',
    'hecho',
    'claro',
    'perfecto',
    'exacto',
    'noviembre',
    'diciembre',
    'enero',
    'demasiado',
    'rápida',
    'rapida',
    'alta',
    'central',
    'noche',
  };

  static const narrativeVerbNonEntities = <String>{
    'Pienso',
    'Creo',
    'Recuerdo',
    'Siento',
    'Miro',
    'Camino',
    'Reviso',
    'Preparo',
    'Llevo',
    'Entro',
    'Salgo',
    'Llego',
    'Vivo',
    'Estoy',
    'Estaba',
    'Había',
    'Pensé',
    'Vi',
    'Oí',
    'Escuché',
    'Encontré',
    'Seguí',
    'Tomé',
    'Dejé',
    'Cerré',
    'Noté',
    'Observé',
    'Corrí',
    'Temí',
    'Imaginé',
    'Intenté',
    'Recordé',
    'Sabía',
    'Quería',
    'Debía',
    'Busco',
    'Pruebo',
    'Suspiro',
    'Encuentro',
    'Guardo',
    'Decido',
    'Escribía',
    'Llevaba',
    'Fui',
    'Soy',
    'Entré',
    'Salí',
    'Llegué',
    'Dije',
    'Volví',
    'Hice',
    'Podía',
  };

  static const narrativeNounNonEntities = <String>{
    'Líneas',
    'Lineas',
    'Formas',
    'Sombras',
    'Pasos',
    'Ruidos',
    'Señales',
    'Detalles',
    'Marcas',
    'Notas',
    'Grafitis',
    'Grietas',
  };

  static const firstPersonCues = <String>[
    ' yo ',
    ' me ',
    ' mi ',
    ' mis ',
    ' conmigo ',
    ' tengo ',
    ' puedo ',
    ' llevo ',
    ' entro ',
    ' salgo ',
    ' llego ',
    ' camino ',
    ' preparo ',
    ' reviso ',
    ' me levanto ',
    ' me despierto ',
    ' vivo ',
    ' estoy ',
    ' estaba ',
    ' había ',
    ' saqué ',
    ' abrí ',
    ' busqué ',
    ' miré ',
    ' me acerqué ',
    ' pregunté ',
    ' anoté ',
    ' pensé ',
    ' vi ',
    ' oí ',
    ' escuché ',
    ' encontré ',
    ' seguí ',
    ' tomé ',
    ' dejé ',
    ' cerré ',
    ' noté ',
    ' observé ',
    ' corrí ',
    ' temí ',
    ' imaginé ',
    ' intenté ',
    ' recordé ',
    ' sabía ',
    ' quería ',
    ' debía ',
    ' llevaba ',
    ' fui ',
    ' soy ',
    ' entré ',
    ' salí ',
    ' llegué ',
    ' dije ',
    ' volví ',
    ' hice ',
    ' podía ',
    ' no podía ',
  ];

  static const professionCues = <String>[
    'abogada',
    'abogado',
    'periodista',
    'reportera',
    'reportero',
    'detective',
    'profesora',
    'profesor',
    'médica',
    'médico',
    'doctora',
    'doctor',
    'escritora',
    'escritor',
    'becaria',
    'becario',
    'editora',
    'editor',
    'policía',
    'agente',
    'inspectora',
    'inspector',
    'fotógrafa',
    'fotógrafo',
    'enfermera',
    'enfermero',
    'camarera',
    'camarero',
    'cocinera',
    'cocinero',
    'recepcionista',
    'fiscal',
    'jueza',
    'juez',
    'taxista',
    'conductora',
    'conductor',
    'mecánica',
    'mecánico',
    'obrera',
    'obrero',
    'funcionaria',
    'funcionario',
    'bibliotecaria',
    'bibliotecario',
    'investigadora',
    'investigador',
    'analista',
  ];

  static const relationshipCues = <String>[
    'madre',
    'padre',
    'hermana',
    'hermano',
    'tía',
    'tio',
    'tío',
    'prima',
    'primo',
    'hija',
    'hijo',
    'novia',
    'novio',
    'pareja',
    'marido',
    'mujer',
    'amiga',
    'amigo',
    'jefa',
    'jefe',
    'vecina',
    'vecino',
    'compañera',
    'compañero',
    'editora',
    'editor',
    'profesora',
    'profesor',
    'inspectora',
    'inspector',
  ];

  static bool isBlockedCapitalizedWord(String value) {
    return blockedCharacterWords.contains(value) ||
        narrativeVerbNonEntities.contains(value) ||
        narrativeNounNonEntities.contains(value);
  }

  static bool isCommonNonEntityWord(String value) {
    final lowered = value.toLowerCase();
    return commonNonEntityWords.contains(lowered) ||
        narrativeVerbNonEntities.any((item) => item.toLowerCase() == lowered) ||
        narrativeNounNonEntities.any((item) => item.toLowerCase() == lowered);
  }

  static bool looksLikeOrganizationName(String name) {
    final lowered = name.trim().toLowerCase();
    if (lowered.isEmpty) return false;

    const organizationSignals = <String>[
      'times',
      'post',
      'news',
      'press',
      'media',
      'journal',
      'tribune',
      'chronicle',
      'gazette',
      'herald',
      'observer',
      'bulletin',
      'review',
      'wire',
      'standard',
      'ledger',
      'mirror',
      'lens',
    ];

    for (final signal in organizationSignals) {
      if (RegExp(r'(^|\\s)' + RegExp.escape(signal) + r'(\\s|$)')
          .hasMatch(lowered)) {
        return true;
      }
    }
    return false;
  }

  static bool looksLikeGeographicName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (topLevelGeography.contains(trimmed)) return true;

    final lowered = trimmed.toLowerCase();
    if (monthWords.contains(lowered)) return true;
    if (RegExp(r'\b\d{1,4}\b').hasMatch(lowered)) return true;

    final parts = lowered.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.any(geographyDescriptorWords.contains);
  }

  static bool appearsInGeographicContext(String text, String name) {
    final escaped = RegExp.escape(name);
    final patterns = <RegExp>[
      RegExp(
        r'\b(calle|avenida|carretera|camino|barrio|distrito|callejón|muelle|parque|plaza|portal|bar|cafetería|oficina|redacción|apartamento|estudio)\s+(de|del|en)\s+' +
            escaped +
            r'\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(en|desde|hasta|hacia|por|rumbo a|camino a|frente a|cerca de|junto a|dos manzanas de)\s+' +
            escaped +
            r'\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b' + escaped + r'\s+(street|st|avenue|ave|road|rd|boulevard|blvd|district|heights|city|park|harbor|pier)\b',
        caseSensitive: false,
      ),
    ];
    return patterns.any((pattern) => pattern.hasMatch(text));
  }

  static bool appearsInOrganizationContext(String text, String name) {
    final escaped = RegExp.escape(name);
    final patterns = <RegExp>[
      RegExp(
        r'\b(redacción|diario|medio|revista|periódico|editorial|newsroom|portal)\s+(de|del|en)\s+' +
            escaped +
            r'\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(beca|trabajo|prácticas|pasantía|puesto|empleo)\s+(en|de)\s+' +
            escaped +
            r'\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b' + escaped + r'\s+(está|era|tiene|publicó|encargó)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b' +
            escaped +
            r'\b.{0,48}\b(edificio|ventanas|suelos|oficina|fotocopiadora|escritorio|gestor de contenidos)\b',
        caseSensitive: false,
      ),
    ];
    return patterns.any((pattern) => pattern.hasMatch(text));
  }

  static bool appearsOnlyAtSentenceStart(String selection, String candidate) {
    final escaped = RegExp.escape(candidate);
    final total = RegExp(r'\b' + escaped + r'\b').allMatches(selection).length;
    if (total == 0) return false;
    final atStart = RegExp(
      r'(^|[.!?…\n"“”])\s*' + escaped + r'\b',
      multiLine: true,
    ).allMatches(selection).length;
    return atStart == total;
  }

  static bool hasLikelyHumanContext(String selection, String candidate) {
    final escaped = RegExp.escape(candidate);
    final patterns = <RegExp>[
      RegExp(
        r'\b' +
            escaped +
            r'\b.{0,40}\b(dijo|preguntó|miró|escribió|llamó|respondió|vio|pensó|sonrió|admitió|ordenó)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(dijo|preguntó|miró|escribió|llamó|respondió|vio|pensó|sonrió|ordenó)\b.{0,40}\b' +
            escaped +
            r'\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b' +
            escaped +
            r'\b.{0,40}\b(madre|padre|hermana|hermano|jefa|jefe|vecina|vecino|abogada|abogado|profesora|profesor|periodista|reportera|reportero|detective)\b',
        caseSensitive: false,
      ),
    ];
    return patterns.any((pattern) => pattern.hasMatch(selection));
  }

  static bool hasHumanContext(String selection, String name) {
    final escaped = RegExp.escape(name);
    final patterns = <RegExp>[
      RegExp(
        r'\b' +
            escaped +
            r'\s+(dijo|preguntó|respondió|escribió|miró|llamó|vio|pensó|sonrió|admitió|ordenó)\b',
      ),
      RegExp(r'\b' + escaped + r'\s+me\b'),
      RegExp(r'—[^—\n]{0,60}\b' + escaped + r'\b'),
      RegExp(
        r'\b(dijo|preguntó|respondió|escribió|miró|llamó|vio|pensó|sonrió|admitió|ordenó)\b.{0,40}\b' +
            escaped +
            r'\b',
      ),
      RegExp(
        r'\b' +
            escaped +
            r'\s+(estaba|estuvo|seguía|discutía|tecleaba|trabajaba|sonreía|se\s+giró|se\s+volvió|salió|entró|llevaba|cubría|acompañó)\b',
        caseSensitive: false,
      ),
    ];
    return patterns.any((pattern) => pattern.hasMatch(selection));
  }

  static bool hasDirectPresentationContext(String selection, String name) {
    final escaped = RegExp.escape(name);
    final patterns = <RegExp>[
      RegExp(
        r'\b' +
            escaped +
            r'\b.{0,40}\b(' +
            (professionCues + relationshipCues).join('|') +
            r')\b',
        caseSensitive: false,
      ),
      RegExp(r'mensaje de\s+' + escaped, caseSensitive: false),
      RegExp(r'\b' + escaped + r'\s*:\s*[“"]'),
    ];
    return patterns.any((pattern) => pattern.hasMatch(selection));
  }

  static bool isFullName(String candidate) {
    final parts = candidate
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length < 2) return false;
    for (final part in parts) {
      if (isBlockedCapitalizedWord(part) || isCommonNonEntityWord(part)) {
        return false;
      }
    }
    final lowered = candidate.toLowerCase();
    if (lowered.contains('san francisco') ||
        lowered.contains('mission district')) {
      return false;
    }
    return true;
  }

  static bool isSameCharacter(String a, String b) {
    final normalizedA = a.trim().toLowerCase();
    final normalizedB = b.trim().toLowerCase();
    if (normalizedA.isEmpty || normalizedB.isEmpty) return false;
    if (normalizedA == normalizedB) return true;
    if (normalizedA.contains(normalizedB) ||
        normalizedB.contains(normalizedA)) {
      return true;
    }
    final firstA = normalizedA.split(RegExp(r'\s+')).first;
    final firstB = normalizedB.split(RegExp(r'\s+')).first;
    final hasFullName =
        isFullName(a) || isFullName(b) || a.contains(' ') || b.contains(' ');
    return hasFullName && firstA.length > 2 && firstA == firstB;
  }

  static int computeCharacterStrength({
    required String name,
    required String context,
  }) {
    var score = 0;
    if (isFullName(name)) score += 3;
    if (inferProfession(context, name).isNotEmpty) score += 2;

    final escaped = RegExp.escape(name);
    final localContextMatch = RegExp(
      r'\b' + escaped + r'\b([^.!?\n]{0,120})',
      caseSensitive: false,
    ).firstMatch(context);
    final localContext =
        '${context.toLowerCase()} ${(localContextMatch?.group(1) ?? '').toLowerCase()}';

    if (RegExp(r'\b\d{1,3}\b').hasMatch(localContext) ||
        RegExp(
          r'\b(veinte|treinta|cuarenta|cincuenta|sesenta|setenta|ochenta|noventa)\b',
          caseSensitive: false,
        ).hasMatch(localContext)) {
      score += 2;
    }

    if (RegExp(
      r'\b(trabajaba como|era|se dedicaba a)\b',
      caseSensitive: false,
    ).hasMatch(localContext)) {
      score += 2;
    }

    if (hasDirectPresentationContext(context, name)) {
      score += 2;
    }

    if (relationshipCues
        .any((cue) => mentionsRelationshipCue(localContext, cue))) {
      score += 2;
    }

    if (RegExp(
      r'\b' +
          escaped +
          r'\s+(estaba|estuvo|seguía|discutía|tecleaba|trabajaba|sonreía|se\s+giró|se\s+volvió|salió|entró|llevaba|cubría|acompañó)\b',
      caseSensitive: false,
    ).hasMatch(context)) {
      score += 2;
    }

    if (hasHumanContext(context, name) ||
        RegExp(r'—[^—\n]{0,80}\b' + escaped + r'\b', caseSensitive: false)
            .hasMatch(context)) {
      score += 1;
    }

    return score;
  }

  static bool mentionsRelationshipCue(String normalized, String cue) {
    final pattern = RegExp(
      r'(^|[^a-záéíóúñ])(?:mi|su)\s+' +
          RegExp.escape(cue) +
          r'([^a-záéíóúñ]|$)|(^|[^a-záéíóúñ])' +
          RegExp.escape(cue) +
          r'\s+de\s+la\s+protagonista([^a-záéíóúñ]|$)|(^|[^a-záéíóúñ])' +
          RegExp.escape(cue) +
          r'\s+del\s+protagonista([^a-záéíóúñ]|$)',
      caseSensitive: false,
    );
    return pattern.hasMatch(normalized);
  }

  static String inferProfession(String selection, String name) {
    final escaped = RegExp.escape(name);
    final match = RegExp(
      r'\b' + escaped + r'\.\s*([A-ZÁÉÍÓÚÑa-záéíóúñ][^.!?\n]{3,80})[.!?\n]',
      caseSensitive: false,
    ).firstMatch(selection);
    if (match == null) return '';

    final sentence = match.group(1)!.trim();
    final lowered = sentence.toLowerCase();
    for (final cue in professionCues) {
      if (lowered.contains(cue)) {
        return sentence;
      }
    }
    return '';
  }

  static bool isLikelyFirstPersonNarrator(String selection) {
    final normalized = ' ${selection.trim().toLowerCase()} ';
    var score = 0;
    for (final cue in firstPersonCues) {
      if (normalized.contains(cue)) {
        score += 1;
      }
    }

    final hasMe = normalized.contains(' me ') || normalized.contains(' mi ');
    final hasFirstPersonVerb =
        RegExp(r'\b[a-záéíóúñ]+é\b', caseSensitive: false)
                .hasMatch(normalized) ||
            normalized.contains(' era ') ||
            normalized.contains(' estaba ') ||
            normalized.contains(' tenía ') ||
            normalized.contains(' quería ') ||
            normalized.contains(' sabía ') ||
            normalized.contains(' debía ');
    if (hasMe && hasFirstPersonVerb) {
      score += 2;
    }

    return score >= 2;
  }

  static bool isBroadGeographicContext(String candidate) {
    final normalized = candidate.trim();
    return topLevelGeography.contains(normalized);
  }

  static String? inferScenarioFunction(String context) {
    final normalized = ' ${context.toLowerCase()} ';
    if (_containsAny(normalized, <String>[
      ' sangre ',
      ' policía ',
      ' cinta ',
      ' cadáver ',
      ' cuerpo sin vida ',
      ' móvil caído ',
      ' contenedor abierto ',
    ])) {
      return 'Escena de crimen';
    }
    if (_containsAny(normalized, <String>[
      ' apartamento ',
      ' estudio ',
      ' cama ',
      ' cafetera ',
      ' patio interior ',
      ' refugio ',
    ])) {
      return 'Espacio de intimidad';
    }
    if (_containsAny(normalized, <String>[
      ' redacción ',
      ' oficina ',
      ' escritorio ',
      ' gestor de contenidos ',
      ' periodistas ',
    ])) {
      return 'Lugar de trabajo';
    }
    if (_containsAny(normalized, <String>[
      ' camino por ',
      ' cruzo ',
      ' avenida ',
      ' calle ',
      ' carretera ',
      ' paso frente ',
    ])) {
      return 'Zona de tránsito';
    }
    if (_containsAny(normalized, <String>[
      ' sala de espera ',
      ' pasillo ',
      ' urgencias ',
      ' espera ',
    ])) {
      return 'Espacio de espera';
    }
    if (_containsAny(normalized, <String>[
      ' observar ',
      ' miré ',
      ' vi ',
      ' focos ',
      ' desde la ventana ',
    ])) {
      return 'Lugar de observación';
    }
    return null;
  }

  static int computeScenarioStrength({
    required String name,
    required String context,
  }) {
    final normalized = ' ${context.toLowerCase()} ';
    var score = 0;

    if (!isBroadGeographicContext(name) &&
        scenarioCoreWords.any((word) => name.toLowerCase().contains(word))) {
      score += 3;
    } else if (!isBroadGeographicContext(name) && name.trim().isNotEmpty) {
      score += 2;
    }

    if (_containsAny(normalized, <String>[
      ' húmed',
      ' mojado ',
      ' vacío ',
      ' acordonado ',
      ' oscuro ',
      ' tranquilo ',
      ' pequeño ',
      ' precario ',
      ' tenso ',
      ' frío ',
      ' caliente ',
    ])) {
      score += 2;
    }

    if (_containsAny(normalized, <String>[
      ' móvil ',
      ' portátil ',
      ' libreta ',
      ' sangre ',
      ' contenedor ',
      ' café ',
      ' cámara ',
      ' expediente ',
      ' llave ',
      ' vaso ',
      ' mochila ',
      ' cinta amarilla ',
    ])) {
      score += 2;
    }

    if (inferScenarioFunction(context) != null) {
      score += 2;
    }

    final nameLower = name.toLowerCase();
    if (nameLower.isNotEmpty &&
        RegExp(RegExp.escape(nameLower))
                .allMatches(context.toLowerCase())
                .length >
            1) {
      score += 1;
    }

    if (isBroadGeographicContext(name) && score <= 2) {
      score = 1;
    }

    return score;
  }

  static bool isSameScenario(String a, String b) {
    final normalizedA = a.trim().toLowerCase();
    final normalizedB = b.trim().toLowerCase();
    if (normalizedA.isEmpty || normalizedB.isEmpty) return false;
    if (normalizedA == normalizedB) return true;
    if (normalizedA.contains(normalizedB) ||
        normalizedB.contains(normalizedA)) {
      return true;
    }
    for (final core in scenarioCoreWords) {
      if (normalizedA.contains(core) && normalizedB.contains(core)) {
        return true;
      }
    }
    return false;
  }

  static bool _containsAny(String normalized, List<String> terms) {
    for (final term in terms) {
      if (normalized.contains(term)) return true;
    }
    return false;
  }
}

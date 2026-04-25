/// Léxicos centralizados para detección y análisis de texto.
///
/// Toda lista de palabras-clave usada por `fragment_analysis_service.dart`
/// y `fragment_inference_utils.dart` vive aquí. La lógica de matching no
/// cambia: estas listas son sólo datos. Cuando haga falta añadir un nuevo
/// tipo de escenario, momento u objeto, este es el único punto a tocar.
///
/// Convenciones:
/// - Las listas que se buscan con `contains` sobre texto normalizado
///   `' ${text.toLowerCase()} '` mantienen los espacios envolventes
///   (` palabra `) para forzar word-boundary.
/// - Las listas que sirven para regex o lookup directo van sin espacios.
class TextAnalysisLexicons {
  // ─── Geografía ─────────────────────────────────────────────────

  static const Set<String> topLevelGeography = <String>{
    'San Francisco',
    'Oakland',
    'Los Ángeles',
    'Los Angeles',
    'Mission District',
    'Bernal Heights',
  };

  static const Set<String> monthWords = <String>{
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

  static const Set<String> geographyDescriptorWords = <String>{
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
    // Mansiones/edificios nombrados (libro 3, "Hallim House"):
    'house',
    'hall',
    'manor',
    'palace',
    'castle',
    'tavern',
    'inn',
  };

  // ─── Detección de personajes ───────────────────────────────────

  static const List<String> scenarioCoreWords = <String>[
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

  static const Set<String> blockedCharacterWords = <String>{
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
    // FPs detectados en diagnóstico libros 1/2/3:
    // verbos/adverbios capitalizados a inicio de oración + topónimos parciales
    'Puede',
    'Cuando',
    'Preparar',
    'Mira',
    'Hum',
    'Vamos',
    'Venga',
    'Vaya',
    'Ojalá',
    'Cerco',
    'Círculo',
    'Hallim',
    'Con',
    'Para',
    'Atiende',
  };

  static const Set<String> commonNonEntityWords = <String>{
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

  static const Set<String> narrativeVerbNonEntities = <String>{
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

  static const Set<String> narrativeNounNonEntities = <String>{
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

  /// Nombres propios capitalizados que aparecen en el texto pero no son
  /// personas (lugares específicos, marcas, redes sociales).
  static const Set<String> nonPersonProperNames = <String>{
    'Mission District',
    'San Francisco',
    'AirDrop',
    'X',
    'Twitter',
    'Instagram',
    'Google',
    'WhatsApp',
    'Mission',
    'District',
    'Policía',
    'Ambulancia',
    'Callejón',
    'Crimen',
    'Norte',
    'Sur',
    'Este',
    'Oeste',
    // Topónimos/instituciones detectados como personajes en libros 1/3:
    'Mar Sangriento',
    'Cerco Exterior',
    'Círculo Supremo',
    'Hallim House',
    'Remolino',
  };

  static const List<String> firstPersonCues = <String>[
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

  static const List<String> professionCues = <String>[
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

  static const List<String> relationshipCues = <String>[
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

  /// Tokens dentro de nombres que sugieren organización/medio.
  /// Usados por `looksLikeOrganizationName`.
  static const List<String> organizationSignals = <String>[
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

  // ─── Detección de tipo de escenario ────────────────────────────
  // Se buscan con `_containsAny` sobre texto normalizado
  // (` ${text.toLowerCase()} `), por eso van con espacios envolventes.

  static const List<String> newsroomSignals = <String>[
    ' redacción ',
    ' the bay lens ',
    ' newsroom ',
    ' oficina ',
    ' escritorio ',
    ' fotocopiadora ',
    ' gestor de contenidos ',
    ' periodistas ',
    ' teléfono ',
    ' ordenador ',
    ' segundo piso ',
    ' edificio ',
    ' ventanas ',
    ' suelos de madera ',
    ' calefacción ',
  ];

  static const List<String> pressIdentitySignals = <String>[
    ' becaria ',
    ' prensa ',
    ' periodista ',
    ' reportera ',
    ' reportero ',
    ' acreditación ',
    ' pase temporal ',
  ];

  /// Señales de "apartamento/espacio íntimo doméstico". OJO: las palabras
  /// genéricas (` casa `, ` habitación `, ` cuarto `, ` piso `) se quitaron
  /// porque disparaban FPs masivos en cualquier escena con mención casual
  /// a una vivienda (libro 2 epílogo, libro 3 alcoba). Quedan señales
  /// específicas que sólo aparecen al describir el espacio íntimo en sí.
  static const List<String> apartmentSignals = <String>[
    ' mi apartamento ',
    ' mi estudio ',
    ' apartamento ',
    ' estudio ',
    ' cama ',
    ' cafetera ',
    ' mochila ',
    ' bernal heights ',
    ' patio interior ',
    ' saxofón ',
    ' vecino ',
  ];

  /// Señales de cafetería. Nota: ` barra ` se ha movido sólo a
  /// `barRestaurantSignals` para no robarle bares (libro 2: el barman de
  /// "Christopher's" caía en cafetería).
  static const List<String> cafeSignals = <String>[
    ' cafetería ',
    ' chai ',
    ' mesa del fondo ',
    ' leche de avena ',
    ' café negro ',
    ' café en vasos ',
    ' vasos de cartón ',
    ' barista ',
  ];

  static const List<String> workshopSignals = <String>[
    ' taller ',
    ' herramientas ',
    ' banco de trabajo ',
    ' serrín ',
    ' grasa ',
    ' torno ',
    ' martillo ',
  ];

  static const List<String> warehouseSignals = <String>[
    ' almacén ',
    ' nave ',
    ' muelle ',
    ' cajas ',
    ' palés ',
    ' contenedor ',
    ' carga ',
    ' descarga ',
  ];

  static const List<String> hospitalSignals = <String>[
    ' hospital ',
    ' pasillo ',
    ' urgencias ',
    ' enfermera ',
    ' médico ',
    ' camilla ',
    ' sala de espera ',
  ];

  static const List<String> schoolSignals = <String>[
    ' instituto ',
    ' colegio ',
    ' aula ',
    ' pupitre ',
    ' pasillo del instituto ',
    ' universidad ',
    ' campus ',
    ' biblioteca ',
    ' laboratorio ',
  ];

  static const List<String> storeSignals = <String>[
    ' tienda ',
    ' escaparate ',
    ' mostrador ',
    ' cajero ',
    ' supermercado ',
    ' ultramarinos ',
    ' librería ',
    ' lavandería ',
  ];

  static const List<String> barRestaurantSignals = <String>[
    ' bar ',
    ' restaurante ',
    ' taquería ',
    ' cocina ',
    ' camarero ',
    ' barra ',
    ' barra del bar ',
    ' comedor ',
    ' terraza ',
    ' pub ',
    ' taburete ',
    ' barman ',
    ' whisky ',
    ' bourbon ',
    ' cóctel ',
    ' old fashioned ',
    ' copa ',
    ' garito ',
  ];

  static const List<String> parkSignals = <String>[
    ' parque ',
    ' banco ',
    ' césped ',
    ' estanque ',
    ' árboles ',
    ' columpios ',
    ' jardín ',
  ];

  static const List<String> roadSignals = <String>[
    ' avenida ',
    ' calle ',
    ' carretera ',
    ' autopista ',
    ' cruce ',
    ' semáforo ',
    ' arcén ',
    ' barrio ',
    ' portal ',
  ];

  static const List<String> townSignals = <String>[
    ' pueblo ',
    ' plaza ',
    ' ayuntamiento ',
    ' iglesia ',
    ' mercado ',
    ' calle mayor ',
    ' centro ',
  ];

  static const List<String> beachSignals = <String>[
    ' playa ',
    ' arena ',
    ' orilla ',
    ' mar ',
    ' acantilado ',
    ' paseo marítimo ',
  ];

  static const List<String> forestSignals = <String>[
    ' bosque ',
    ' sendero ',
    ' árboles altos ',
    ' maleza ',
    ' barro ',
    ' hojas secas ',
  ];

  static const List<String> streetTransitSignals = <String>[
    ' camino por ',
    ' cruzo ',
    ' paso frente ',
    ' taquería ',
    ' luces de neón ',
    ' esquina ',
    ' portal ',
    ' tienda de conveniencia ',
    ' cerca de ',
    ' al fondo de ',
    ' a las afueras de ',
    ' entre ',
    ' tras ',
    ' junto al ',
    ' junto a la ',
  ];

  // ─── Marcadores de crimen / atmósfera ──────────────────────────

  static const List<String> crimeSceneSignals = <String>[
    ' crimen ',
    ' policía ',
    ' sangre ',
    ' cinta ',
    ' ambulancia ',
    ' cadáver ',
    ' cuerpo había ',
    ' el cuerpo ',
    ' cuerpo fue ',
    ' cuerpo sin vida ',
    ' retirado ',
  ];

  /// Marcadores de humedad usados por la detección de crimen / clima.
  /// Nota: ' húmed' (sin cierre) es intencional — captura húmedo/húmeda/húmedos.
  static const List<String> moistureSignals = <String>[
    ' húmed',
    ' mojado ',
    ' lluvia ',
  ];

  // ─── Función del escenario (inferScenarioFunction) ──────────────

  static const List<String> scenarioFunctionCrimeSignals = <String>[
    ' sangre ',
    ' policía ',
    ' cinta ',
    ' cadáver ',
    ' cuerpo sin vida ',
    ' móvil caído ',
    ' contenedor abierto ',
  ];

  static const List<String> scenarioFunctionIntimacySignals = <String>[
    ' apartamento ',
    ' estudio ',
    ' cama ',
    ' cafetera ',
    ' patio interior ',
    ' refugio ',
  ];

  static const List<String> scenarioFunctionWorkSignals = <String>[
    ' redacción ',
    ' oficina ',
    ' escritorio ',
    ' gestor de contenidos ',
    ' periodistas ',
  ];

  static const List<String> scenarioFunctionTransitSignals = <String>[
    ' camino por ',
    ' cruzo ',
    ' avenida ',
    ' calle ',
    ' carretera ',
    ' paso frente ',
  ];

  static const List<String> scenarioFunctionWaitingSignals = <String>[
    ' sala de espera ',
    ' pasillo ',
    ' urgencias ',
    ' espera ',
  ];

  static const List<String> scenarioFunctionObservationSignals = <String>[
    ' observar ',
    ' miré ',
    ' vi ',
    ' focos ',
    ' desde la ventana ',
  ];

  // ─── Atmósfera y objetos para scoring ──────────────────────────

  static const List<String> scenarioAtmosphereTerms = <String>[
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
  ];

  static const List<String> scenarioObjectTerms = <String>[
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
  ];

  // ─── Objetos clave (para _buildKeyObjectSummary) ───────────────

  static const List<String> phoneTerms = <String>[' móvil ', ' teléfono '];
  static const List<String> laptopTerms = <String>[' portátil ', ' ordenador '];
  static const List<String> cameraTerms = <String>[
    ' cámara ',
    ' foto ',
    ' fotos ',
  ];
  static const List<String> videoTerms = <String>[' vídeo ', ' video '];
  static const List<String> folderTerms = <String>[
    ' carpeta ',
    ' expediente ',
  ];
  static const List<String> keyTerms = <String>[' llave ', ' llaves '];
  static const List<String> dangerousObjectTerms = <String>[
    ' arma ',
    ' pistola ',
    ' cuchillo ',
  ];
  static const List<String> physicalTraceTerms = <String>[
    ' sangre ',
    ' huellas ',
    ' ceniza ',
  ];
  static const List<String> containerTerms = <String>[
    ' contenedor ',
    ' caja ',
    ' palé ',
  ];
  static const List<String> coffeeTerms = <String>[' taza ', ' café ', ' chai '];
  static const List<String> workFurnitureTerms = <String>[
    ' escritorio ',
    ' silla ',
  ];

  // ─── Momentos narrativos (para _detectMoment) ──────────────────

  static const List<String> workshopMomentTerms = <String>[
    ' taller ',
    ' herramientas ',
    ' grasa ',
    ' banco de trabajo ',
  ];

  static const List<String> newsroomMomentTerms = <String>[
    ' redacción ',
    ' escritorio ',
    ' gestor de contenidos ',
    ' periodistas ',
    ' despacho ',
    ' fotocopiadora ',
    ' artículo ',
    ' correcciones ',
    ' llamadas ',
  ];

  static const List<String> intimateMorningMomentTerms = <String>[
    ' mi apartamento ',
    ' mi estudio ',
    ' apartamento ',
    ' estudio ',
    ' cafetera ',
    ' bernal heights ',
    ' vecino ',
    ' saxofón ',
    ' patio interior ',
    ' cama ',
  ];

  static const List<String> backgroundTensionMomentTerms = <String>[
    ' mi madre ',
    ' mensaje ',
    ' ansiedad ',
    ' desayuno ',
    ' no te olvides de comer ',
    ' no te metas en líos ',
    ' admiro ',
    ' no quiero cambiar el sistema ',
    ' quiero entender ',
  ];

  static const List<String> soloProcessingMomentTerms = <String>[
    ' habitación ',
    ' portátil ',
    ' libreta ',
    ' silencio ',
    ' símbolo ',
  ];

  static const List<String> nightWalkHomeMomentTerms = <String>[
    ' camino por ',
    ' cruzo ',
    ' paso frente ',
    ' luces de neón ',
    ' tienda de conveniencia ',
    ' llego a casa ',
    ' subo las escaleras ',
  ];

  static const List<String> cafePauseMomentTerms = <String>[
    ' cafetería ',
    ' mesa del fondo ',
    ' café negro ',
    ' chai ',
    ' sándwich ',
    ' almuerzo ',
  ];

  /// Señales de inicio de investigación. Quitadas ` nombre ` y ` conect`
  /// porque eran demasiado genéricas (matcheaban cualquier prosa con un
  /// nombre o el verbo conectar) y disparaban "Recogida de indicios" en
  /// libros que no son de investigación (libros 2 y 3).
  static const List<String> investigationStartMomentTerms = <String>[
    ' investigar ',
    ' pista ',
    ' indicio ',
    ' buscar ',
    ' anoté ',
  ];

  static const List<String> crimeSceneEntryMomentTerms = <String>[
    ' sangre ',
    ' policía ',
    ' cinta ',
    ' crimen ',
    ' cadáver ',
    ' el cuerpo ',
    ' cuerpo sin vida ',
    ' retirado ',
  ];

  static const List<String> containedTensionMomentTerms = <String>[
    ' grito ',
    ' sombra ',
    ' miedo ',
    ' ruido ',
    ' pasos ',
  ];

  // ─── Clasificación de documentos (narrative_document_classifier) ──

  static const List<String> documentTechnicalTokens = <String>[
    'entrevista full stack',
    'manual completo',
    'objetivo transmitir',
    'frontend',
    'backend',
    ' api ',
    'pull request',
    'currículum',
  ];

  static const List<String> documentResearchTokens = <String>[
    'resumen ejecutivo',
    'documento de investigación',
    'objetivo de este documento',
    'cómo hacer que',
    'cómo construir',
    'qué es la',
    'características:',
    'se basa',
    'este documento analiza',
    'este documento explica',
    'osint',
    'apofenia',
  ];

  static const List<String> documentWorldbuildingMagicTokens = <String>[
    'reino',
    'magia',
    'culto',
    'ritual',
    'símbolos',
    'mitología',
    'reglas del mundo',
  ];

  static const List<String> documentWorldbuildingBuildTokens = <String>[
    'diseñar',
    'construir',
    'uso narrativo',
    'worldbuilding',
    'origen cultural',
  ];

  /// Señales de primera persona en muestreo de documentos (variante de
  /// `firstPersonCues` con conjunto reducido para clasificación).
  static const List<String> documentSceneFirstPersonTokens = <String>[
    ' me ',
    ' mi ',
    ' mis ',
    ' conmigo ',
    ' desperté',
    ' miré',
    ' caminé',
    ' pensé',
    ' sentí',
  ];

  static const List<String> documentSceneActionTokens = <String>[
    'dije',
    'respondió',
    'preguntó',
    'me detuve',
    'entré',
    'salí',
    'levanté',
    'encendí',
    'seguía',
    'estaba',
  ];

  static const List<String> documentScenePlaceTokens = <String>[
    'san francisco',
    'apartamento',
    'callejón',
    'redacción',
    'cafetería',
    'mission',
    'tenderloin',
  ];

  // ─── next_best_move_service ────────────────────────────────────

  static const Set<String> nextMoveStopWords = <String>{
    'una',
    'uno',
    'unos',
    'unas',
    'que',
    'por',
    'para',
    'con',
    'sin',
    'sobre',
    'entre',
    'esta',
    'este',
    'esto',
    'como',
    'cuando',
    'donde',
    'porque',
    'pero',
    'tambien',
    'también',
    'cada',
    'todo',
    'toda',
    'todas',
    'todos',
    'puede',
    'pueden',
    'debe',
    'deben',
    'hay',
    'ser',
    'está',
    'están',
    'estan',
    'hace',
    'hacer',
    'más',
    'mas',
    'muy',
    'del',
    'los',
    'las',
    'al',
    'el',
    'la',
    'lo',
    'y',
    'o',
  };

  static const List<String> nextMoveStructuralMarkers = <String>[
    'regla',
    'límite',
    'limite',
    'coste',
    'costo',
    'obliga',
    'obligado',
    'obligación',
    'obligacion',
    'prohíbe',
    'prohibe',
    'prohibido',
    'restricción',
    'restriccion',
    'impide',
    'requiere',
    'solo puede',
    'no puede',
    'depende de',
    'a cambio de',
    'bajo condición',
    'bajo condicion',
  ];

  static const List<String> nextMoveOperationalVerbs = <String>[
    'obliga',
    'requiere',
    'impide',
    'limita',
    'prohíbe',
    'prohibe',
    'prohibido',
    'cuesta',
    'coste',
    'costo',
    'depende de',
    'solo puede',
    'no puede',
    'a cambio de',
  ];

  static const List<String> nextMoveGenericSignals = <String>[
    'depende de quien',
    'ya veremos',
    'puede ser',
    'tal vez',
    'quizá',
    'quizas',
    'quien lo mire',
  ];

  static const List<String> nextMoveActionVerbs = <String>[
    'corrió',
    'golpeó',
    'abrió',
    'saltó',
    'empujó',
    'sacó',
    'lanzó',
    'miró',
    'caminó',
    'entró',
    'salió',
    'levantó',
    'subió',
    'bajó',
  ];

  static const List<String> nextMoveDialogConversationCues = <String>[
    'dijo',
    'preguntó',
    'respondió',
    'murmuró',
    'contestó',
    'dime',
    'mira',
  ];

  // ─── narrative_memory_updater: keywords por categoría ──────────

  static const List<String> memoryClueKeywords = <String>[
    'pista',
    'indicio',
    'rastro',
    'señal',
    'huella',
    'clave',
  ];

  static const List<String> memoryThreatKeywords = <String>[
    'amenaza',
    'peligro',
    'miedo',
    'riesgo',
    'persecución',
    'muerte',
  ];

  static const List<String> memoryFactKeywords = <String>[
    'descubre',
    'revela',
    'sabe que',
    'comprende',
    'recuerda',
  ];

  static const List<String> memoryCharacterShiftKeywords = <String>[
    'decide',
    'duda',
    'cambia',
    'renuncia',
    'confiesa',
    'teme',
  ];

  // ─── story_state_updater: tokens de estado ─────────────────────

  /// Tokens que suben tensión global cuando aparecen en la escena.
  static const List<String> tensionTokens = <String>[
    // Amenazas clásicas
    'amenaza', 'peligro', 'muerte', 'huye', 'arma', 'sangre', 'secreto',
    // Vocabulario de fase de investigación (thriller, misterio)
    'asesinat', 'mataron', 'desaparec', 'advertencia', 'crimen',
  ];

  /// Verbos/sustantivos que sugieren amenaza activa en el progreso real.
  static const List<String> progressThreatTokens = <String>[
    'amenaza',
    'peligro',
    'riesgo',
    'persecución',
    'muerte',
  ];

  /// Verbos que sugieren información nueva en el progreso real.
  static const List<String> progressFactTokens = <String>[
    'descubre',
    'revela',
    'sabe que',
    'comprende',
  ];

  /// Tokens base para detectar progreso real cuando el género no impone
  /// reglas adicionales.
  static const List<String> progressDefaultTokens = <String>[
    'descubre',
    'decide',
    'revela',
    'amenaza',
    'confiesa',
    'pierde',
  ];

  /// Léxico de "sistema" (sci-fi: explicaciones que tocan reglas técnicas).
  static const List<String> systemTokens = <String>[
    'sistema',
    'tecnología',
    'algoritmo',
    'motor',
    'órbita',
    'colonia',
    'protocolo',
  ];

  /// Verbos que indican un cambio estructural (decisiones, costes,
  /// consecuencias). Usados con stemming → captan también pretérito/imperfecto.
  static const List<String> structuralShiftTokens = <String>[
    'obliga',
    'exige',
    'decide',
    'elige',
    'pierde',
    'cruza',
    'renuncia',
    'empuja',
    'marca',
    'implica',
    'cambia',
    'regla',
    'coste',
    'consecuencia',
    'prohíbe',
    'limita',
    'altera',
    'reduce',
    'aumenta',
    'impide',
  ];

  /// Texturas de mundo de fantasía (bosques, magia, oráculos…).
  static const List<String> fantasyWorldTextureTokens = <String>[
    'bosque',
    'reino',
    'magia',
    'templo',
    'dragón',
    'hechizo',
    'oráculo',
  ];

  /// Presión narrativa típica de fantasía (deuda, destino, maldición…).
  static const List<String> fantasyPressureTokens = <String>[
    'deuda',
    'destino',
    'maldición',
    'juramento',
    'amenaza',
    'sombra',
    'guerra',
    'exilio',
  ];

  // ─── Sinónimos curados ─────────────────────────────────────────

  /// Mapa de sinónimos para análisis tolerante a variación léxica.
  ///
  /// Convención conservadora: sólo equivalencias claras dentro del mismo
  /// dominio narrativo. Añadir entradas requiere verificar con tests:
  /// expandir demasiado introduce falsos positivos en escenas que sólo
  /// tocan el concepto por encima.
  ///
  /// Las búsquedas con sinónimos pasan a través del stemmer, así que un
  /// sinónimo cubre también sus formas conjugadas (ej. 'opta' → 'optó',
  /// 'optaba', 'optaron').
  static const Map<String, List<String>> synonymMap =
      <String, List<String>>{
    // Miedo / amenaza
    'miedo': <String>['temor', 'pavor', 'angustia'],
    'amenaza': <String>['peligro', 'advertencia'],
    // Decisión / duda
    'decide': <String>['elige', 'opta', 'resuelve'],
    'duda': <String>['vacila', 'titubea'],
    // Descubrimiento / revelación
    'descubre': <String>['halla', 'encuentra'],
    'revela': <String>['muestra', 'expone', 'desvela'],
    // Confesión
    'confiesa': <String>['admite', 'reconoce'],
  };
}

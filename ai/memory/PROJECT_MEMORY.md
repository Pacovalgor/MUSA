# PROJECT MEMORY

## Decisiones estables
- MUSA es un estudio de escritura asistida por IA **local-first** con foco en escritorio macOS y arquitectura Flutter + Riverpod.
- El repositorio público debe preservar esa tesis local-first: excluir secretos, credenciales, proyectos `.musa`, modelos `.gguf` y bases de datos locales mediante `.gitignore`.
- El flujo crítico del producto sigue la cadena: `main` → providers de workspace/libro → `editor_controller` → servicios IA/análisis → persistencia local.
- La persistencia del workspace y del documento `.musa` es un contrato central: cualquier cambio debe preservar compatibilidad de serialización y restauración.
- El dominio está segmentado en módulos (`books`, `manuscript`, `characters`, `scenarios`, `notes`, `continuity`, `musa`) con modelos inmutables y providers específicos por slice.
- **V1.3 (2026-04-20)**: Implementado gating estructural en `ChapterAnalysisService` y `NextBestMoveService`. Se ha añadido refinamiento por contexto local en `NextBestMoveService` y en Musas individuales (`ClarityMusa`, `StyleMusa`, `RhythmMusa`, `TensionMusa`) para ofrecer instrucciones quirúrgicas basadas en el fragmento seleccionado. Se ha introducido la detección de **diálogo estancado** en `TensionMusa` y un sistema de **explicabilidad basada en señales** en `MusaAutopilot` para dotar de trazabilidad a las recomendaciones editoriales.
- **V1.4 (2026-04-24)**: 
  - ✅ Agregada música lofi embebida (30 pistas Open-Lofi, ~88 MB) con widget de selección por categoría y persistencia de preferencias
  - ✅ **Confidence scoring** en `NarrativeDocumentClassifier`: clasificaciones retornan probabilidad (0.0-1.0) permitiendo descartar sugerencias en textos ambiguos
  - ✅ **Ponderación de verbos** en `EditorialSignals`: verbos de acción divididos en 3 categorías (físicos, operacionales, dicendi) con blending contextual, evita penalizar escenas de diálogo puro
  - ✅ **Feedback loops** en pipelines: `_shouldSkipMusaByFeedback()` analiza salida de Musa N antes de ejecutar N+1, evita procesamiento redundante (ej: ClarityMusa + RhythmMusa no corren ambas si Clarity ya solucionó ritmo)
  - 🔄 **Pipeline transparency** (parcial): `musaExecutionHistory` rastrea musas ejecutadas/saltadas; falta exposición UI mejorada
  - ⏳ **Adaptive thresholds**: pendiente para future iteration
- **V1.5 (2026-05-06)**:
  - ✅ **Aprendizaje adaptativo conectado**: `MusaEffectivenessTracker` aplica multiplicadores conservadores tras un mínimo de 5 muestras por Musa.
  - ✅ **Atribución precisa de feedback**: las sugerencias editoriales conservan `sourceMusaId`; aceptación/rechazo se registra sobre la Musa que produjo la propuesta final, no sobre toda la pipeline.
  - ✅ **Estado visible de aprendizaje**: `MusaSettingsDialog` muestra estado por Musa (`Aprendiendo`, `Estable`, `Afinada`, `En pausa`) con muestras, aceptación y descartes.
  - ✅ **Gating narrativo endurecido**: mejor separación entre escena, research, worldbuilding y técnico, con cobertura para `El ojo invisible`.
  - ✅ **Smoke FFI real validado**: `llama_processor_real_smoke_test.dart` puede ejecutarse con el modelo instalado en el contenedor macOS de MUSA.
- **V1.6 (2026-05-06)**:
  - ✅ **Calibración profesional separada**: `ProfessionalCorpusCalibration` usa perfiles derivados de los reportes de `Mithas y Karthay` (fantasy), `Tras la puerta` (thriller) y `Un lugar llamado libertad` (historical).
  - ✅ **No mezcla corpus con feedback personal**: la calibración profesional ajusta multiplicadores base por género; `MusaEffectivenessTracker` sigue representando únicamente aceptaciones/rechazos del usuario.
  - ✅ **Composición conservadora**: los multiplicadores profesionales y personales se combinan con límites para evitar sesgos bruscos en `MusaAutopilot`.
- **V1.7 (2026-05-06)**:
  - ✅ **Corpus profesional ampliado**: `ProfessionalCorpusCalibration` pasa a 15 referencias locales derivadas, con 5 libros por perfil (`fantasy`, `thriller`, `historical`).
  - ✅ **Métricas derivadas, no texto fuente**: se registran señales agregadas por género (`avgSentenceLength`, diálogo, preguntas, términos dramáticos y diversidad léxica) sin guardar prose, fragmentos de libros ni EPUBs en el repositorio.
  - ✅ **Tests golden de calibración**: `professional_corpus_calibration_test.dart` valida referencias, métricas y ausencia de `sampleText` para preservar privacidad/copyright.
- **V1.8 (2026-05-06)**:
  - ✅ **Memoria narrativa ampliada**: `NarrativeMemory` persiste promesas de lectura, promesas abiertas, señales de tono y avisos de patrón repetido por libro, con compatibilidad para proyectos `.musa` antiguos.
  - ✅ **Estado de la novela derivado**: `NovelStatusService` calcula salud narrativa, tensión, ritmo, promesa, memoria viva y comparación profesional sin llamar al modelo local ni persistir reportes derivados.
  - ✅ **Vista en Libro activo**: `book_editor.dart` muestra semáforo, métricas, señales críticas, acciones siguientes y comparación con corpus profesional en la sección “Estado de la novela”.
- **V1.9 (2026-05-06)**:
  - ✅ **Auditor de continuidad derivado**: `ContinuityAuditService` detecta promesas abiertas, contradicciones prohibidas, personajes sin ficha, escenarios sin ficha y patrones repetidos sin llamar al modelo local.
  - ✅ **Panel de riesgos en Libro activo**: `book_editor.dart` muestra “Riesgos de continuidad” debajo del estado de la novela, con gravedad, evidencia y acción sugerida.
  - ✅ **Cobertura de auditoría**: tests unitarios del auditor y prueba integrada con `El ojo invisible` garantizan hallazgos útiles sobre el libro completo.
- **V2.0 fase 1 (2026-05-06)**:
  - ✅ **Reescritura guiada controlada**: `GuidedRewriteService` genera propuestas deterministas para subir tensión, aclarar, reducir exposición y naturalizar diálogo sin llamar al modelo local.
  - ✅ **Contrato de seguridad editorial**: cada propuesta preserva hechos y voz, evita personajes nuevos y no resuelve trama ni promesas abiertas.
  - ✅ **Flujo integrado en editor**: el menú de selección crea una propuesta revisable que reutiliza comparación/aplicar/descartar mediante `MusaSuggestion`.
  - ✅ **Cobertura base**: `guided_rewrite_service_test.dart` valida que las acciones no inventan hechos, no contaminan diálogo y manejan selección vacía.
- **V2.0 fase 2 (2026-05-06)**:
  - ✅ **Planificador contextual de reescritura**: `GuidedRewritePlanner` recomienda una acción guiada según fragmento, estado de novela, memoria narrativa, continuidad y género.
  - ✅ **Prioridad conservadora**: exposición acumulada, diálogo sin respiración, promesas abiertas y baja tensión compiten por prioridad; si no hay señal clara no fuerza recomendación.
  - ✅ **Recomendación visible en editor**: el menú contextual destaca “Recomendado” con razón breve, pero mantiene el flujo revisable de comparar antes de aplicar.
- **V2.0 fase 3 (2026-05-06)**:
  - ✅ **Auditoría de seguridad para reescrituras**: `GuidedRewriteSafetyService` detecta nombres nuevos, expansión excesiva y pérdida de términos clave entre original y propuesta.
  - ✅ **Resultado enriquecido**: `GuidedRewriteResult` incorpora `safetyAudit`, y `GuidedRewriteService` lo calcula en cada propuesta mediante inyección testeable.
  - ✅ **Revisión visible**: si la auditoría marca advertencias, el editor las añade a la nota editorial y la vista de comparación muestra esa nota junto al diff.
- **V2.0 fase 4 (2026-05-06)**:
  - ✅ **Atribución por acción guiada**: cada `GuidedRewriteAction` expone un `feedbackSlug` estable (`guided-rewrite.raise-tension`, `guided-rewrite.clarify`, etc.).
  - ✅ **Aprendizaje accionable**: el editor registra las propuestas guiadas como mostradas y atribuye aceptación/rechazo a la acción concreta, no al bucket genérico `guided-rewrite`.
  - ✅ **Base para personalización**: el tracker existente puede acumular preferencias de Paco por tipo de reescritura sin mezclarlo con las Musas clásicas.
- **V2.0 cierre (2026-05-06)**:
  - ✅ **Aprendizaje visible de reescritura**: `MusaSettingsDialog` muestra tarjetas de aceptación/rechazo para tensión, claridad, exposición y diálogo.
  - ✅ **Recomendaciones personalizadas**: `GuidedRewritePlanner` acepta multiplicadores aprendidos y el menú contextual prioriza acciones guiadas según preferencias locales.
  - ✅ **Sin persistencia nueva**: se reutiliza `MusaEffectivenessTracker`, manteniendo las preferencias locales y separadas por slug estable.
- **V2.1 (2026-05-06)**:
  - ✅ **Capa preparada para modelo local**: `GuidedRewriteGenerationService` acepta un `GuidedRewriteModelClient` inyectable y cae a `GuidedRewriteService` si no está listo.
  - ✅ **Prompts con contrato estricto**: `GuidedRewritePromptBuilder` genera instrucciones por acción y exige devolver solo texto reescrito, sin explicación ni invención.
  - ✅ **Auditoría antes de mostrar**: la salida del modelo se limpia y pasa por `GuidedRewriteSafetyService`; si falla, se usa fallback determinista.
- **V2.2 (2026-05-06)**:
  - ✅ **Auditor editorial derivado**: `EditorialAuditService` construye un ledger de promesas leídas, pagadas, abiertas y olvidadas sin persistir reportes.
  - ✅ **Continuidad elevada a auditoría editorial**: contradicciones críticas del auditor de continuidad se reflejan como hallazgos editoriales críticos.
  - ✅ **Provider listo para UI**: `activeEditorialAuditProvider` entrega el reporte del libro activo combinando memoria narrativa, documentos y continuidad.
- **V2.3 (2026-05-06)**:
  - ✅ **Mapa editorial por capítulos**: `ChapterEditorialMapService` calcula prioridad local de tensión, ritmo, promesa o consecuencia por capítulo narrativo.
  - ✅ **Comparación profesional por tramo**: cada capítulo muestra si su ritmo está alineado, más lento o más cortado que el corpus profesional del género.
  - ✅ **Vista en Libro activo**: `book_editor.dart` añade el mapa editorial derivado junto al estado de novela, sin persistir reportes.
- **V3.0 (2026-05-06)**:
  - ✅ **Dirección editorial unificada**: `EditorialDirectorService` fusiona estado de novela, auditoría editorial, mapa por capítulos, memoria y estado narrativo en misiones priorizadas.
  - ✅ **Orden de intervención estable**: contradicciones críticas ganan a ritmo/capítulo; promesas olvidadas se elevan antes de recomendaciones locales.
  - ✅ **Vista ejecutiva en Libro activo**: `book_editor.dart` muestra preparación, intervención, revisión o avance con máximo 3 misiones accionables.
- **V3.1 (2026-05-07)**:
  - ✅ **Mesa creativa por libro**: `CreativeCard` persiste ideas, bocetos, preguntas, research, imagenes y enlaces como tarjetas organizables por estado dentro del workspace.
  - ✅ **Tablero operativo**: `CreativeBoardEditor` expone Inbox, Explorando, Prometedoras, Listas y Convertidas, con creacion rapida, movimiento controlado y conversion a nota, personaje, escenario o documento.
  - ✅ **Entrada desde inbox**: capturas aceptadas pueden entrar como tarjetas creativas con origen y adjuntos, sin sustituir el flujo existente de notas.
- **V3.2 Mesa creativa (2026-05-08)**:
  - ✅ **Tarjeta creativa enriquecida**: cada `CreativeCard` puede abrirse en un panel de detalle para editar título, cuerpo, tipo, estado y tags.
  - ✅ **Adjuntos y vínculos explícitos**: las tarjetas gestionan enlaces, referencias de imagen y relaciones con personajes, escenarios, documentos y notas del libro activo.
  - ✅ **Antesala no canónica reforzada**: las tarjetas siguen fuera de memoria narrativa, continuidad y auditoría hasta conversión o acción explícita.

## Restricciones operativas recurrentes
- Priorizar cambio mínimo correcto y scope estricto.
- Evitar refactors oportunistas en `editor`, `providers` y `storage`.
- No declarar verificaciones no ejecutadas.
- Mantener coherencia con servicios IA locales y fallbacks explícitos para plataformas no soportadas.
- **Auditabilidad**: Se han añadido fixtures literarios y de apoyo en `test/fixtures/` junto con un test de auditoría (`test/narrative_gating_audit_test.dart`) para garantizar la robustez del gating estructural. Las pruebas reproducibles actuales muestran que el gating estructural distingue bien entre el fixture narrativo auditado, el fixture de apoyo auditado y un caso ambiguo conservador, aunque la cobertura sigue siendo limitada.
- El aprendizaje de Musas debe mantenerse local-first y conservador: no ajustar selección hasta tener muestra mínima, y registrar feedback sobre la Musa fuente de la sugerencia final.
- La calibración de libros profesionales debe permanecer como criterio editorial general, separada del aprendizaje personal de Paco, y solo debe guardar señales derivadas agregadas.
- Los reportes globales de salud narrativa deben ser derivados y recalculables; solo la memoria narrativa estable debe persistirse en el `.musa`.
- Los hallazgos de continuidad V1.9 deben permanecer derivados/recalculables; no se persisten hasta que exista un flujo explícito de revisión/aceptación por Paco.
- La reescritura guiada V2.0 fase 1 debe permanecer controlada y revisable: no aplica cambios directamente, no llama al modelo local y entra siempre por comparación antes de tocar el manuscrito.
- Las recomendaciones de reescritura V2.0 fase 2 son derivadas y no persistidas; deben ayudar a elegir herramienta, no sustituir criterio editorial ni aplicar cambios automáticos.
- La auditoría de seguridad V2.0 fase 3 es informativa, no bloqueante; debe alertar antes de aplicar, pero la decisión final sigue siendo del usuario.
- Los slugs de aprendizaje de reescritura guiada V2.0 fase 4 son contrato estable de preferencias; no renombrarlos sin migración de estadísticas locales.
- El cierre V2.0 usa el aprendizaje solo para ordenar recomendaciones cuando hay señales competidoras; no debe ocultar acciones manuales ni aplicar cambios automáticamente.
- V2.1 deja lista la integración con modelo local pero no fuerza su uso en UI; cualquier activación debe mantener fallback determinista y auditoría previa.
- V2.2 mantiene el auditor editorial como derivado/recalculable; no guardar reportes hasta que exista flujo explícito de revisión o exportación.
- V2.3 mantiene el mapa editorial por capítulos como derivado/recalculable; no guardar recomendaciones por capítulo hasta que exista flujo explícito de revisión editorial.
- V3.0 mantiene la dirección editorial como derivada/recalculable; no aplicar misiones automáticamente ni persistirlas como tareas hasta que exista revisión explícita del usuario.
- V3.1 mantiene las tarjetas creativas fuera de memoria narrativa, continuidad, auditoria y direccion editorial hasta conversion o accion explicita de uso.
- V3.2 Mesa creativa mantiene adjuntos de imagen como referencias URI/ruta; no copiar archivos al `.musa` hasta que exista gestor de media explícito.

## Guía de entrada rápida para futuras tareas
1. Confirmar impacto en capa (`ui`, `editor`, `dominio`, `ia`, `storage`).
2. Localizar contrato afectado (modelo/proveedor/servicio/controlador).
3. Aplicar parche mínimo.
4. Ejecutar verificación real (tests/checks relevantes).
5. Guardar solo aprendizaje estable.

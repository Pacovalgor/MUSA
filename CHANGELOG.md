# Changelog

Todos los cambios relevantes de MUSA se documentan en este archivo.

El formato sigue una variante ligera de Keep a Changelog: las entradas nuevas empiezan en `Unreleased` y se consolidan bajo una fecha o versión cuando se prepara una entrega. No hace falta registrar cambios puramente internos que no afecten a producto, arquitectura, documentación o flujo de desarrollo.

## Unreleased

### Added

- Workflow de CI en GitHub Actions (`.github/workflows/ci.yml`): `flutter analyze --fatal-infos` + `flutter test --exclude-tags=real_ffi` sobre `macos-latest` en cada push y PR a `main`.
- `test/flutter_test_config.dart`: deshabilita `GoogleFonts.allowRuntimeFetching` globalmente para que los widget tests que usan `MusaTheme` funcionen en CI sin conexión.
- Tag `@Tags(['real_ffi'])` en `llama_processor_real_smoke_test.dart` para excluirlo limpiamente del CI headless.

## 2026-05-12 - V3.4: Captura iPhone orientada a mesa creativa

### Added

- `InboxCapture` transporta intención editorial opcional (`creativeTypeHint`) y referencias de adjunto sin romper JSON antiguo.
- Popover y detalle de bandeja Mac crean `CreativeCard` del libro activo usando el tipo sugerido o corregido antes de confirmar.
- Capturas sin libro activo permanecen pendientes y no se marcan como procesadas.
- Tests de modelo, storage, provider y widgets para el flujo de captura iPhone a tarjeta creativa.

## 2026-05-08 - V3.2/V3.3: Mesa creativa enriquecida y validación local de personajes

### Added

- Panel de detalle de tarjeta creativa con edición de título, cuerpo, tipo, estado y tags.
- Adjuntos y vínculos explícitos en tarjetas: enlaces, referencias de imagen y relaciones con personajes, escenarios, documentos y notas del libro activo.
- Las tarjetas refuerzan su rol de antesala no canónica: permanecen fuera de memoria narrativa, continuidad y auditoría hasta conversión o acción explícita.
- Validación local opcional de personajes en `ChapterAnalysisService.analyzeAsync`: el modelo local filtra candidatos detectados por heurística sin inventar nombres nuevos.
- Fallback conservador cuando el modelo local no está disponible o no devuelve JSON válido; el análisis no se bloquea.
- Bloqueo léxico de verbos capitalizados para reducir falsos positivos conocidos en detección de personajes.

## 2026-05-07 - V3.1: Mesa creativa por libro

### Added

- `CreativeCard` persiste ideas, bocetos, preguntas, research, imágenes y enlaces como tarjetas organizables por estado dentro del workspace.
- `CreativeBoardEditor` con columnas Inbox, Explorando, Prometedoras, Listas y Convertidas; creación rápida, movimiento controlado y conversión a nota, personaje, escenario o documento.
- Entrada desde bandeja: capturas aceptadas pueden entrar como tarjetas creativas con origen y adjuntos, sin sustituir el flujo existente de notas.

## 2026-05-06 - V1.5–V3.0: Motor editorial, aprendizaje adaptativo y dirección unificada

### Added

- **Aprendizaje adaptativo de Musas**: `MusaEffectivenessTracker` aplica multiplicadores conservadores tras un mínimo de 5 muestras por Musa.
- **Atribución precisa de feedback**: las sugerencias conservan `sourceMusaId`; aceptación/rechazo se registra sobre la Musa que produjo la propuesta final, no sobre toda la pipeline.
- **Estado visible de aprendizaje**: `MusaSettingsDialog` muestra estado por Musa (Aprendiendo, Estable, Afinada, En pausa) con muestras, aceptación y descartes.
- **Calibración profesional separada**: `ProfessionalCorpusCalibration` con 15 referencias derivadas en fantasy, thriller e historical; métricas agregadas sin guardar texto fuente ni EPUBs en el repositorio.
- **Composición conservadora**: multiplicadores profesionales y personales se combinan con límites en `MusaAutopilot` para evitar sesgos bruscos.
- **Memoria narrativa ampliada**: `NarrativeMemory` persiste promesas de lectura, promesas abiertas, señales de tono y avisos de patrón repetido por libro, con compatibilidad para proyectos `.musa` anteriores.
- **Estado de la novela derivado**: `NovelStatusService` calcula salud narrativa, tensión, ritmo, promesa, memoria viva y comparación con corpus profesional sin llamar al modelo local ni persistir reportes.
- **Vista de estado de novela en libro activo**: semáforo, métricas, señales críticas, acciones siguientes y comparación profesional.
- **Auditor de continuidad derivado**: `ContinuityAuditService` detecta promesas abiertas, contradicciones prohibidas, personajes y escenarios sin ficha y patrones repetidos.
- **Panel de riesgos en libro activo**: muestra gravedad, evidencia y acción sugerida de cada hallazgo de continuidad.
- **Reescritura guiada controlada** (V2.0): `GuidedRewriteService` genera propuestas deterministas para subir tensión, aclarar, reducir exposición y naturalizar diálogo; no aplica cambios directamente y entra siempre por comparación.
- **Planificador contextual de reescritura** (V2.0): `GuidedRewritePlanner` recomienda una acción guiada según fragmento, estado de novela, memoria narrativa, continuidad y género; la recomendación aparece destacada en el menú de selección con razón breve.
- **Auditoría de seguridad para reescrituras** (V2.0): `GuidedRewriteSafetyService` detecta nombres nuevos, expansión excesiva y pérdida de términos clave entre original y propuesta; las advertencias aparecen en la vista de comparación, no bloquean el flujo.
- **Aprendizaje de reescritura guiada** (V2.0): slugs estables por acción (`guided-rewrite.raise-tension`, `guided-rewrite.clarify`, etc.) con estado de aceptación/rechazo visible en ajustes.
- **Capa para modelo local en reescritura** (V2.1): `GuidedRewriteGenerationService` acepta `GuidedRewriteModelClient` inyectable; si no está listo cae a `GuidedRewriteService` determinista; auditoría de seguridad previa a mostrar el resultado.
- **Auditor editorial derivado** (V2.2): `EditorialAuditService` construye ledger de promesas leídas, pagadas, abiertas y olvidadas; contradicciones críticas del auditor de continuidad se elevan como hallazgos editoriales críticos.
- **Mapa editorial por capítulos** (V2.3): `ChapterEditorialMapService` calcula prioridad local de tensión, ritmo, promesa o consecuencia y compara el ritmo de cada capítulo contra el corpus profesional del género.
- **Dirección editorial unificada** (V3.0): `EditorialDirectorService` fusiona estado de novela, auditoría editorial, mapa de capítulos, memoria narrativa y estado narrativo en máximo 3 misiones priorizadas mostradas en la vista de libro activo.
- Smoke FFI real validado con modelo instalado en macOS (`llama_processor_real_smoke_test.dart`).
- Tests golden de calibración (`professional_corpus_calibration_test.dart`) que validan ausencia de texto fuente para preservar privacidad y copyright.

## 2026-04-24 - V1.4: Música lofi, señales editoriales y pipeline de Musas

### Added

- Música lofi embebida: 30 pistas Open-Lofi (~88 MB) con widget de selección por categoría y persistencia de preferencias.
- Confidence scoring en `NarrativeDocumentClassifier`: las clasificaciones retornan probabilidad (0.0–1.0) para descartar sugerencias en textos ambiguos.
- Ponderación de verbos en `EditorialSignals`: tres categorías (físicos, operacionales, dicendi) con blending contextual, sin penalizar escenas de diálogo puro.
- Feedback loops en pipeline de Musas: `_shouldSkipMusaByFeedback()` analiza la salida de la Musa N antes de ejecutar N+1 para evitar procesamiento redundante.

### Changed

- `musaExecutionHistory` rastrea musas ejecutadas y saltadas en cada ejecución de pipeline.

## 2026-04-20 - V1.3: Gating estructural y refinamiento contextual

### Added

- Gating estructural en `ChapterAnalysisService` y `NextBestMoveService` para evitar que contexto débil se convierta en recomendación editorial.
- Refinamiento por contexto local en `NextBestMoveService` y Musas individuales (`ClarityMusa`, `StyleMusa`, `RhythmMusa`, `TensionMusa`) para instrucciones quirúrgicas sobre el fragmento seleccionado.
- Detección de diálogo estancado en `TensionMusa`.
- Explicabilidad basada en señales en `MusaAutopilot` para trazabilidad de recomendaciones editoriales.
- `PROJECT_PROFILE.yaml` anclado a estructura real del repositorio.
- `PROJECT_MEMORY.md` inicializado con decisiones estables de arquitectura y restricciones recurrentes.

## 2026-04-12 - Contexto narrativo, importación local y picker seguro

### Added

- Memoria contextual separada para reglas de mundo, restricciones de sistema, hallazgos de investigación y conceptos persistentes.
- Clasificador interno para distinguir escenas, investigación, worldbuilding, material técnico y documentos ambiguos antes de actualizar `StoryState`.
- Compuerta de calidad para evitar falsos positivos de contexto por solapamiento léxico superficial.
- Trazas breves de contexto aceptado o rechazado en `NextBestMoveRecommendation`.
- Auditoría V1.5 del copiloto narrativo y herramienta local `tool/audit_narrative_copilot.dart` para revisar salidas sobre workspace real.
- Importación local de modelos `.gguf` desde onboarding, con progreso de copia/validación y reconciliación de modelos ya presentes en disco.
- Picker nativo macOS para abrir proyectos `.musa` con acceso seguro a archivos fuera del sandbox.

### Changed

- `NextBestMove` pasa a exponer foco, motivo, acción sugerida, riesgo si se ignora y trazabilidad contextual.
- La memoria narrativa evita que documentos no narrativos contaminen tensión, acto o progreso de historia.
- La apertura de proyectos `.musa` copia el contenido a la ruta canónica local antes de cargarlo, reduciendo problemas de permisos de macOS.
- El editor conserva correctamente el listener del `FocusNode` activo.
- Se ignoran configuraciones locales generadas por asistentes y DevTools.

## 2026-04-11 - Proyectos `.musa` y copiloto narrativo

### Added

- Menú de proyecto para abrir, guardar como, crear, volver a proyecto local y reabrir proyectos recientes.
- Selector de documentos `.musa` basado en `file_selector`.
- Manifiesto de proyecto `.musa` con identidad, nombre, versión de esquema, libro activo y conteo de libros.
- Persistencia de proyecto activo y lista de recientes con `shared_preferences`.
- Pantalla de recuperación cuando el proyecto seleccionado no está disponible.
- ADN narrativo editable por libro: género, subgénero, tono, escala, ritmo objetivo, prioridad, promesa de lectura y tipo de final.
- Copiloto narrativo con memoria ligera, estado de historia y recomendación de siguiente mejor movimiento.
- Heurísticas por género para thriller, ciencia ficción y fantasía.
- Documento de auditoría editorial para validar salidas reales del copiloto.
- Tests para manifiesto `.musa`, proyectos recientes y heurísticas del copiloto narrativo.

### Changed

- El editor recalcula el copiloto narrativo al guardar texto, cerrar el controlador o completar análisis de capítulo.
- El workspace serializa `storyStates` y `narrativeMemories`.
- El README documenta proyectos `.musa`, ADN narrativo, copiloto y nuevos casos de uso.

## 2026-04-10 - Cierre de workflow editorial

Commit: `d87538e`

### Added

- Workflow estructurado para `connectToPlot`, con sheet de direcciones y notas persistentes.
- Metadatos de workflow en notas editoriales: tipo de ayuda, capítulo origen, dirección elegida y estado.
- Estados de nota editorial para marcar direcciones como `inbox`, usadas o descartadas.
- Snapshots manuales ligeros del workspace, con guardado, listado y restauración simple.
- Señales de continuidad light por capítulo para personajes y escenarios activos.
- Focus mode visual sobre el shell de escritura.
- Tests para ruido de análisis, notas estructurales y snapshots.
- Documentación interna de arquitectura adaptativa y planes de iPad/mobile.

### Changed

- `nextStep` pasa de sugerencia textual a acción editorial más estructurada.
- `expandMoment` queda alineado con el nuevo backbone de notas estructurales.
- Los enriquecimientos de personaje y escenario siguen una política más uniforme desde distintos puntos de entrada.
- El README refleja el estado actual del producto, incluyendo workflows, continuidad light y snapshots.

## 2026-04-10 - README visual y documentación de producto

Commit: `c714f75`

### Added

- README completo de producto con propuesta de valor, arquitectura, manual de uso, casos de uso y roadmap.
- Diagramas Mermaid para arquitectura de alto nivel, flujo principal y roadmap.
- Capturas y GIF de recorrido visual en `docs/media`.

### Changed

- La documentación pública pasa de README técnico básico a presentación de producto defendible.

## 2026-04-10 - Import inicial

Commit: `5676216`

### Added

- Import inicial del proyecto Flutter MUSA.
- Base de app de escritura editorial local-first con manuscrito, libros, personajes, escenarios, notas, musas e IA local.
- Persistencia local del workspace, editor, servicios de análisis, gestión de modelos e impresión.

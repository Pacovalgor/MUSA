# Changelog

Todos los cambios relevantes de MUSA se documentan en este archivo.

El formato sigue una variante ligera de Keep a Changelog: las entradas nuevas empiezan en `Unreleased` y se consolidan bajo una fecha o versión cuando se prepara una entrega. No hace falta registrar cambios puramente internos que no afecten a producto, arquitectura, documentación o flujo de desarrollo.

## Unreleased

- Pendiente de documentar en el próximo cambio relevante.

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

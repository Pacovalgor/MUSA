# Changelog

Todos los cambios relevantes de MUSA se documentan en este archivo.

El formato sigue una variante ligera de Keep a Changelog: las entradas nuevas empiezan en `Unreleased` y se consolidan bajo una fecha o versión cuando se prepara una entrega. No hace falta registrar cambios puramente internos que no afecten a producto, arquitectura, documentación o flujo de desarrollo.

## Unreleased

- Pendiente de documentar en el próximo cambio relevante.

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

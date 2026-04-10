# Codebase Overview

Esta guía complementa el `README.md` con una lectura orientada a mantenimiento. Resume cómo se reparten las responsabilidades en el código y qué piezas conviene abrir primero al depurar o extender la app.

## Flujo principal

1. `lib/main.dart` restaura el estado de onboarding y arranca `MusaApp`.
2. `lib/modules/books/providers/workspace_providers.dart` carga y persiste el `NarrativeWorkspace`.
3. `lib/modules/manuscript/providers/document_providers.dart` y módulos afines exponen slices de estado para UI.
4. `lib/editor/controller/editor_controller.dart` sincroniza texto, selección, análisis y ejecución de Musas.
5. `lib/services/ia_providers.dart` selecciona el backend de IA disponible.
6. `lib/shared/storage/local_workspace_storage.dart` serializa el workspace completo a disco.

## Capas

### App y shells

- `lib/main.dart`: punto de entrada, tema, onboarding y navegación adaptativa.
- `lib/app/`: shells y composición por dispositivo.
- `lib/ui/`: layout principal, sidebar, inspector y diálogos globales.

### Workspace narrativo

- `lib/modules/books/models/narrative_workspace.dart`: agregado principal en memoria.
- `lib/modules/books/models/`: ajustes globales, libros, snapshots y preferencias editoriales.
- `lib/shared/storage/local_workspace_storage.dart`: persistencia JSON local y seeding inicial.

### Contenido editorial

- `lib/modules/manuscript/`: documentos, revisiones y referencias de escena.
- `lib/modules/characters/`: fichas de personaje, relaciones y drafts de autocompletado.
- `lib/modules/scenarios/`: fichas de escenario y drafts de autocompletado.
- `lib/modules/notes/`: notas, memorias de voz y contenido derivado para el editor.
- `lib/modules/continuity/`: continuidad global y eventos de línea temporal.

### IA y Musas

- `lib/muses/`: perfiles editoriales y recomendaciones.
- `lib/modules/musa/`: sesiones, chunks y sugerencias persistidas.
- `lib/services/ia/`: motores de inferencia embebidos, fallback y gestión de modelos.
- `lib/services/ia_providers.dart`: resolución del servicio activo según plataforma y modelo.

### Editor

- `lib/editor/controller/editor_controller.dart`: cerebro del flujo de edición.
- `lib/editor/services/`: análisis heurístico de fragmentos y capítulos.
- `lib/editor/widgets/`: overlays, comparadores y paneles de revisión.

## Convenciones útiles

- Los modelos son inmutables y suelen exponer `copyWith`, `toJson` y `fromJson`.
- El estado de aplicación fluye por Riverpod; los módulos publican providers específicos en lugar de exponer el workspace bruto a la UI.
- La persistencia es local-first: si no existe workspace, se genera uno mínimo funcional.
- Las Musas trabajan sobre fragmentos y producen sesiones, chunks y sugerencias separadas para poder auditar el proceso.

## Archivos clave al depurar

- Error de carga o selección de workspace: `lib/modules/books/providers/workspace_providers.dart`
- Problema de persistencia: `lib/shared/storage/local_workspace_storage.dart`
- Comportamiento raro del editor: `lib/editor/controller/editor_controller.dart`
- Resultados de IA o disponibilidad de modelo: `lib/services/ia_providers.dart` y `lib/services/ia/embedded/`
- Datos inconsistentes en entidades narrativas: `lib/modules/*/models/`

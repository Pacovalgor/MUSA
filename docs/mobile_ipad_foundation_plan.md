# MUSA iPhone + iPad Foundation Plan

Fecha: 2026-04-10

## Objetivo

Preparar el proyecto Flutter actual para soportar herramientas de iPhone y iPad como parte de una misma plataforma MUSA, compartiendo núcleo editorial, dominio y persistencia, sin convertir el estudio desktop actual en una simple UI responsive.

## Resumen ejecutivo

El repo ya tiene una base reutilizable suficiente para abrir una línea móvil/tablet sin reescritura masiva:

- El `workspace` narrativo está bien centralizado en `NarrativeWorkspace` y `NarrativeWorkspaceNotifier`.
- La persistencia local-first ya vive detrás de un contrato (`NarrativeWorkspaceRepository`) y una implementación concreta (`LocalWorkspaceStorage`).
- El dominio editorial principal ya está modelado por módulos (`books`, `manuscript`, `characters`, `scenarios`, `notes`, `continuity`, `musa`, `models_runtime`).
- El editor tiene una lógica potente y compartible en `EditorController`.
- Riverpod ya articula el estado de forma razonable.

La parte más acoplada hoy no es el dominio, sino el shell:

- `lib/ui/layout/main_screen.dart` encapsula una experiencia explícitamente desktop.
- `sidebar`, `inspector`, `hover edge panels`, overlays y top bar mezclan layout, navegación y políticas de paneles.
- El arranque actual decide solo entre onboarding y pantalla desktop.
- La IA embebida y algunos servicios auxiliares siguen condicionados a `Platform.isMacOS`.

## Qué ya es reutilizable para iPhone/iPad

### Dominio y modelos

Reutilizable casi completo:

- `lib/modules/books/models/`
- `lib/modules/manuscript/models/`
- `lib/modules/characters/models/`
- `lib/modules/scenarios/models/`
- `lib/modules/notes/models/`
- `lib/modules/continuity/models/`
- `lib/modules/musa/models/`
- `lib/modules/models_runtime/models/`
- `lib/domain/ia/`
- `lib/domain/musa/`

Observación:

- `lib/project/` parece un legado anterior al workspace narrativo actual. No parece formar parte del flujo principal ya documentado en `README.md`.

### Estado y providers

Reutilizable con buen encaje:

- `lib/modules/books/providers/workspace_providers.dart`
- `lib/modules/manuscript/providers/document_providers.dart`
- `lib/modules/characters/providers/character_providers.dart`
- `lib/modules/scenarios/providers/scenario_providers.dart`
- `lib/modules/notes/providers/note_providers.dart`
- `lib/modules/continuity/providers/continuity_providers.dart`
- `lib/modules/musa/providers/musa_providers.dart`
- `lib/modules/models_runtime/providers/model_runtime_providers.dart`

Valor principal:

- La selección de libro, documento, nota, personaje y escenario ya vive en el workspace, no en widgets aislados.
- El cambio de contenido se persiste desde el `EditorController` hacia el notifier del workspace.

### Persistencia y servicios

Reutilizable:

- `lib/modules/books/services/narrative_workspace_repository.dart`
- `lib/shared/storage/local_workspace_storage.dart`
- `lib/editor/services/fragment_analysis_service.dart`
- `lib/editor/services/chapter_analysis_service.dart`
- `lib/services/context_builder.dart`
- contratos IA de `lib/domain/ia/ia_interfaces.dart`

Matiz:

- `LocalWorkspaceStorage` usa `path_provider` y `dart:io`, pero conceptualmente es reutilizable para iOS/iPadOS porque sigue siendo persistencia local del sandbox.

### Editor controller

Muy reutilizable:

- `lib/editor/controller/editor_controller.dart`
- `lib/editor/controller/musa_text_editing_controller.dart`

Valor:

- sincroniza contenido activo
- maneja selección y overlay
- dispara análisis y flujo de Musa
- crea notas ancladas
- coordina entidades narrativas desde el editor

Riesgo:

- contiene decisiones que asumen el editor principal como centro de la app; esto sirve también en iPad y parcialmente en iPhone, pero conviene que el shell decida densidad, navegación y presencia de paneles.

### IA y análisis

Reutilizable por contrato:

- interfaces de IA
- construcción de contexto
- análisis heurístico de fragmento/capítulo
- pipeline Musa/editorial

Acoplado a plataforma:

- `lib/services/ia_providers.dart`
- `lib/services/ia/embedded/`
- `lib/services/characters/embedded_character_autofill_service.dart`
- `lib/services/scenarios/embedded_scenario_autofill_service.dart`

Motivo:

- resolución por `Platform.isMacOS`
- dependencias FFI y gestión local de modelos orientadas a macOS

## Qué está demasiado acoplado a desktop/macOS

### Shell desktop actual

Fuertemente acoplado:

- `lib/ui/layout/main_screen.dart`
- `lib/ui/widgets/sidebar.dart`
- `lib/ui/widgets/inspector.dart`
- `lib/ui/providers/ui_providers.dart`

Motivos:

- navegación lateral fija de estudio
- inspector lateral como pieza estructural
- `MouseRegion` para edge hover panels
- top bar densa y orientada a sesiones largas de escritorio
- políticas de layout codificadas dentro del propio screen

### Desktop UI mezclada con políticas

Problema estructural:

- visibilidad de sidebar e inspector
- auto-open/auto-close
- contexto del top bar
- overlays y paneles de revisión

Todo eso existe hoy como estado UI global, pero no como políticas adaptativas reutilizables.

### Integración macOS

Acoplado:

- `lib/main.dart` usa `MethodChannel('musa/app_menu')`
- provider de IA resuelve implementación solo para macOS
- gestión de modelos, hardware detector y ciertas rutas de onboarding viven muy cerca del flujo global

## Hallazgos de arquitectura

### Fortalezas actuales

- MUSA ya tiene un núcleo editorial unificado y persistido localmente.
- El workspace actúa como fuente de verdad seria.
- El dominio no está modelado “por pantalla”, lo cual favorece shells múltiples.
- El tema visual ya expresa una identidad limpia, sobria y editorial.

### Debilidades actuales

- La entrada a la app no contempla shells alternativos.
- Desktop concentra demasiadas decisiones de layout y navegación.
- No existe una capa adaptativa semántica: breakpoints, clases de ventana, políticas de paneles, densidad editorial.
- Hay restos de arquitectura antigua (`lib/project/`) que pueden confundir.

## Implicaciones para la base iPhone/iPad

### iPhone

Debe verse como herramienta de captura y escritura ligera:

- navegación simple
- biblioteca compacta
- documento activo a pantalla completa
- captura rápida sin densidad de inspector ni sidebar desktop

### iPad

Debe verse como herramienta de composición y revisión:

- navegación lateral adaptativa
- split view cuando haya espacio
- editor principal con inspector contextual solo cuando proceda
- soporte natural para ventanas reducidas y multitarea

### Desktop

Debe seguir siendo el estudio completo actual:

- se preserva `MusaMainScreen`
- se encapsula como `DesktopStudioShell`
- no se reescribe como parte de esta fase

## Dirección recomendada

1. Introducir una capa adaptativa semántica propia de MUSA.
2. Encapsular el shell desktop existente sin romperlo.
3. Crear shells nuevos para iPhone e iPad que consuman el mismo workspace y el mismo editor.
4. Mover las políticas de navegación/paneles fuera del screen desktop.
5. Mantener la IA y servicios macOS intactos, pero detrás de contratos ya existentes.

## Refactor mínimo recomendado

- Mantener `MusaMainScreen` como implementación desktop.
- Añadir un `app shell router` que decida shell por plataforma + clase de ventana.
- Crear infraestructura adaptativa en una nueva capa (`lib/app/adaptive/`).
- Crear shells nuevos en `lib/app/shells/`.
- Añadir pantallas base compartidas para biblioteca y documento en `lib/app/features/workspace/`.

## Riesgos detectados

- Parte del editor sigue asumiendo una experiencia principal amplia; en iPhone habrá que validar ergonomía real.
- La IA embebida seguirá sin estar disponible fuera de macOS en esta fase.
- El `workspace notifier` es muy grande; aún funciona, pero convendrá modularizarlo por capacidades en fases posteriores.
- `lib/project/` puede inducir duplicidad conceptual si no se limpia en una fase futura.

## Conclusión

La base actual permite abrir iPhone y iPad con un coste controlado si se evita copiar el shell desktop y se añade una capa adaptativa explícita. El núcleo editorial ya es suficientemente compartible; el trabajo correcto ahora es reorganizar shell, navegación y políticas de layout, no reescribir el dominio.

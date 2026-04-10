# MUSA iPad Compose Phase 2 Plan

Fecha: 2026-04-10

## 1. Auditoría específica del iPad actual

### Estado actual revisado

Archivos inspeccionados:

- `README.md`
- `docs/mobile_ipad_foundation_plan.md`
- `docs/mobile_adaptive_architecture.md`
- `lib/app/shells/ipad/compose_tool_shell.dart`
- `lib/app/features/workspace/presentation/widgets/document_focus_view.dart`
- `lib/app/features/workspace/presentation/widgets/workspace_library_panel.dart`
- `lib/editor/widgets/musa_editor_field.dart`
- `lib/ui/widgets/inspector.dart`
- `lib/editor/controller/editor_controller.dart`
- `lib/editor/widgets/fragment_insight_panel.dart`
- `lib/editor/widgets/chapter_insight_panel.dart`
- `lib/editor/widgets/suggestion_review_panel.dart`
- `lib/editor/widgets/editor_overlay.dart`

### Qué ya sirve bien para iPad

- El `NarrativeWorkspace` y sus providers ya resuelven libro, documento, nota, continuidad, personajes y escenarios sin depender del shell desktop.
- `EditorController` ya concentra selección, análisis de fragmento/capítulo y flujo Musa.
- `MusaEditor` ya es funcional y persistente sobre el workspace actual.
- `DocumentFocusView` y `WorkspaceLibraryPanel` ya permiten abrir documento y escribir sin duplicar dominio.
- La capa adaptativa ya diferencia `capture`, `compose` y `studio`.

### Qué sigue oliendo a desktop

- El flujo editorial rico sigue viviendo en widgets flotantes pensados para estudio desktop:
  - `editor_overlay`
  - `fragment_insight_panel`
  - `chapter_insight_panel`
  - `suggestion_review_panel`
- El inspector desktop mezcla demasiadas responsabilidades y demasiada densidad para tablet.
- `MusaEditor` mantiene paddings y espaciamiento de sesión larga desktop, especialmente en cabecera y márgenes del cuerpo.
- La shell iPad actual solo es una estructura base; no propone aún un flujo Compose claro.

### Fricciones detectadas por contexto de ventana

#### iPad portrait / medium

- Falta navegación lateral usable sin ocupar permanentemente ancho crítico.
- Falta una forma clara de abrir contexto/editorial review sin overlays desktop.
- El documento necesita más foco y menos chrome.

#### iPad split / medium

- La shell actual no ofrece una reducción clara de densidad.
- El inspector persistente desaparece, pero no se sustituye por una alternativa con valor equivalente.
- Biblioteca y contexto compiten por el mismo espacio sin una estrategia clara.

#### iPad landscape / expanded

- Ya hay espacio para split real, pero la shell actual no usa ese espacio para composición editorial útil.
- El inspector actual solo muestra contexto básico; no integra de verdad análisis ni Musa.

### Qué falta para que iPad tenga valor real

1. Un shell Compose con foco principal en documento y navegación lateral adaptativa.
2. Un inspector propio para iPad que combine:
   - contexto narrativo inmediato
   - análisis editorial
   - flujo Musa
3. Acciones rápidas de composición en la cabecera del documento.
4. Ajustes de ergonomía del editor para tablet.
5. Un comportamiento claro para `medium` y `expanded` sin copiar desktop.

## 2. Contrato funcional de Compose Tool

### Qué es

La Compose Tool de iPad es la herramienta de composición y revisión editorial de MUSA para sesiones de escritura intermedias y móviles con contexto, situada entre:

- iPhone: captura ligera
- Desktop: estudio completo

### Qué no es

- no es el shell desktop reducido
- no es una versión grande del iPhone
- no es el lugar para toda la gestión avanzada del estudio
- no es la fase para añadir nuevas capacidades IA o sync

### Propósito

Permitir escribir, revisar y orientar el documento activo con apoyo editorial local-first y contexto suficiente, manteniendo una experiencia sobria y usable en iPad.

### Capacidades principales de esta fase

- abrir biblioteca y documentos del workspace
- editar documento o nota activa
- consultar contexto narrativo inmediato
- lanzar análisis de fragmento o capítulo
- consultar resultados editoriales relevantes
- invocar una Musa desde una selección activa
- revisar, comparar, aceptar o descartar sugerencias
- acceder a notas editoriales vinculadas al documento

### Fuera de alcance en esta fase

- replicar toda la instrumentación desktop
- nuevo runtime IA para iPadOS
- sync remoto
- graph / atlas / spatial
- rediseño total del editor
- reescritura del `workspace notifier`

### Prioridades de foco

1. Documento activo
2. Contexto editorial inmediato
3. Navegación lateral del workspace
4. Revisión y Musa

### Reglas de navegación

- `expanded`: biblioteca persistente a la izquierda + documento + inspector persistente
- `medium`: documento prioritario; biblioteca y inspector viven como paneles invocables
- la navegación lateral del workspace debe poder cambiar entre:
  - biblioteca
  - índice
  - notas

### Reglas de inspector

- no replica el inspector desktop
- se centra en:
  - documento y continuidad
  - notas/editorial workflow
  - personajes y escenarios vinculados
  - análisis actual
  - Musa y revisión
- `expanded`: panel persistente
- `medium`: panel modal/secundario invocable

### Reglas por window class

#### `medium`

- documento a pantalla principal
- biblioteca en drawer/panel lateral invocable
- inspector en panel secundario/modal
- acciones rápidas visibles en cabecera

#### `expanded`

- composición en split real
- biblioteca persistente
- inspector persistente
- revisión editorial sin overlays flotantes desktop

## 3. Implementación recomendada para esta fase

1. Mantener desktop intacto.
2. Reusar `EditorController` como orquestador editorial.
3. Añadir un inspector Compose específico.
4. Llevar acciones de análisis/Musa a la shell iPad y al inspector.
5. Introducir un contrato de ergonomía del editor reusable para tablet.

## 4. Resultado esperado

Al terminar esta fase, el iPad debe sentirse como una herramienta real de composición de MUSA: más centrada y ligera que desktop, pero con suficiente contexto editorial para escribir y revisar con criterio.

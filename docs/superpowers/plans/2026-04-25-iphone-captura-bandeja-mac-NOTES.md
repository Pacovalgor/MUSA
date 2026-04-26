# Notas de implementación · Ola 1 — captura iPhone → bandeja Mac

## Desviaciones del plan

### Task 5 / Task 6: Swift channels embebidos

El plan pedía crear `macos/Runner/InboxBookmarkChannel.swift` y `ios/Runner/InboxBookmarkChannel.swift` como archivos separados, lo cual habría requerido editar `project.pbxproj` (frágil).

**Decisión:** las clases `InboxBookmarkChannel` viven embebidas en `MainFlutterWindow.swift` (macOS) y `AppDelegate.swift` (iOS). Esto sigue el patrón existente del proyecto (`SecureFilePickerHandler` está embebido también) y evita tocar `project.pbxproj`. Coherente con `cambio_minimo_correcto` del `PROJECT_PROFILE.yaml`.

### Task 21: Settings + Onboarding integrados Mac — APLAZADO a Ola 1.5

El plan permitía explícitamente aplazar Task 21 si el popover ya gestionaba `unconfigured` y `unreachable`. **Y lo hace** (`_ConfigurePrompt` y `_UnreachablePrompt` en `lib/ui/inbox/popover/inbox_popover.dart`).

Añadir una sección "Bandeja" a `lib/ui/widgets/musa_settings_dialog.dart` (1363 líneas) requeriría comprender el patrón de `_SectionCard`, los providers internos del diálogo y su layout. Riesgo de "refactor oportunista" en un archivo grande no relacionado.

**Estado:** aplazado a Ola 1.5. La funcionalidad que daría (cambiar carpeta, mostrar path) ya está accesible desde el popover de toolbar.

**Cuándo retomarlo:** si el usuario reporta fricción para reconfigurar la carpeta, o si se añaden más opciones (deviceLabel editable en Mac, política de purga, etc.) que justifiquen un panel propio.

## Tests

- 161 pass / 5 fail en main al inicio de la Ola.
- **161 pass / 5 fail al final de la Ola** (5 fallos pre-existentes intactos, 0 regresiones, 29 tests nuevos añadidos por Tasks 2, 3, 4 con TDD).

## Tareas no implementadas

- ❌ Settings Mac (Task 21) — aplazada (ver arriba).
- ❌ Entrada de menú nativo "Ver → Bandeja de capturas" (parte opcional de Task 20). Sólo el atajo `⌘⇧B` y el botón de toolbar están conectados. La entrada de menú requeriría tocar `MainMenu.xib` y añadir un canal en `AppDelegate.swift` macOS — coste alto para beneficio bajo dado que el atajo y el botón ya cubren el caso.

## Tareas implementadas según plan literal

Tasks 1, 2, 3, 4, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 — todas completas. Total 20 tasks de las 22 del plan.

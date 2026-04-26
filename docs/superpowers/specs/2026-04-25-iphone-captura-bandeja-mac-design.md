# Captura iPhone → Bandeja en Mac (Ola 1)

**Estado:** Diseño aprobado, pendiente de plan de implementación.
**Fecha:** 2026-04-25
**Alcance:** Slice vertical "captura iPhone → bandeja Mac" como Ola 1 de un proyecto multi-dispositivo más amplio.

## Resumen ejecutivo

Permitir al usuario capturar **texto y URLs** desde el iPhone y verlas aparecer en una **bandeja en el Mac** sin depender de servicios propios. El transporte es una carpeta del sistema de archivos que el usuario elige libremente — sincronizada por iCloud Drive, Drive, OneDrive, Dropbox o cualquier otro proveedor que el usuario ya use. MUSA no habla con APIs de terceros; sólo con el filesystem.

Cada captura es un archivo JSON con UUID. La bandeja del Mac vive como **popover en la barra superior** + **ventana de gestión** independiente. Aceptar una captura crea una `Note` en el módulo existente y mueve el archivo a `processed/`.

Ola 1 entrega kinds `text` y `link`. Voz, foto y Share Extension son Olas posteriores.

## Cómo se llegó aquí — decisiones tomadas

| Decisión | Elegido | Por qué |
|---|---|---|
| Caso de uso global | Roles especializados por dispositivo | iPhone = bandeja de captura. Define el resto del proyecto. |
| Slice de arranque | A: captura iPhone → Mac | iPhone es el dispositivo más vestigial; el slice cierra primero por ser append-only |
| Transporte | Camino 1: filesystem agnóstico | "No depender de nadie" sin OAuth/SDKs por proveedor; cumple local-first |
| Kinds | C-2 / Ola 1 = `text` + `link` | Arquitectura completa de C, primer subset cerrado, sin permisos del sistema |
| Bandeja en Mac | C: popover + ventana de gestión | Decisión del usuario; popover ligero para 1-3 capturas, ventana propia para gestión real |
| iPhone | A: 2 tabs (Capturar + Historial) | El historial es necesario porque el sync provider tiene latencia variable |
| Selector de proyecto | Aplazado a Ola 1.5 | Requiere manifesto del Mac; Ola 1 se simplifica con `projectHint: null` |
| Acciones por captura | Mínimo: aceptar como nota / expandir / descartar | Pickers (anclar a personaje/escenario/libro) son Ola 1.5 |

## Alcance

### Lo que entra en Ola 1

- App iPhone "MUSA Capturar" reducida (2 tabs: Capturar, Historial)
- Pantalla de bandeja en Mac (popover toolbar + ventana de gestión)
- Onboarding de carpeta sincronizada en cada dispositivo
- Lectura/escritura del filesystem con security-scoped bookmarks
- Detección automática de kind (`text` vs `link`)
- Tres acciones en la bandeja del Mac: **Aceptar como nota**, **Expandir y editar**, **Descartar**
- Estados: pendiente / procesada / descartada / sincronizando / sin carpeta
- Watcher de filesystem en Mac (FSEvents) para detección reactiva de capturas nuevas

### Lo que NO entra (lista explícita)

- ❌ Voz / audio (Ola 2)
- ❌ Foto / imagen (Ola 3)
- ❌ Share Extension de iOS (Ola 3)
- ❌ Selector de proyecto en iPhone (Ola 1.5)
- ❌ Pickers para anclar a personaje / escenario / libro (Ola 1.5)
- ❌ Multi-selección, filtros, búsqueda (Ola 1.5)
- ❌ Borradores auto-guardados en iPhone (Ola 1.5 si surge la necesidad real)
- ❌ Push notifications (innecesario; el badge en toolbar basta)
- ❌ Encriptación end-to-end propia (responsabilidad del sync provider del usuario)
- ❌ Unfurl de links (resolución del `<title>`) — Ola 1.5
- ❌ Tabs "Biblioteca" y "Documento" del `CaptureToolShell` actual — se ocultan/marcan "Próximamente" en Ola 1 porque requieren sync del workspace (otro slice del proyecto madre)

### Restricciones que respeta este diseño

Del `ai/memory/PROJECT_PROFILE.yaml`:

- **`cambio_minimo_correcto`**: cada decisión cuestionada favorece la opción menor.
- **`scope_estricto`**: Olas 2 y 3 explícitamente fuera.
- **`local_first_y_privacidad`**: la nube es del usuario; MUSA sólo habla con el filesystem.
- **`no_degradar_persistencia_del_workspace_local`**: la bandeja vive **fuera del `.musa`**. El contrato del documento del workspace queda intacto.
- **`mantener_arquitectura_riverpod_y_modelos_inmutables`**: nuevo módulo `inbox` con providers y modelos `@immutable`.

## Arquitectura

### Topología

```
┌─────────────────┐         ┌──────────────────────┐         ┌─────────────────┐
│  iPhone         │         │  Carpeta             │         │  Mac            │
│  MUSA Capturar  │  write  │  sincronizada        │  read   │  MUSA Studio    │
│                 ├────────►│  (iCloud/Drive/      │◄────────┤  (popover +     │
│  - 2 tabs       │         │   OneDrive/...)      │         │   ventana)      │
│  - text/link    │         │  MUSA-Inbox/         │  move   │                 │
└─────────────────┘         │   <fecha>/*.json     │◄───┐    │  - lee inbox    │
                            │   processed/         │    │    │  - acepta/desc. │
                            │   discarded/         │    │    │  - crea Note    │
                            └──────────────────────┘    │    └─────────────────┘
                                                        └────────── escribe en processed/discarded
```

**Reglas del transporte:**

- Sólo el iPhone escribe en `MUSA-Inbox/<fecha>/`.
- Sólo el Mac mueve archivos a `processed/` o `discarded/`.
- Nadie modifica un archivo después de escrito (append-only por contrato).
- Ningún dispositivo conoce los demás. Cada uno habla sólo con el filesystem.

### Contrato del archivo JSON

```json
{
  "schemaVersion": 1,
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "capturedAt": "2026-04-25T17:32:14Z",
  "deviceLabel": "iPhone de Paco",
  "kind": "text",
  "body": "Diane mira la pizarra. Lo que NO está escrito es lo que importa.",
  "url": null,
  "title": null,
  "projectHint": null
}
```

| Campo | Tipo | Obligatorio | Notas |
|---|---|---|---|
| `schemaVersion` | int | sí | Empieza en `1`. Cada cambio incompatible incrementa. |
| `id` | string (UUID v4) | sí | Único global. El nombre del archivo deriva de aquí. |
| `capturedAt` | string (ISO 8601 UTC) | sí | Fuente de verdad para ordenar. |
| `deviceLabel` | string | sí | Editable en settings; default `"iPhone"` o `"Mac"` + nombre del dispositivo. |
| `kind` | enum | sí | Ola 1: `"text"` \| `"link"`. Olas siguientes añadirán `"voice"`, `"image"`. |
| `body` | string | sí | En `text` = el contenido. En `link` = comentario opcional sobre el link (puede ser `""`). |
| `url` | string \| null | sí (null si kind ≠ link) | URL absoluta. |
| `title` | string \| null | no | Reservado para Ola 1.5 (unfurl). En Ola 1 siempre `null`. |
| `projectHint` | string \| null | no | Reservado para Ola 1.5 (selector de proyecto en iPhone). En Ola 1 siempre `null`. |

**Validación al leer:** si falta cualquier campo obligatorio o `schemaVersion > 1`, MUSA marca la captura como `⚠️ Ilegible` y permite ver el bruto y descartar.

### Estructura de carpetas

```
<carpeta-elegida-por-el-usuario>/
└── MUSA-Inbox/
    ├── 2026-04-25/
    │   ├── 17-32-14-550e8400-e29b-41d4-a716-446655440000.json
    │   └── 17-45-02-661f9511-e29b-41d4-a716-557788990011.json
    ├── 2026-04-26/
    │   └── 09-12-08-...json
    ├── processed/
    │   └── 550e8400-e29b-41d4-a716-446655440000.json
    └── discarded/
        └── 661f9511-e29b-41d4-a716-557788990011.json
```

**Convenciones:**

- Subcarpeta por día en hora local del dispositivo que escribe (legibilidad para humanos al inspeccionar; el orden real lo da `capturedAt` UTC del JSON).
- Nombre del archivo: `<HH-MM-SS>-<uuid>.json`. Sortable lexicográficamente.
- `processed/` y `discarded/` no tienen subcarpetas — un archivo procesado puede vivir años y no se vuelve a inflar la lista por carpeta porque ya nadie navega esas dos a mano.
- Si el día UTC y el día local difieren (cruzas medianoche), el archivo va a la subcarpeta del día *local* del dispositivo. La verdad cronológica está en el JSON.

## iPhone — MUSA Capturar

### Pantallas

**Tab 1: Capturar** (default al abrir)

- Cabecera: título `Capturar` + pill de estado de sync (verde / amarilla / roja).
- Input principal: textarea grande con auto-focus al abrir y placeholder *"Una idea, un link, una frase…"*. Detección automática de kind muestra un chip arriba a la derecha (`📝 texto` o `🔗 link`).
- Botón `Guardar a la bandeja` al pie. Deshabilitado si el body está vacío.
- Tras guardar: toast `✓ Guardado a la bandeja`, input se vacía, auto-focus de nuevo.

**Tab 2: Historial**

- Lista vertical de las últimas N capturas enviadas desde este dispositivo (sugerido N=20, configurable más tarde si hace falta).
- Cada item: timestamp local + chip de kind + body recortado a 2 líneas + estado.
- Read-only: no se editan ni se eliminan capturas pasadas.
- Pull-to-refresh re-lee la carpeta para actualizar estados.

### Lógica clave

**Detección de kind** (`KindDetectorService`):

```
input.trim() es una URL absoluta válida (http/https/file)?
  └─ sí: kind = "link", url = input.trim(), body = ""
  └─ no:
     ¿el input contiene una URL?
       └─ sí: kind = "link", url = primera URL extraída, body = input completo
       └─ no: kind = "text", url = null, body = input
```

**Estado del historial** (calculado, no persistido):

| Estado | Cómo se calcula |
|---|---|
| `Pendiente` | Archivo aún en `MUSA-Inbox/<fecha>/` |
| `Procesada` | Archivo en `MUSA-Inbox/processed/` |
| `Descartada` | Archivo en `MUSA-Inbox/discarded/` |
| `Subiendo` | (Sólo Mac, vía `NSMetadataQuery`) — en iPhone se simplifica a `Pendiente`. |

**Sin polling agresivo:** el historial se recalcula al abrir la app y al hacer pull-to-refresh. No hay timer en background.

**El iPhone mantiene un cache local** de los UUIDs que envió (en sandbox de la app, no en la carpeta sincronizada). Cuando lee la carpeta, sabe qué archivos son suyos para construir el historial. Si la app se reinstala, se pierde el historial pero las capturas siguen vivas en la carpeta — el iPhone simplemente ya no las "reconoce como suyas".

**Purga del cache:** al recalcular el historial, el iPhone elimina del cache los UUIDs cuyo archivo no aparece en ninguna de las tres carpetas (`<fecha>/`, `processed/`, `discarded/`). Eso cubre el caso del usuario que limpia carpetas a mano y mantiene el cache acotado al tamaño de capturas vivas.

**Sin watcher activo en iPhone.** No hay observación de filesystem en background. El historial se reconstruye sólo al abrir la app o hacer pull-to-refresh. Razón: batería y simplicidad. El iPhone es write-mostly; saber el estado exacto en tiempo real no aporta valor proporcional al coste.

### Cambio mínimo en el shell iPhone existente

`lib/app/shells/iphone/capture_tool_shell.dart` (69 líneas hoy) se mantiene como envoltorio pero los tabs cambian:

- Tab 0 (Biblioteca) → oculto en Ola 1, se mostrará tras Slice de sync de workspace.
- Tab 1 (Documento) → oculto en Ola 1, idem.
- Tab 2 (Captura) → reemplazado por flujo nuevo de 2 sub-tabs (Capturar + Historial).

En Ola 1, el shell iPhone es esencialmente la "subaplicación MUSA Capturar".

## Mac — bandeja con popover + ventana de gestión

### Componentes

**1. Popover en la barra superior**

- Botón con icono 📥 + badge numérico cuando hay pendientes.
- Al hacer click, popover (~280px de ancho) con:
  - Título: `Capturas pendientes (N)`
  - Lista de las capturas más recientes (max 5 visibles, scroll si más).
  - Cada item: timestamp + chip de kind + body recortado.
  - Acciones inline mínimas por item: `Aceptar` y `Descartar` (botones pequeños).
  - Pie del popover: enlace `Ver todas (N) →` que abre la ventana de gestión.

**2. Ventana de gestión** (separada, no popover)

- Atajo de teclado: `⌘⇧B`.
- También accesible desde menú `Ver → Bandeja de capturas` y desde el enlace del popover.
- Layout master-detail:
  - **Lista a la izquierda** de todas las capturas pendientes (scrolleable, ordenadas por `capturedAt` desc).
  - **Detalle a la derecha**: la captura completa + acciones.
- Acciones en el detalle (Ola 1):
  - `Aceptar como nota` (botón primario)
  - `Expandir y editar` (modo edición inline en el panel de detalle: el `body` se vuelve editable, aparecen `Cancelar` / `Guardar y aceptar`. **No es modal aparte** — escribir uno completo es Ola 1.5.)
  - `Descartar` (botón secundario)

### Acción "Aceptar como nota"

1. Crea una `Note` en el módulo `lib/modules/notes/` con:
   - `body` = body de la captura (incluyendo URL si es kind=link).
   - `metadata.source` = `"inbox"` (campo nuevo opcional para distinguir origen).
   - `metadata.capturedAt` = del JSON.
   - `metadata.deviceLabel` = del JSON.
2. Mueve el archivo `.json` de `MUSA-Inbox/<fecha>/` a `MUSA-Inbox/processed/`.
3. Actualiza el `lastWriteAt` para que el watcher del iPhone lo detecte como movido.
4. Refresca la lista de la bandeja en Mac.

### Acción "Descartar"

Mueve a `MUSA-Inbox/discarded/`. No borra. La papelera del sync provider hará su trabajo si el usuario lo desea, pero MUSA preserva auditabilidad.

### Watcher

- macOS: `FSEvents` sobre `MUSA-Inbox/`. Reacciona a creaciones, movimientos y eliminaciones.
- Debounce de 250ms para evitar tormentas durante un sync masivo del provider.

## Onboarding

### Primera vez en iPhone

1. Pantalla de bienvenida una sola vez:

   > **MUSA Capturar**
   > Guarda tus ideas en una carpeta que tú elijas — puede estar en iCloud, Drive, OneDrive, Dropbox… cualquier servicio de sync que ya uses.
   > Tus capturas son archivos `.json` que tú controlas. MUSA no habla con ningún servicio en la nube.
   >
   > [ Elegir carpeta ]

2. Tap en `Elegir carpeta` → `UIDocumentPickerViewController` modo `open` con `documentTypes = [kUTTypeFolder]`.

3. Tras la selección:
   - Crear subcarpeta `MUSA-Inbox/` si no existe.
   - Guardar security-scoped bookmark en `UserDefaults` o equivalente.
   - Validación: escribir `.musa-test`, comprobar lectura, eliminar.
   - Si falla: mostrar error y volver al paso 2.

4. Pasa a la pantalla de captura.

### Primera vez en Mac

Mismo flujo con `NSOpenPanel` (`canChooseDirectories = true`). Si la carpeta ya contiene archivos `MUSA-Inbox/`, los muestra en la bandeja desde el primer arranque.

### Cambiar la carpeta más tarde

Settings → Bandeja → `Cambiar carpeta…`. Avisa: *"Las capturas pendientes en la carpeta anterior dejarán de aparecer aquí. No se borran — siguen en su sitio."*

## Settings

Ola 1 expone un único panel en `Settings → Bandeja` con tres opciones:

| Setting | Tipo | Default | Notas |
|---|---|---|---|
| **Carpeta de bandeja** | path / picker | (vacío hasta primer onboarding) | Click → re-ejecuta el flujo de onboarding (picker + validación). |
| **Etiqueta de este dispositivo** | string | `"iPhone de <nombreUsuario>"` o `"Mac de <nombreUsuario>"` (resuelto desde el sistema) | Es lo que aparece en `deviceLabel` del JSON. Editable. |
| **Capturas en historial (sólo iPhone)** | int | `20` | Límite de items mostrados en el tab Historial. |

Sin opción para configurar acciones, layout, ordenación. Si surgen necesidades reales en uso, Ola 1.5.

## Estados, errores, edge cases

### Pill de sync en iPhone

| Color | Texto | Disparador |
|---|---|---|
| 🟢 verde | `Sincronizado` | Bookmark válido, último escritura OK |
| 🟡 amarillo | `Subiendo…` | Mientras se escribe el archivo (transitorio) |
| 🔴 rojo | `Sin carpeta` | Bookmark inválido / carpeta inaccesible / disco lleno |

### Botón de bandeja en Mac

| Color | Disparador |
|---|---|
| Sin badge | 0 capturas pendientes |
| Verde con número | N capturas pendientes |
| Rojo con `!` | Carpeta inaccesible |

### Edge cases que el spec cubre

| Caso | Comportamiento |
|---|---|
| Reloj iPhone desincronizado | Sólo se usa UTC en `capturedAt`. Subcarpeta por fecha local es solo cosmética. |
| Dos iPhones del usuario capturan al mismo segundo | UUID resuelve. Ambos `.json` aparecen. |
| Usuario mata la app antes de guardar | Sin auto-save de borradores en Ola 1. Lo no guardado se pierde. |
| Usuario edita un `.json` a mano | Si campos requeridos y `schemaVersion` válida, MUSA lo lee. Si no, `⚠️ Ilegible` con opción de ver bruto y descartar. |
| Carpeta en USB no conectada | iPhone: pill rojo. Mac: rojo. Sin cola interna. |
| `processed/` o `discarded/` borradas a mano | A MUSA no le importa — son carpetas de auditoría. |
| `body` muy largo (>10 KB) | Permitido. Si escala mal, lo verá Ola 2. |
| Mismo `id` aparece dos veces | Mac deduplica por `id`; si el contenido difiere, prevalece `capturedAt` más reciente y el otro va a `discarded/_collisions/`. |
| Usuario cambia la carpeta sincronizada | Settings permite cambiar. Capturas anteriores no migran automáticamente — siguen en su carpeta antigua. |

## Arquitectura técnica en MUSA

### Nuevos módulos

```
lib/modules/inbox/
├── models/
│   ├── inbox_capture.dart          # @immutable, JSON-serializable
│   └── inbox_capture_status.dart   # enum: pending | processed | discarded | unreadable
├── services/
│   ├── inbox_storage_service.dart  # read/write/move filesystem ops
│   ├── inbox_bookmark_service.dart # security-scoped bookmarks (iOS + macOS via FFI)
│   └── kind_detector_service.dart  # text/link detection
└── providers/
    ├── inbox_folder_provider.dart  # ruta de la carpeta + estado
    ├── inbox_captures_provider.dart # lista de capturas pendientes
    └── inbox_history_provider.dart  # historial del iPhone (cache local)
```

### UI

```
lib/ui/inbox/
├── popover/
│   └── inbox_popover.dart          # Mac: popover en toolbar
├── window/
│   ├── inbox_management_window.dart # Mac: ventana propia con master-detail
│   └── widgets/
│       ├── capture_list_item.dart
│       ├── capture_detail_panel.dart
│       └── capture_inline_editor.dart
└── iphone/
    ├── capture_screen.dart          # Tab 1
    └── history_screen.dart          # Tab 2
```

### Integración con shells existentes

- `lib/app/shells/iphone/capture_tool_shell.dart` se modifica para que su tab "Captura" cargue el flujo de 2 sub-tabs nuevo. Los otros dos tabs se ocultan tras un flag de feature.
- `lib/ui/layout/main_screen.dart` (Mac, 700+ líneas hoy) recibe **un solo añadido**: el botón de la bandeja en su toolbar. Ningún refactor de la pantalla principal.
- La ventana de gestión vive como **ruta propia** dentro del Studio Shell — no se fuerza dentro de `main_screen.dart` para no inflar más ese archivo.

### Integración con `Note`

Al aceptar una captura, `inbox_storage_service.acceptAsNote(capture)` invoca el provider del módulo `lib/modules/notes/` para crear una nota nueva con campo extra `metadata.source = "inbox"`. Si el módulo `notes` no expone hoy un punto de extensión limpio para esto, se añade un método mínimo `notesProvider.addFromInbox(capture)` — punto único de acoplamiento.

### Tests

- **Unit tests del `KindDetectorService`** con casos limítrofes: URL pura, URL con parámetros, URL con texto antes/después, URLs malformadas, dominios sin protocolo, mailto:, tel:, etc.
- **Unit tests del `InboxStorageService`** sobre filesystem temporal (`Directory.systemTemp.createTempSync()`). Cubrir lectura, escritura, mover, JSON corrupto, `schemaVersion > 1`, archivos sin permisos.
- **Tests de modelos** (serialización/deserialización con todos los `kind`).
- **Integration test opcional** que escribe en una carpeta real, espera 2s, y verifica detección. No corre en CI (depende de FS).

### Estimación

Ola 1 cabe en aproximadamente **5-7 días de trabajo focalizado**, distribuidos así:

| Pieza | Estimación |
|---|---|
| Modelos `InboxCapture` + serialización + tests | 0.5 d |
| `KindDetectorService` + tests | 0.5 d |
| `InboxStorageService` (FS, tests con FS temporal) | 1 d |
| `InboxBookmarkService` (Swift channels para iOS y macOS) | 1 d |
| iPhone: 2 tabs (Capturar + Historial) + onboarding | 1.5 d |
| Mac: popover en toolbar + ventana de gestión + acciones | 1.5 d |
| Integración con módulo `notes` (acción `aceptar como nota`) | 0.5 d |
| Settings + edge cases + manualidad | 0.5 d |

Es estimación conservadora; depende de cuánto código hay que mover en `main_screen.dart` para meter el botón en la toolbar.

### Plataformas

- **macOS**: FFI no necesario; security-scoped bookmarks via `NSURL.bookmarkData` mediante un canal pequeño (Swift code en `macos/Runner/`).
- **iOS**: igual; `URL.bookmarkData` Swift en `ios/Runner/`.
- **Otras plataformas (Linux, Windows, web)**: el módulo `inbox` reporta `unavailable` con la misma estética que los servicios IA actuales en plataformas no soportadas.

## Riesgos y mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Latencia del sync provider hace que las capturas tarden minutos en llegar al Mac | Alta | Medio | Indicador claro de estado en iPhone (`Subiendo…`). Documentado en onboarding: *"la sincronización depende de tu proveedor"*. |
| Security-scoped bookmark se invalida (usuario movió la carpeta) | Media | Alto | Validación al inicio de la app; pill rojo si falla; flujo claro de reconfiguración. |
| Conflicto de `id` por bug raro de provider | Baja | Bajo | Deduplicación en Mac por `id`; carpeta `_collisions/` para auditoría. |
| Usuario espera funcionalidad que NO está en Ola 1 (anclar, voz, foto) | Alta | Bajo | Sección "NO entra" explícita en este spec; la UI de Ola 1 no enseña *handles* de funciones futuras. |
| `lib/ui/layout/main_screen.dart` ya es grande; añadir más allí lo empeora | Alta | Medio | El botón es único añadido; la ventana de gestión vive como ruta independiente. Ningún refactor opportunista en esta Ola. |
| FSEvents no detecta cambios en algunas carpetas en red | Baja | Medio | Fallback: re-lectura periódica cada 30s sólo cuando la ventana de gestión está abierta. |

## Criterios de éxito

La Ola 1 se considera terminada cuando:

1. Usuario configura carpeta en iPhone y Mac apuntando al mismo iCloud Drive (u otro provider) **una sola vez** en cada dispositivo.
2. Usuario captura `text` desde iPhone → archivo `.json` aparece en `MUSA-Inbox/<fecha>/` < 1s.
3. Sync provider replica el archivo al Mac (latencia depende del provider, fuera de control).
4. Mac detecta el archivo (FSEvents o re-lectura) y aparece en el badge del popover y en la ventana de gestión.
5. Usuario `Acepta como nota` → la nota aparece en el módulo `notes` del workspace activo, el `.json` está en `MUSA-Inbox/processed/`.
6. Captura `link` con URL pegada se detecta automáticamente (chip 🔗 en iPhone) y se muestra como link en la bandeja.
7. Historial del iPhone muestra la captura como `Procesada` tras pull-to-refresh.
8. Si el usuario rota carpeta o desconecta USB con la carpeta, el pill se pone rojo y permite reconfigurar sin perder capturas anteriores.
9. Suite de tests existente sigue pasando (no rompemos `editor`, `workspace`, IA, persistencia `.musa`).
10. Tests nuevos del módulo `inbox` pasan: `KindDetectorService`, `InboxStorageService` con FS temporal, modelos.

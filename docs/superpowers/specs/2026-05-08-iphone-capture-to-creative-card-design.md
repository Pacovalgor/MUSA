# V3.4 · Captura iPhone a tarjeta creativa

## Contexto

V3.1 creó la Mesa creativa por libro y V3.2 convirtió cada tarjeta en una unidad rica: editable, con adjuntos, vínculos y acciones de conversión. MUSA ya tiene además una primera ola de captura iPhone hacia bandeja Mac mediante `InboxCapture`, `InboxStorageService`, `CaptureScreen`, `InboxPopover`, `InboxManagementScreen` y `CaptureActions`.

El siguiente paso no debe crear una sincronización directa de workspace entre dispositivos. El camino correcto es aprovechar la bandeja existente como frontera local-first y hacer que las capturas móviles aterricen como tarjetas creativas útiles.

## Objetivo

Convertir la captura iPhone en una entrada natural de la Mesa creativa:

- iPhone captura texto, enlaces y una intención editorial simple.
- Mac revisa la bandeja y crea tarjetas creativas del libro activo.
- La tarjeta resultante conserva origen, tipo sugerido, cuerpo, URL y adjuntos.
- La captura no se marca como procesada si no pudo crearse una tarjeta.

## No objetivos

- No implementar sincronización directa de `.musa` entre iPhone y Mac.
- No resolver conflictos multi-dispositivo.
- No crear editor completo de tarjetas en iPhone.
- No crear gestor de media ni copiar imágenes/audio al proyecto.
- No transcribir audio ni reproducir audio dentro de MUSA en esta versión.
- No construir todavía mapa mental/canvas.

## Diseño de producto

### iPhone

La pantalla `CaptureScreen` sigue siendo una herramienta rápida:

- campo grande de texto;
- detección automática de enlace como hasta ahora;
- selector de intención: `Idea`, `Boceto`, `Pregunta`, `Research`;
- botón `Guardar en bandeja`;
- estado de carpeta sincronizada/desconectada.

El selector no obliga al usuario a organizar la idea. Solo añade una pista editorial para el Mac.

### Mac

La bandeja conserva el flujo actual, pero cambia la prioridad:

- acción principal: `Crear tarjeta`;
- acción secundaria: `Aceptar como nota`;
- acción de descarte se mantiene;
- en ventana completa, el usuario puede editar cuerpo y corregir tipo creativo antes de aceptar;
- en popover, `Crear tarjeta` usa el tipo sugerido o inferido sin abrir un flujo pesado.

Si no hay libro activo, `Crear tarjeta` no mueve el archivo a procesados y deja la captura pendiente.

## Modelo de datos

### InboxCapture

Se extiende de forma compatible:

- `creativeTypeHint`: nombre de `CreativeCardType` sugerido por iPhone o Mac.
- `attachmentUri`: referencia opcional a imagen/audio/enlace local.
- `attachmentKind`: tipo de adjunto compatible con `CreativeCardAttachmentKind` cuando aplique.

Compatibilidad:

- `schemaVersion` puede seguir aceptando capturas antiguas.
- Campos nuevos son opcionales.
- Capturas de versión antigua sin `creativeTypeHint` siguen funcionando con inferencia.
- Capturas con `kind` desconocido siguen siendo ilegibles, como ahora.

### CreativeCard

No requiere cambios de modelo. Ya soporta:

- `type`;
- `source`;
- `attachments`;
- `createdAt`;
- `updatedAt`;
- `status`.

## Flujo de datos

1. iPhone construye un `InboxCapture`.
2. `KindDetectorService` detecta URL si existe.
3. `CaptureScreen` añade `creativeTypeHint` según selector.
4. `InboxStorageService.write` deposita el JSON en `MUSA-Inbox`.
5. Mac lee capturas pendientes.
6. `CaptureActions.acceptAsCreativeCard` llama a `addCreativeCardFromInbox`.
7. `NarrativeWorkspaceNotifier` crea una `CreativeCard` del libro activo.
8. Solo si la tarjeta se creó, la captura pasa a `processed`.

## Reglas de inferencia

`addCreativeCardFromInbox` debe aceptar un tipo explícito opcional:

- si llega `creativeTypeHint`, se usa ese tipo si es válido;
- si no llega, se conserva la inferencia actual;
- enlaces puros pueden seguir mapeando a `research`;
- texto sin tipo explícito puede seguir entrando como `idea`.

## Adjuntos

En esta versión:

- una URL detectada sigue creando adjunto `link`;
- una referencia de imagen se guarda como adjunto `image` con URI/ruta;
- audio queda preparado como URI textual si llega, pero sin reproducción ni transcripción;
- no se copian archivos al `.musa`.

## Errores y estados vacíos

- Sin carpeta configurada en iPhone: se conserva el mensaje actual.
- Bandeja desconectada en Mac: se conserva el flujo actual de reintentar/reconfigurar.
- Captura ilegible: se conserva descarte manual.
- Sin libro activo: `Crear tarjeta` no procesa la captura y muestra un error recuperable.
- Tipo creativo inválido: se ignora el hint y se usa inferencia.

## Cambios esperados

### Modelo y servicios

- Extender `InboxCapture`.
- Extender tests de serialización de inbox.
- Extender `CaptureActions.acceptAsCreativeCard`.
- Extender `NarrativeWorkspaceNotifier.addCreativeCardFromInbox` con parámetros opcionales.
- Mantener `addNoteFromInbox` sin cambios funcionales.

### UI iPhone

- Añadir selector compacto de tipo creativo en `CaptureScreen`.
- Persistir la selección solo dentro de la captura escrita, no como preferencia global.

### UI Mac

- En `CaptureDetailPanel`, añadir selector/corrección de tipo creativo.
- Priorizar visualmente `Crear tarjeta`.
- En `InboxPopover`, añadir acción rápida `Crear tarjeta`.

## Testing

Unitarios:

- `InboxCapture` serializa/deserializa campos nuevos y acepta JSON antiguo.
- `KindDetectorService` conserva detección actual.
- `addCreativeCardFromInbox` respeta tipo explícito válido.
- `addCreativeCardFromInbox` ignora tipo inválido y cae a inferencia.
- `CaptureActions.acceptAsCreativeCard` no marca procesado si no se crea tarjeta.

Widget:

- `CaptureScreen` guarda `creativeTypeHint`.
- `CaptureDetailPanel` permite corregir tipo y crear tarjeta.
- `InboxPopover` ofrece acción rápida `Crear tarjeta`.

Regresión:

- `creative_conversion_test.dart`.
- `inbox_capture_test.dart`.
- `inbox_storage_service_test.dart`.
- `kind_detector_service_test.dart`.

## Criterios de aceptación

- Una captura de iPhone puede convertirse en tarjeta creativa del libro activo sin pasar por nota.
- Las capturas antiguas siguen leyéndose.
- Crear tarjeta solo marca procesado cuando se creó tarjeta.
- La experiencia de iPhone sigue siendo de captura rápida.
- Mac conserva revisión y edición antes de aceptar.
- No se introduce sincronización directa ni gestor de media.

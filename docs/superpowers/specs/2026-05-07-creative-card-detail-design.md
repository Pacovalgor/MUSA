# V3.2 · Tarjeta potente para Mesa creativa

## Estado

Diseño aprobado para planificar implementación.

## Contexto

V3.1 añadió la Mesa creativa por libro: tarjetas persistidas, tablero por estados, conversiones a entidades del workspace y entrada desde Inbox. La base funciona, pero cada tarjeta todavía es una pieza compacta dentro del tablero. Antes de construir captura móvil directa o mapa mental, MUSA necesita que la tarjeta sea una unidad rica, editable y conectable.

V3.2 convierte cada `CreativeCard` en un objeto de trabajo completo: una idea puede madurar con cuerpo, tags, adjuntos y vínculos antes de pasar a nota, personaje, escenario o documento.

## Objetivo

Crear una vista de detalle para tarjetas creativas dentro de la Mesa creativa que permita:

- Editar título, cuerpo, tipo, estado y tags.
- Gestionar adjuntos básicos, empezando por enlaces.
- Preparar soporte de imagen como referencia local sin mover ni copiar archivos todavía.
- Vincular la tarjeta con personajes, escenarios, documentos y notas existentes del libro activo.
- Mantener conversiones controladas sin contaminar memoria narrativa antes de una conversión o acción explícita.

## No objetivos

- No construir mapa mental/canvas en esta versión.
- No crear flujo móvil directo nuevo desde iPhone/iPad.
- No llamar al modelo local para sugerir vínculos.
- No copiar imágenes al paquete `.musa`; las imágenes se guardarán como referencias URI/ruta en esta fase.
- No convertir tarjetas en memoria narrativa, continuidad, auditoría o dirección editorial antes de una conversión explícita.

## Experiencia de usuario

La Mesa creativa seguirá mostrando el tablero por columnas. Al seleccionar una tarjeta, aparecerá un panel de detalle a la derecha de la misma vista en escritorio. El tablero conserva el contexto de organización; el detalle permite trabajar la tarjeta.

Estados esperados:

- Sin tarjeta seleccionada: panel con mensaje breve para seleccionar o crear una tarjeta.
- Tarjeta seleccionada: formulario de edición completo.
- Tarjeta archivada: no aparece en el tablero normal; si en el futuro se abre desde una vista de archivo, sus acciones serán restringidas.
- Tarjeta convertida: sus campos siguen consultables, pero no debe poder volver a estados previos desde la UI normal.

## Componentes

### CreativeBoardEditor

Debe evolucionar de tablero compacto a tablero + detalle:

- Mantiene columnas actuales: Inbox, Explorando, Prometedoras, Listas y Convertidas.
- Mantiene creación rápida.
- Añade selección de tarjeta.
- Renderiza `CreativeCardDetailPanel` para la tarjeta seleccionada.
- Si la tarjeta seleccionada desaparece por archivado o cambio de libro, limpia la selección.

### CreativeCardDetailPanel

Nuevo widget enfocado en edición:

- Campos editables:
  - título
  - cuerpo
  - tipo
  - estado permitido
  - tags
- Adjuntos:
  - listar adjuntos existentes
  - añadir enlace con título opcional
  - eliminar adjunto
  - mostrar imagen referenciada si el adjunto es de tipo imagen y la plataforma puede renderizar la ruta
- Vínculos:
  - mostrar personajes, escenarios, documentos y notas vinculadas
  - permitir vincular/desvincular elementos existentes del libro activo
- Acciones:
  - convertir a nota, personaje, escenario o documento si la tarjeta no está convertida
  - archivar si no está convertida

El panel debe guardar mediante operaciones existentes de `NarrativeWorkspaceNotifier` siempre que sea posible, sin crear una segunda fuente de verdad.

## Datos y contratos

V3.2 debe reutilizar el modelo `CreativeCard` existente:

- `tags`
- `attachments`
- `linkedCharacterIds`
- `linkedScenarioIds`
- `linkedDocumentIds`
- `linkedNoteIds`
- `convertedTo`

No se requiere migración pesada porque V3.1 ya añadió defaults compatibles en JSON. Si se añade algún helper nuevo, debe preservar compatibilidad con proyectos `.musa` antiguos.

Los adjuntos de imagen usarán `CreativeCardAttachmentKind.image` y `uri` como ruta o identificador local. No se implementa todavía copia de archivos ni gestor de media.

## Flujo de datos

1. `CreativeBoardEditor` lee tarjetas visibles del libro activo.
2. El usuario selecciona una tarjeta.
3. `CreativeCardDetailPanel` edita una copia local controlada por campos.
4. Cambios discretos se persisten con `updateCreativeCard`.
5. Vínculos se persisten con `linkCreativeCard` o un helper equivalente si hace falta desvincular de forma clara.
6. Adjuntos se persisten actualizando la tarjeta con una lista nueva.
7. Conversiones usan los métodos ya existentes e idempotentes.

## Manejo de errores

- Si no hay libro activo, se muestra estado vacío.
- Si una actualización falla por workspace no cargado, la UI no debe marcar el cambio como aplicado.
- Si una tarjeta ya está convertida, se bloquean acciones que la devuelvan a estados no convertidos.
- Si una ruta de imagen no puede renderizarse, se muestra como referencia textual, no como error fatal.

## Testing

Tests mínimos:

- El panel de detalle renderiza la tarjeta seleccionada y permite editar título/cuerpo/tags.
- Añadir y quitar un link modifica `attachments`.
- Vínculos a personaje, escenario, documento y nota se persisten sin cambiar de libro.
- Tarjeta convertida no ofrece vuelta a estados previos ni reconversión.
- Cambiar de libro o archivar la tarjeta limpia selección si deja de estar visible.

Verificación esperada:

- `flutter test test/creative_board_editor_test.dart --reporter expanded`
- Tests nuevos de detalle si se separan en `test/creative_card_detail_panel_test.dart`
- `flutter analyze`

## Orden futuro

Esta versión prepara:

1. V3.3 Captura móvil directa: iPhone/iPad podrán crear tarjetas más completas porque el Mac ya sabe editarlas.
2. V3.4 Mapa mental/canvas: el canvas podrá representar nodos ricos, no solo tarjetas planas.

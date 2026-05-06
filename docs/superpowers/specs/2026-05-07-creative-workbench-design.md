# MUSA V3.1-V3.3: Mesa Creativa Por Libro

## Resumen

MUSA necesita una zona previa al manuscrito donde el autor pueda dejar ideas, bocetos, personajes incipientes, escenarios, imagenes, preguntas e investigacion sin convertirlos todavia en canon narrativo. La solucion sera una **Mesa creativa** por libro: una capa libre, ordenable y convertible que conecta la captura movil con el workspace editorial.

La Mesa creativa no sustituye a notas, personajes, escenarios ni documentos. Funciona como antesala: una tarjeta puede nacer como idea suelta, madurar en un tablero, vincularse con elementos existentes y convertirse despues en nota, personaje, escenario o documento.

## Objetivos

- Dar al autor un espacio rapido y flexible para organizar material creativo por libro.
- Mantener una experiencia cercana a una mesa de trabajo libre, con vista de tablero tipo Notion/Kanban.
- Preparar el modelo para capturas desde iPhone/iPad, links, imagenes y futuros mapas mentales.
- Permitir convertir tarjetas maduras en entidades reales del workspace.
- Evitar que ideas verdes contaminen memoria narrativa, continuidad, auditoria o estado de novela.

## No Objetivos Iniciales

- No crear un editor visual de mapa mental en V3.1.
- No llamar al modelo local para desarrollar ideas en V3.1.
- No convertir tarjetas automaticamente.
- No tratar tarjetas como canon narrativo hasta que el usuario las convierta o vincule explicitamente.
- No crear sincronizacion cloud propia; se mantiene la tesis local-first y se reutiliza el enfoque de captura/inbox existente.

## Fases

### V3.1: Mesa Creativa Mac

- Nueva seccion del libro activo: **Mesa creativa**.
- Tarjetas libres por libro.
- Vista tablero con columnas:
  - `Bandeja`
  - `Explorando`
  - `Prometedor`
  - `Para usar`
  - `Convertido`
  - `Archivado`
- Filtros por tipo.
- Panel de detalle para editar tarjeta.
- Adjuntos basicos: links e imagenes referenciadas.
- Conversiones a nota, personaje, escenario o documento/boceto.

### V3.2: Captura Movil

- iPhone/iPad pueden crear tarjetas para la Mesa creativa del libro.
- La bandeja de captura existente puede aceptar una captura como tarjeta creativa.
- Soporte de origen: manual, inbox, iPhone, iPad, importado.
- Imagenes y links entran como adjuntos de tarjeta.

### V3.3: Mapa Mental / Canvas

- Vista visual para conectar tarjetas entre si.
- Conexiones entre tarjetas y personajes, escenarios, documentos, notas e imagenes.
- Persistencia de posicion visual y relaciones.
- Pensado especialmente para iPad, sin bloquear la utilidad Mac.

## Modelo De Datos

Nuevo modulo recomendado:

```text
lib/modules/creative/
  models/
  providers/
  services/
```

Modelo principal:

```text
CreativeCard
```

Campos:

- `id`
- `bookId`
- `title`
- `body`
- `type`
- `status`
- `tags`
- `attachments`
- `source`
- `linkedCharacterIds`
- `linkedScenarioIds`
- `linkedDocumentIds`
- `linkedNoteIds`
- `convertedTo`
- `createdAt`
- `updatedAt`

Enums:

- `CreativeCardType`
  - `idea`
  - `sketch`
  - `character`
  - `scenario`
  - `image`
  - `research`
  - `question`
- `CreativeCardStatus`
  - `inbox`
  - `exploring`
  - `promising`
  - `readyToUse`
  - `converted`
  - `archived`
- `CreativeCardSource`
  - `manual`
  - `inbox`
  - `iphone`
  - `ipad`
  - `imported`
- `CreativeCardAttachmentKind`
  - `link`
  - `image`

`CreativeCardAttachment` debe guardar metadatos minimos: `id`, `kind`, `uri`, `title`, `createdAt`. Para V3.1 las imagenes pueden referenciar rutas locales o capturas aceptadas desde inbox; la gestion avanzada de ficheros queda reservada para V3.2.

`convertedTo` debe ser una referencia ligera con tipo de destino e id: nota, personaje, escenario o documento.

## Persistencia

Las tarjetas se guardaran dentro del workspace local `.musa`, asociadas a cada libro. La carga debe ser compatible con proyectos antiguos:

- Si el JSON no contiene tarjetas creativas, usar lista vacia.
- Si una tarjeta antigua no contiene campos nuevos, usar defaults seguros.
- Las tarjetas archivadas y convertidas permanecen en el proyecto salvo eliminacion explicita futura.

## Comportamiento

- Crear tarjeta rapida desde la Mesa creativa.
- Editar titulo, cuerpo, tipo, estado, tags y adjuntos.
- Mover tarjeta entre columnas.
- Archivar tarjeta.
- Vincular tarjeta con personajes, escenarios, documentos o notas existentes.
- Convertir tarjeta en:
  - nota del libro
  - personaje
  - escenario
  - documento `scratch`
- Marcar tarjeta como `converted` tras conversion y guardar referencia destino.
- Mantener la tarjeta visible en `Convertido` para trazabilidad.

Regla editorial:

Las tarjetas no alimentan `NarrativeMemory`, `StoryState`, continuidad, auditoria editorial ni direccion editorial hasta convertirse o hasta que exista una accion explicita futura de "usar en novela".

## Experiencia Mac

La seccion **Mesa creativa** debe aparecer como parte del libro activo.

Pantalla:

- Encabezado compacto con contador y accion "Nueva tarjeta".
- Tablero de columnas.
- Tarjetas compactas con tipo, titulo, extracto, tags e indicador de adjuntos.
- Filtros por tipo.
- Panel de detalle para editar sin navegar fuera de la mesa.

La interfaz debe sentirse como una mesa de escritor, no como una base de datos fria. El orden existe, pero la captura debe seguir siendo rapida.

## Experiencia iPhone/iPad

La primera implementacion Mac debe dejar el modelo preparado para movil:

- Las tarjetas aceptan `source`.
- Las tarjetas aceptan adjuntos.
- La bandeja de captura puede convertirse mas adelante en entrada directa a la Mesa creativa.

iPhone:

- Captura rapida de texto, link e imagen.
- Entrada por defecto en `Bandeja`.

iPad:

- Vista tablero con mas espacio.
- Base para V3.3: mapa mental/canvas.

## Inteligencia

V3.1 sera determinista y local:

- Sugerir tipo inicial por heuristica simple.
- Detectar posible duplicado por titulo parecido.
- Mantener todo revisable.

V3.2/V3.3 podran ampliar:

- "Desarrollar esta idea" con modelo local.
- "Relacionar con personajes/escenarios existentes".
- "Buscar ideas compatibles con la direccion editorial actual".
- "Convertir grupo de tarjetas en esquema de capitulo".
- Sugerir conexiones de mapa mental.

Ninguna inteligencia debe canonizar, convertir o aplicar cambios automaticamente.

## Integracion Con Modulos Existentes

- `notes`: conversion a nota y vinculos con notas existentes.
- `characters`: conversion a personaje y vinculos.
- `scenarios`: conversion a escenario y vinculos.
- `manuscript`: conversion a documento `scratch`.
- `inbox`: V3.2 aceptara capturas como tarjetas creativas.
- `books/workspace`: persistencia y operaciones en `NarrativeWorkspaceNotifier`.

La integracion debe ser minima y compatible con los patrones actuales de Riverpod, modelos inmutables y serializacion JSON local.

## Tests

Tests unitarios:

- Serializacion de `CreativeCard` y defaults compatibles.
- Crear tarjeta.
- Mover tarjeta entre estados.
- Archivar tarjeta.
- Adjuntos de link e imagen.
- Provider filtra tarjetas del libro activo.
- Conversion a nota.
- Conversion a personaje.
- Conversion a escenario.
- Conversion a documento `scratch`.
- Tarjetas no contaminan memoria narrativa antes de convertirse.

Tests de UI ligeros si encajan con patrones actuales:

- Vista vacia.
- Render de columnas.
- Seleccion de tarjeta y panel de detalle.

## Plan De Commits Previsto

1. Modelo + persistencia + tests.
2. Providers + operaciones del workspace.
3. Conversiones.
4. UI tablero Mac.
5. Captura movil/inbox hacia Mesa creativa.
6. Base para mapa mental/canvas.

Cada commit debe pasar verificacion relevante antes de subirse.

## Criterios De Aceptacion

- Un libro puede tener tarjetas creativas persistidas.
- Un proyecto `.musa` antiguo carga sin errores y sin tarjetas.
- El autor puede crear, editar, mover y archivar tarjetas.
- El autor puede convertir una tarjeta en nota, personaje, escenario o documento.
- Una tarjeta convertida queda enlazada al destino.
- La Mesa creativa no altera estado narrativo ni auditorias antes de conversion.
- La UI Mac muestra una experiencia de tablero por libro.
- El modelo queda preparado para captura movil y adjuntos.

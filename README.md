# MUSA

MUSA es una aplicación de escritura asistida por IA, local-first y orientada a proceso editorial. Está pensada como un estudio de escritura soberano: manuscrito, personajes, escenarios, notas, continuidad e inferencia conviven en una sola app de escritorio, con foco actual en macOS.

No es un simple editor con autocompletado. MUSA intenta actuar como una mesa de trabajo literaria donde el texto, el contexto narrativo y las intervenciones editoriales especializadas comparten el mismo espacio.

## Vista rápida

Capturas reales del estado actual de la app.

### Recorrido visual

![Recorrido visual de MUSA](docs/media/musa-tour.gif)

### Vista general

![Vista general de MUSA](docs/media/musa-overview.png)

### Editor narrativo

![Editor narrativo de MUSA](docs/media/musa-editor.png)

### Navegación lateral

![Navegación lateral de MUSA](docs/media/musa-sidebar.png)

### Inspector contextual

![Inspector contextual de MUSA](docs/media/musa-inspector.png)

## Qué aporta el proyecto

- Escritura asistida por IA local, sin depender de una API externa para el flujo principal.
- Arquitectura local-first con persistencia del workspace en disco.
- Organización narrativa por libro, capítulos, escenas, notas, personajes y escenarios.
- Musas especializadas para intervenir sobre estilo, claridad, ritmo y tensión.
- Análisis de fragmento y de capítulo para detectar foco narrativo, personajes, escenario y trayectoria.
- Herramientas de impresión/exportación editorial, incluyendo cuadernillo.
- Interfaz pensada para escritorio, con panel lateral, inspector contextual y overlays editoriales.

## Estado actual

El proyecto ya supera la fase de prototipo visual. Hay una base funcional clara en estos ejes:

- Onboarding con detección de hardware y selección de modelo local.
- Gestión de workspace narrativa persistida localmente.
- Edición de manuscrito y entidades narrativas.
- Flujo de sugerencias editoriales con IA embebida en macOS.
- Análisis heurístico del texto para continuidad y ayudas contextuales.
- Workflows editoriales estructurados para expandir momentos y conectar trama.
- Notas editoriales con estado, origen de capítulo y dirección reutilizable.
- Snapshots manuales ligeros del workspace.
- Focus mode visual y modo máquina de escribir.
- Impresión de capítulos y libro completo en PDF.

Todavía hay recorrido en robustez, packaging, testing automatizado y documentación operativa de producción.

## Principios del producto

### 1. Local-first

El workspace se guarda en disco y el modelo se instala en la máquina del autor. La propuesta de valor central es privacidad, latencia baja y control del entorno de escritura.

### 2. IA editorial, no IA invasiva

Las musas no están diseñadas para secuestrar la voz del autor, sino para intervenir con intención delimitada: aclarar, tensar, pulir o afinar el ritmo sin desbordar el fragmento.

### 3. Contexto narrativo persistente

Libro, continuidad, tono, personajes, escenarios y documentos forman parte del contexto de trabajo. Eso permite que la IA no opere a ciegas sobre un bloque aislado de texto.

### 4. Flujo de escritorio

La experiencia está concebida para sesiones largas de escritura y revisión, con navegación lateral, inspector, análisis de capítulo y herramientas de impresión.

## Público objetivo

MUSA encaja especialmente bien en estos perfiles:

- Novelistas que trabajan manuscritos largos y necesitan continuidad entre capítulos.
- Autores que quieren ayuda editorial sin mover el texto a la nube.
- Editores o coautores que necesitan revisar estructura, tono y consistencia.
- Escritura de ficción con un ecosistema de personajes, escenarios y tensión narrativa.

## Arquitectura de alto nivel

```mermaid
flowchart LR
    UI["UI Flutter Desktop"] --> State["Riverpod State + Notifiers"]
    State --> Workspace["Narrative Workspace"]
    Workspace --> Storage["Local Workspace Storage"]
    State --> Editor["Editor Controller"]
    Editor --> Analysis["Fragment / Chapter Analysis"]
    Editor --> Workflow["Editorial Workflow Notes"]
    Editor --> IA["IA Service"]
    IA --> Embedded["Embedded IA Service (macOS)"]
    Embedded --> Models["Model Manager + GGUF Models"]
    State --> Print["Print Service"]
    Workspace --> Snapshots["Manual Snapshots"]
```

## Flujo principal de producto

```mermaid
flowchart TD
    Start["Abrir MUSA"] --> Onboarding{"Onboarding completado?"}
    Onboarding -- No --> Detect["Detectar hardware"]
    Detect --> Pick["Elegir modelo recomendado"]
    Pick --> Download["Descargar e instalar modelo"]
    Download --> App["Entrar al estudio de escritura"]
    Onboarding -- Sí --> App
    App --> Book["Abrir libro activo"]
    Book --> Write["Escribir capítulo / escena / nota"]
    Write --> Analyze["Analizar fragmento o capítulo"]
    Analyze --> Decide["Resolver nextStep editorial"]
    Decide --> Workflow{"Acción estructurada?"}
    Workflow -- "expandMoment" --> Expand["Guardar dirección para expandir momento"]
    Workflow -- "connectToPlot" --> Plot["Guardar dirección para conectar trama"]
    Workflow -- "Musa" --> Invoke["Invocar Musa"]
    Expand --> Notes["Nota editorial con estado"]
    Plot --> Notes
    Invoke --> Review["Revisar sugerencia"]
    Review --> Persist["Persistir cambios en workspace local"]
    Notes --> Persist
```

## Estructura funcional

### Núcleo de escritura

- Manuscrito por documentos con soporte para capítulos, escenas y borradores.
- Edición centrada en texto, con overlay y panel de sugerencias.
- Revisión con propuesta generada, comparación y aceptación/rechazo.

### Contexto narrativo

- Libros con metadatos, sinopsis y notas de tono.
- Personajes vinculables a documentos.
- Escenarios vinculables a documentos.
- Notas y memorias de voz dentro del workspace.
- Estado de continuidad asociado al libro activo.
- Señales ligeras de continuidad por capítulo desde el inspector.
- Snapshots manuales para guardar estados del libro sin introducir versionado complejo.

### IA editorial

- Modelos locales descargables durante onboarding.
- Servicio IA embebido para macOS.
- Musas con reglas editoriales específicas.
- Flujo de sugerencias sobre selección o pasaje activo.

### Análisis automatizado

- Detección heurística de narrador.
- Detección de personajes y escenarios presentes en un fragmento.
- Análisis de capítulo por fragmentación interna.
- Resolución de momento dominante, función del capítulo y siguiente paso sugerido.
- Motor de `nextStep` con acciones estructuradas para `expandMoment` y `connectToPlot`.
- Filtro de ruido visible para evitar entidades no defendibles en la UI.

### Workflows editoriales

- `expandMoment`: convierte una recomendación de desarrollo de escena en una nota estructural con dirección elegida.
- `connectToPlot`: permite conectar un capítulo con símbolo, consecuencia o personaje.
- Cada dirección queda persistida como nota editorial con origen, estado y tipo de workflow.
- Las notas pueden abrirse desde el inspector y marcarse como usadas o descartadas.

### Salida editorial

- Impresión de capítulo.
- Impresión de libro completo.
- Generación de cuadernillo para revisión o lectura física.

## Las musas actuales

MUSA define cuatro perfiles editoriales principales:

- `Musa de Estilo`: mejora cadencia, precisión léxica y elegancia verbal.
- `Musa de Tensión`: intensifica fricción dramática y amenaza implícita.
- `Musa de Ritmo`: reorganiza respiración, pausas y flujo del texto.
- `Musa de Claridad`: elimina ambigüedad innecesaria sin aplanar la voz.

Cada musa incorpora:

- intención editorial explícita,
- reglas de intervención,
- recordatorio de alcance,
- límite de expansión del pasaje,
- mensajes de thinking/streaming para el panel de revisión.

## Módulos principales del código

### App shell

- `lib/main.dart`
- `lib/ui/layout/main_screen.dart`
- `lib/ui/widgets/sidebar.dart`
- `lib/ui/widgets/inspector.dart`

### Dominio editorial y workspace

- `lib/modules/books/`
- `lib/modules/manuscript/`
- `lib/modules/characters/`
- `lib/modules/scenarios/`
- `lib/modules/notes/`
- `lib/shared/storage/local_workspace_storage.dart`

### Editor e inferencia

- `lib/editor/controller/editor_controller.dart`
- `lib/editor/services/fragment_analysis_service.dart`
- `lib/editor/services/chapter_analysis_service.dart`
- `lib/editor/widgets/suggestion_review_panel.dart`
- `lib/editor/widgets/chapter_insight_panel.dart`

### IA local

- `lib/services/ia_providers.dart`
- `lib/services/ia/embedded/`
- `lib/services/ia/embedded/management/model_manager.dart`
- `lib/services/ia/embedded/management/model_catalog.dart`

### Impresión

- `lib/services/print/print_service.dart`

### Shell adaptativo y documentación interna

- `lib/app/adaptive/`
- `lib/app/shells/desktop/`
- `lib/app/shells/ipad/`
- `lib/app/shells/iphone/`
- `docs/codebase_overview.md`
- `docs/mobile_adaptive_architecture.md`
- `docs/mobile_ipad_foundation_plan.md`
- `docs/ipad_compose_phase2_plan.md`

## Persistencia local

El workspace narrativo se guarda como un único documento de proyecto `.musa`
en el directorio de soporte de la aplicación. El documento es un contenedor
opaco y versionado para que el usuario no pueda borrar partes internas del
proyecto por accidente:

- archivo principal: `Musa.musa`
- ubicación base: `Application Support/musa/`

Las instalaciones con el formato anterior se migran automáticamente desde
`musa_workspace.json` al abrir la app.

El sistema genera un workspace semilla si no existe ninguno, con:

- un libro inicial,
- un capítulo de apertura,
- un estado base de continuidad,
- perfiles de musas,
- un perfil de modelo inicial.

Las notas estructurales y los snapshots se guardan dentro del mismo workspace local. Los snapshots son copias manuales ligeras: no hay branching, merge ni versionado complejo.

## Requisitos de desarrollo

### Entorno

- macOS
- Flutter SDK compatible con `>=3.3.0 <4.0.0`
- Xcode y toolchain para `flutter run -d macos`
- Homebrew recomendado para utilidades auxiliares

### Dependencias relevantes

- `flutter_riverpod`
- `google_fonts`
- `path_provider`
- `ffi`
- `printing`
- `pdf`

## Puesta en marcha

### 1. Obtener dependencias

```bash
flutter pub get
```

### 2. Ejecutar en macOS

```bash
flutter run -d macos
```

### 3. Ejecutar tests

```bash
flutter test
```

### 4. Analizar el proyecto

```bash
flutter analyze
```

## Manual de uso

### Primera apertura

1. Abre la app.
2. Completa el onboarding.
3. Deja que MUSA detecte el hardware del Mac.
4. Acepta el modelo recomendado o cambia a modo avanzado.
5. Descarga e instala el modelo local.
6. Entra al estudio de escritura.

### Flujo básico de escritura

1. Selecciona el libro activo desde la barra lateral.
2. Abre un capítulo o crea uno nuevo.
3. Escribe directamente en el editor.
4. Usa el inspector para enriquecer sinopsis, tono, personajes y escenarios vinculados.
5. Invoca una musa sobre el fragmento que quieras revisar.
6. Si el análisis propone `expandMoment` o `connectToPlot`, abre la dirección editorial y guárdala como nota.
7. Compara la sugerencia y decide si aceptarla o descartarla.

### Gestión de contexto narrativo

1. Crea o selecciona un libro.
2. Define sinopsis y notas de tono.
3. Añade personajes.
4. Añade escenarios.
5. Vincula personajes y escenarios a capítulos o escenas.
6. Revisa la continuidad desde el panel derecho.
7. Atiende las señales ligeras del inspector cuando una entidad pesa en el capítulo pero no está vinculada.

### Workflows editoriales

1. Analiza un capítulo.
2. Revisa el `nextStep` propuesto.
3. Abre la acción estructurada cuando sea `expandMoment` o `connectToPlot`.
4. Elige una dirección editorial.
5. MUSA crea una nota estructural vinculada al capítulo.
6. Desde el inspector puedes abrirla, marcarla como usada o descartarla.

### Snapshots

1. Abre la vista del libro.
2. En el inspector, usa `Guardar` dentro de `Snapshots`.
3. Sigue escribiendo sin miedo a perder el estado anterior.
4. Restaura un snapshot si quieres volver a una versión guardada.

### Impresión editorial

1. Abre un capítulo con contenido o el libro activo.
2. Lanza la acción de imprimir.
3. Elige entre impresión normal o cuadernillo según el flujo disponible.
4. Revisa el PDF generado desde el diálogo de impresión del sistema.

## Casos de uso reales

### Caso 1. Reescritura estilística de un pasaje

Un autor tiene un párrafo funcional pero sin brillo. Selecciona el fragmento, invoca `Musa de Estilo` y revisa una propuesta más precisa sin perder intención narrativa.

### Caso 2. Ajuste de tensión en una escena plana

Una escena transmite información pero no sostiene la atención. `Musa de Tensión` interviene sobre el pasaje para introducir fricción, amenaza implícita y mejor pulso dramático.

### Caso 3. Revisión de claridad antes de compartir

Antes de enviar un capítulo a lectores cero, el autor usa `Musa de Claridad` para despejar ambigüedades innecesarias y mejorar comprensión sin simplificar en exceso.

### Caso 4. Construcción de biblia narrativa

Durante el desarrollo de una novela, el autor mantiene personajes, escenarios y notas vinculados al manuscrito para evitar contradicciones y conservar tono y relaciones.

### Caso 5. Revisión física en papel

Cuando el manuscrito necesita otra lectura, el autor imprime capítulo o cuadernillo para revisarlo fuera de pantalla con una maquetación legible.

### Caso 6. Dirección editorial persistente

El análisis detecta que un capítulo necesita desarrollar un momento o conectarse mejor con la trama. El autor elige una dirección en el sheet y MUSA la guarda como nota estructural, reutilizable y marcable como usada o descartada.

### Caso 7. Escritura sin miedo

Antes de una reescritura fuerte, el autor guarda un snapshot manual del libro. Puede probar cambios y restaurar el estado anterior si la dirección no funciona.

## Diferenciadores frente a un editor genérico con IA

- El contexto narrativo no es accesorio; forma parte del modelo mental de la app.
- La IA trabaja con perfiles editoriales concretos, no con prompts genéricos opacos.
- El almacenamiento local y la instalación del modelo son parte explícita del producto.
- La continuidad, el capítulo y el fragmento tienen herramientas de análisis propias.
- Los `nextStep` importantes se convierten en acciones estructuradas, no solo consejos.
- Las notas funcionan como sistema vivo de trabajo editorial.
- La salida editorial incluye impresión, no solo edición en pantalla.

## Limitaciones actuales

- El target principal hoy es macOS; ya existe base de arquitectura adaptativa para iPad/iPhone, pero no equivale todavía a una distribución final móvil.
- La robustez del motor IA depende del modelo instalado y del hardware disponible.
- El análisis narrativo actual es mayoritariamente heurístico; no sustituye lectura editorial humana.
- La continuidad actual es light: señala actividad y vínculos básicos, no contradicciones globales profundas.
- Faltan más tests de integración y validación de regresiones en flujos complejos.
- El README documenta el estado observable del código, no una distribución empaquetada para usuarios finales.

## Próximas features sugeridas

### Producto

- Biblioteca de proyectos con apertura reciente y archivado.
- Historial editorial más profundo sobre los snapshots actuales.
- Exportación adicional a formatos editoriales más allá de impresión.
- Panel de continuidad más profundo con conflictos abiertos y alertas cross-capítulo.
- Modo de revisión por escenas, no solo por capítulo.

### IA

- Selección manual y benchmarking de modelos desde ajustes.
- Pipeline multi-musa con estrategias combinadas.
- Memoria editorial persistente por libro y por personaje.
- Análisis de arco de personaje y evolución de tensión a nivel de libro.
- Detección de contradicciones entre capítulos.

### Operación técnica

- Mejor cobertura de tests.
- CI estable para análisis, test y build de macOS.
- Empaquetado reproducible para distribución interna.
- Telemetría local opcional para rendimiento y fallos.

## Roadmap recomendado

```mermaid
timeline
    title Roadmap propuesto de MUSA
    Q2 2026 : cerrar motor editorial y workflows
            : mejorar tests y CI
            : refinar README y docs internas
    Q3 2026 : profundizar snapshots
            : análisis de continuidad cross-capítulo
            : exportación editorial mejorada
    Q4 2026 : multi-proyecto
            : configuración avanzada de modelos
            : mayor profundidad en inteligencia narrativa
```

## Estrategia técnica recomendada

Si el objetivo es llevar MUSA a una versión sólida de uso diario, el orden lógico sería:

1. Blindar persistencia, tests y estabilidad del flujo editor.
2. Consolidar el motor IA local y su gestión de modelos.
3. Profundizar el sistema de continuidad y análisis narrativo.
4. Mejorar distribución, empaquetado y documentación para usuarios no técnicos.

## Para contribuir

Antes de tocar arquitectura o añadir features nuevas, conviene revisar:

- shell de la app y layout principal,
- notifiers del workspace,
- controller del editor,
- servicios de análisis,
- gestión de modelos locales.

Flujo recomendado:

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. validar manualmente en `macos`

### Changelog

Cada cambio relevante de producto, arquitectura, documentación o flujo de desarrollo debe actualizar [`CHANGELOG.md`](./CHANGELOG.md) antes de hacer commit.

Regla práctica:

1. documentar primero en `Unreleased`,
2. mover a una fecha o versión cuando se prepare una entrega,
3. omitir solo cambios triviales que no alteren comportamiento, contrato público ni documentación útil.

## Referencias rápidas

- Entrada principal: [`lib/main.dart`](./lib/main.dart)
- Layout principal: [`lib/ui/layout/main_screen.dart`](./lib/ui/layout/main_screen.dart)
- Persistencia local: [`lib/shared/storage/local_workspace_storage.dart`](./lib/shared/storage/local_workspace_storage.dart)
- Controlador del editor: [`lib/editor/controller/editor_controller.dart`](./lib/editor/controller/editor_controller.dart)
- Workflows de capítulo: [`lib/editor/widgets/chapter_insight_panel.dart`](./lib/editor/widgets/chapter_insight_panel.dart)
- Snapshots: [`lib/modules/books/models/workspace_snapshot.dart`](./lib/modules/books/models/workspace_snapshot.dart)
- Modelos locales: [`lib/services/ia/embedded/management/model_manager.dart`](./lib/services/ia/embedded/management/model_manager.dart)
- Impresión: [`lib/services/print/print_service.dart`](./lib/services/print/print_service.dart)
- Arquitectura adaptativa: [`docs/mobile_adaptive_architecture.md`](./docs/mobile_adaptive_architecture.md)

## Resumen

MUSA ya tiene una identidad clara: no quiere competir como un editor genérico, sino como una herramienta editorial local, sobria y especializada para narrativa. El valor del proyecto está en unir manuscrito, contexto narrativo e IA de asistencia dentro de un flujo de escritorio serio.

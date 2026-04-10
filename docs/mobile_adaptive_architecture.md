# MUSA Adaptive Architecture

Fecha: 2026-04-10

## Principio rector

MUSA debe evolucionar como una plataforma editorial con un núcleo narrativo único y shells distintos por contexto de uso:

- iPhone: captura y escritura ligera
- iPad: composición y revisión con más contexto
- Desktop: estudio completo

No se organiza solo “por plataforma”. Se organiza por responsabilidades:

- `core`: tema, constantes, utilidades y contratos base
- `features`: bibliotecas, documento activo, entidades narrativas, editor, continuidad
- `shells`: experiencia y navegación por tipo de herramienta
- `platform adaptations`: resolución adaptativa y políticas de layout

## Organización propuesta

```text
lib/
  app/
    adaptive/
      adaptive_spec.dart
      adaptive_providers.dart
      adaptive_router.dart
    shells/
      desktop/
      ipad/
      iphone/
    features/
      workspace/
        presentation/
          screens/
          widgets/
  core/
  editor/
  modules/
  services/
  shared/
  ui/                 # legacy desktop UI, se mantiene viva en esta fase
```

## Reparto de responsabilidades

### Core compartido

Debe seguir alojando:

- tema visual y tokens
- constantes editoriales globales
- contratos base
- utilidades estables

No debe alojar:

- navegación de shell
- breakpoints concretos de producto
- políticas de paneles dependientes de dispositivo

### Features

Debe alojar:

- pantallas y widgets reutilizables de biblioteca/workspace
- documento activo
- componentes editoriales comunes a shells

Estas piezas deben consumir estado del workspace y no asumir sidebar/inspector desktop.

### Shells / tools

Debe alojar:

- `DesktopStudioShell`
- `ComposeToolShell` para iPad
- `CaptureToolShell` para iPhone

El shell decide:

- estructura primaria de navegación
- densidad de chrome
- composición de paneles
- prioridades de foco

### Platform adaptations

Debe alojar:

- breakpoints semánticos
- `window class`
- `device class`
- `navigation policy`
- `scaffold policy`
- reglas de paneles
- reglas de inspector
- reglas de densidad editorial
- resolver de shell

## Dónde debe vivir cada cosa

### Navegación adaptativa

En `lib/app/adaptive/`.

Motivo:

- depende del contexto de ventana y del shell, no del dominio.

### Breakpoints

En `lib/app/adaptive/adaptive_spec.dart`.

Motivo:

- deben ser semánticos y centralizados.

### Layout policies

En `lib/app/adaptive/adaptive_spec.dart`.

Ejemplos:

- cuándo usar sidebar
- cuándo usar split
- cuándo mostrar inspector
- qué densidad usa el editor

### Tool mode resolver

En `lib/app/adaptive/adaptive_router.dart`.

Entrada:

- plataforma/idioma de host
- `MediaQuery`
- constraints de ventana

Salida:

- shell concreto a renderizar

## Contrato adaptativo propuesto

### Window class

- `compact`: iPhone
- `medium`: iPad portrait, iPad split, ventanas intermedias
- `expanded`: iPad grande, desktop, futuro spatial canvas reducido a vista 2D amplia

### Device class

- `phone`
- `tablet`
- `desktop`

### Shell kind

- `capture`
- `compose`
- `studio`

### Navigation policy

Define:

- `bottomBar`
- `sidebar`
- `splitSidebar`

### Adaptive scaffold policy

Define:

- padding principal
- anchura máxima de contenido
- uso de split
- si el inspector se integra como panel persistente, secundario o modal

### Panel availability rules

Define:

- biblioteca persistente o navegada
- inspector persistente o invocable
- contexto secundario visible o no

### Inspector visibility rules

Define:

- oculto en `compact`
- seleccionable o modal en `medium`
- persistente cuando hay espacio en `expanded` no-phone

### Editor density rules

Define:

- `comfortable` para iPhone
- `balanced` para iPad
- `immersive` para desktop

## Implementación incremental recomendada

### Fase inicial

- mantener `ui/` como desktop legacy shell
- introducir `app/adaptive/`
- introducir `app/shells/`
- crear pantallas base compartidas de workspace y documento

### Fase posterior

- mover piezas reutilizables de `ui/` a `app/features/`
- modularizar `workspace_providers.dart`
- abstraer capacidades IA/model runtime por plataforma

## Decisiones aplicadas en esta fase

1. Desktop se conserva intacto y se envuelve como shell.
2. iPhone e iPad usan navegación distinta.
3. El router se basa en plataforma + clase semántica de ventana.
4. Las políticas adaptativas se encapsulan en un contrato reusable y no en `if` sueltos por widget.
5. La UI inicial será sobria y funcional, no una maqueta genérica.

## Resultado esperado

Al finalizar esta fase, el repo debe quedar preparado para:

- seguir desarrollando desktop sin regresiones
- crecer en iPhone como herramienta de captura
- crecer en iPad como herramienta de composición
- añadir futuras herramientas de plataforma sin duplicar dominio ni persistencia

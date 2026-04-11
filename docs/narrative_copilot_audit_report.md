# Auditoría manual V1.2 del copiloto narrativo

Fecha: 2026-04-11

## Muestra

- Workspace auditado: `musa_workspace.json` del contenedor local de MUSA.
- Corpus real disponible: 2 libros, 15 documentos con contenido, todos marcados como `chapter`.
- Límite importante: el ADN narrativo persistido estaba vacío (`narrativeProfile: null`) en los dos libros. Para obtener una lectura editorial útil hice una pasada no persistente con perfiles asumidos y una segunda pasada de estrés por género.
- Total auditado: 30 outputs.

Distribución:

- 15 outputs con perfil asumido.
- 15 outputs de estrés por género sobre texto real.
- Géneros: mystery/material de investigación, thriller, science fiction, fantasy.

## Resultado global

| Dictamen | Cantidad | Lectura |
| --- | ---: | --- |
| Útil | 2 | Ayuda a tomar una decisión clara de escritura. |
| Correcto pero flojo | 15 | Dice algo defendible, pero poco específico o repetido. |
| Incorrecto | 13 | Falso positivo por tipo de documento, género o estructura. |

## Patrones detectados

### 1. Repetición excesiva

Movimiento más repetido:

- 14/30: `Rompe la cadena de investigación: la próxima pista debe obligar a elegir, perder algo o exponerse.`
- 10/30: `Cierra o transforma una pregunta abierta antes de plantar otra.`

Lectura: la herramienta se apoya demasiado en dos rutas de salida. Cuando el texto es material de investigación o contiene vocabulario de búsqueda, la recomendación se vuelve predecible.

### 2. Falso positivo por documentos de apoyo

El libro `Investigaciones` contiene material documental útil para `El ojo invisible`, pero los documentos están marcados como `chapter`. El copiloto los lee como capítulos narrativos y penaliza “progreso real” o detecta bucles de investigación donde en realidad hay documentación.

Error dominante: estructura/tipo de documento.

### 3. Motivo útil, pero a veces demasiado genérico

Los motivos funcionan cuando explican una señal concreta:

- `Detecto varias búsquedas y pistas seguidas sin una consecuencia proporcional.`

Pero pierden valor cuando repiten una condición general:

- `Hay demasiadas preguntas abiertas compitiendo por la atención.`

Lectura: el motivo aporta, pero necesita apuntar a la evidencia o al tipo de carencia, no solo repetir la categoría.

### 4. Sobreafirmación en stress tests de género

Al forzar sci-fi o fantasy sobre capítulos que no pertenecen a esos géneros, aparecen diagnósticos plausibles pero débiles. Ejemplo: una escena de investigación digital puede activar “sistema” y “reglas” aunque no sea sci-fi.

Error dominante: género.

### 5. Tensión de thriller razonable, pero poco graduada

En `El ojo invisible`, el consejo de presión funciona mejor en capítulos claramente narrativos. Aun así, la salida cae pronto en `preguntas abiertas` y se repite durante varios capítulos.

Error dominante: estructura/priorización.

## Clasificación de los 30 outputs

| # | Modo | Libro | Capítulo | Género | Dictamen | Error principal | Nota editorial |
| ---: | --- | --- | --- | --- | --- | --- | --- |
| 1 | perfil asumido | Investigaciones | Investigación digital realista (OSINT suave) | mystery | Correcto pero flojo | estructura | Detecta que no hay avance narrativo, pero el documento es material de apoyo. |
| 2 | perfil asumido | Investigaciones | Documento de investigación digital realista | mystery | Correcto pero flojo | estructura | Misma lectura: útil si fuera capítulo, floja para documentación. |
| 3 | perfil asumido | Investigaciones | Psicología de la obsesión | mystery | Incorrecto | estructura | Falso positivo de investigación/pista en documento expositivo. |
| 4 | perfil asumido | Investigaciones | Psicología de la obsesión | mystery | Incorrecto | estructura | Repite el falso positivo. |
| 5 | perfil asumido | Investigaciones | Patrones, símbolos, coincidencias... | mystery | Incorrecto | estructura | Vocabulario de investigación leído como bucle narrativo. |
| 6 | perfil asumido | Investigaciones | Símbolos conspirativos... | mystery | Incorrecto | estructura | Penaliza documentación como si fuera escena. |
| 7 | perfil asumido | Investigaciones | Cómo construir un culto creíble... | mystery | Incorrecto | estructura | Diagnóstico narrativo sobre material de worldbuilding/investigación. |
| 8 | perfil asumido | El ojo invisible | El callejón | thriller | Útil | ninguno fuerte | “Falta presión directa” es defendible para apertura con atmósfera e investigación inicial. |
| 9 | perfil asumido | El ojo invisible | Café frio y teclas calientes | thriller | Correcto pero flojo | repetición | “Preguntas abiertas” puede tener sentido, pero falta precisión sobre cuál pesa. |
| 10 | perfil asumido | El ojo invisible | Garabatos en la sombra | thriller | Correcto pero flojo | repetición | Mismo consejo; empieza a sonar genérico. |
| 11 | perfil asumido | El ojo invisible | Busquedas sin voz | thriller | Correcto pero flojo | repetición | La recomendación no distingue suficientemente el capítulo. |
| 12 | perfil asumido | El ojo invisible | Ecos en la red | thriller | Correcto pero flojo | repetición | Sigue priorizando preguntas abiertas. |
| 13 | perfil asumido | El ojo invisible | El mapa y la noche | thriller | Correcto pero flojo | repetición | Defendible, pero poco accionable sin señalar pregunta concreta. |
| 14 | perfil asumido | El ojo invisible | El callejón de Tenderloin | thriller | Útil | ninguno fuerte | El bucle investigación/pista parece aplicable y el consejo empuja a consecuencia. |
| 15 | perfil asumido | El ojo invisible | prueba | thriller | Incorrecto | estructura | Documento de entrevista técnica leído como capítulo narrativo. |
| 16 | stress thriller | Investigaciones | Investigación digital realista (OSINT suave) | thriller | Correcto pero flojo | género | Como stress test, marca falta de presión; el texto real no es thriller narrativo. |
| 17 | stress scienceFiction | Investigaciones | Documento de investigación digital realista | science fiction | Incorrecto | género | “Explicación aporta” se activa por vocabulario de sistemas/proceso. |
| 18 | stress fantasy | Investigaciones | Psicología de la obsesión | fantasy | Incorrecto | género | Mezcla falso positivo de bucle con fantasy no pertinente. |
| 19 | stress thriller | Investigaciones | Psicología de la obsesión | thriller | Correcto pero flojo | estructura | Puede servir como stress test, pero sigue leyendo documentación como escena. |
| 20 | stress scienceFiction | Investigaciones | Patrones, símbolos... | science fiction | Incorrecto | estructura | Falso positivo de bucle de investigación. |
| 21 | stress fantasy | Investigaciones | Símbolos conspirativos... | fantasy | Incorrecto | género | Aplica fantasy a material documental. |
| 22 | stress thriller | Investigaciones | Cómo construir un culto creíble... | thriller | Incorrecto | estructura | Detecta investigación/pista en guía de construcción narrativa. |
| 23 | stress scienceFiction | El ojo invisible | El callejón | science fiction | Correcto pero flojo | género | Correcto como stress: no hay sistema sci-fi, pero no aporta mucho. |
| 24 | stress fantasy | El ojo invisible | Café frio y teclas calientes | fantasy | Correcto pero flojo | repetición | Preguntas abiertas otra vez; género no modifica de forma útil. |
| 25 | stress thriller | El ojo invisible | Garabatos en la sombra | thriller | Correcto pero flojo | repetición | Repite patrón de preguntas abiertas. |
| 26 | stress scienceFiction | El ojo invisible | Busquedas sin voz | science fiction | Incorrecto | género | “Explicación aporta” parece activarse por investigación/red, no por sci-fi real. |
| 27 | stress fantasy | El ojo invisible | Ecos en la red | fantasy | Correcto pero flojo | repetición | No sobreafirma fantasy, pero repite preguntas abiertas. |
| 28 | stress thriller | El ojo invisible | El mapa y la noche | thriller | Correcto pero flojo | repetición | Consejo plausible, poco específico. |
| 29 | stress scienceFiction | El ojo invisible | El callejón de Tenderloin | science fiction | Correcto pero flojo | género | Detecta bucle útil, aunque el género forzado no aporta. |
| 30 | stress fantasy | El ojo invisible | prueba | fantasy | Incorrecto | estructura | Documento técnico leído como capítulo. |

## Conclusión editorial

La V1.2 ya tiene una voz usable y los motivos no son decoración, pero el sistema todavía falla fuerte cuando el workspace mezcla investigación, notas o documentos técnicos dentro de `DocumentKind.chapter`.

El problema más frecuente no es el copy. Es la clasificación estructural del material de entrada.

Prioridad recomendada:

1. Separar o detectar material de apoyo antes de calcular `StoryState`.
2. Rebajar prioridad de `openQuestions.length > 4` para que no tape consejos más concretos.
3. Hacer que el motivo cite una evidencia más específica cuando recomiende “preguntas abiertas”.
4. Mantener `Motivo:` en una sola línea; no ampliar explicación todavía.

## Recomendación V1.3

No pasar aún a generación. Antes conviene introducir una señal ligera de tipo de documento:

- `manuscriptScene`
- `researchNote`
- `worldbuildingNote`
- `technicalNote`

No necesariamente como modelo público todavía; puede empezar como clasificador heurístico interno del copiloto. El objetivo es evitar que una guía OSINT o un documento de entrevista técnica contamine el estado narrativo del libro.

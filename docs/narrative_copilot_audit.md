# Auditoría editorial del copiloto narrativo

Objetivo: revisar 20-30 salidas reales del copiloto como editor, no como programador.

## Muestra

- 8-10 salidas de thriller.
- 8-10 salidas de ciencia ficción.
- 8-10 salidas de fantasía.
- Incluir capítulos útiles, flojos, ambiguos y atmosféricos.

## Registro

| Libro | Género | Capítulo | Movimiento | Motivo | Dictamen | Nota editorial |
| --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  | útil / correcto pero flojo / incorrecto / repetitivo |  |

## Preguntas de lectura

- ¿La recomendación ayuda a tomar una decisión de escritura?
- ¿El motivo justifica de verdad la recomendación?
- ¿La lectura cambia según el género o suena igual en todos?
- ¿La frase es firme y breve, o suena genérica?
- ¿Hay falso positivo por palabra clave sin función narrativa?

## Señales de fallo

- Detecta atmósfera fantasy como progreso sin deuda, destino, amenaza ni decisión.
- Perdona exposición sci-fi sin coste, regla nueva ni margen de acción cambiado.
- Convierte cualquier pausa en fallo de tensión, incluso cuando el género la permite.
- Repite siempre una variante de "sube la tensión".
- El motivo explica una palabra detectada, pero no una función narrativa.

## Criterio para V1.2

- Mantener una línea de movimiento y una línea de motivo.
- Ajustar heurísticas solo cuando reduzcan falsos positivos claros.
- No añadir campos nuevos al `StoryState` salvo que una carencia se repita en varios casos reales.

# Auditoria Manual V1.5 del Copiloto Narrativo

Fecha: 2026-04-12

## Resumen ejecutivo

La V1.5 ya intenta usar memoria contextual en escenas, pero en la muestra real el uso actual no esta aportando valor editorial: 18/18 casos activaron `systemConstraints` con el mismo fragmento conversacional ("Depende de quien lo mire"), que no funciona como restriccion narrativa operativa.  
No se observaron caidas al fallback en los casos auditados con perfil narrativo activo; esto sugiere sobreactivacion del match contextual.

## Muestra

- Workspace auditado: `musa_workspace.json` local de MUSA.
- Documentos con contenido: 15.
- Clasificados fuera de alcance por tipo no escena: 9 (`research/worldbuilding/technical/unknown`).
- Escenas reales disponibles: 6 (`El ojo invisible`).
- Para llegar a 12-20 casos sin inventar texto, se auditaron las 6 escenas en 3 perfiles narrativos (thriller, scienceFiction, fantasy): total 18 casos.

## Tabla de casos

| # | Libro | Documento | Tipo clasificado | Bucket | Movimiento | Motivo | Dictamen | Nota editorial breve |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | El ojo invisible | El callejon (thriller) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | Match lexico superficial; no es restriccion del sistema. |
| 2 | El ojo invisible | El callejon (scienceFiction) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | Repite la misma frase sin accion concreta nueva. |
| 3 | El ojo invisible | El callejon (fantasy) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | No hay relacion causal fuerte con la escena. |
| 4 | El ojo invisible | Cafe frio y teclas calientes (thriller) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | Deberia empujar presion del caso, no una linea dialogada suelta. |
| 5 | El ojo invisible | Cafe frio y teclas calientes (scienceFiction) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | No mejora accionabilidad frente al fallback. |
| 6 | El ojo invisible | Cafe frio y teclas calientes (fantasy) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | Contexto aplicado por forma, no por funcion narrativa. |
| 7 | El ojo invisible | Garabatos en la sombra (thriller) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | Recomendacion estancada; no distingue escena. |
| 8 | El ojo invisible | Garabatos en la sombra (scienceFiction) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | El motivo no justifica por que aplica aqui. |
| 9 | El ojo invisible | Garabatos en la sombra (fantasy) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | Sobreuso del mismo contexto sin validar relevancia. |
| 10 | El ojo invisible | Busquedas sin voz (thriller) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | Hay tension posible del caso; no se aprovecha. |
| 11 | El ojo invisible | Busquedas sin voz (scienceFiction) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | Match de palabras, no match narrativo real. |
| 12 | El ojo invisible | Busquedas sin voz (fantasy) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | No hay restriccion operacional explicita. |
| 13 | El ojo invisible | Ecos en la red (thriller) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | Consejo repetido; pierde utilidad editorial. |
| 14 | El ojo invisible | Ecos en la red (scienceFiction) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | Mismo problema de sobreafirmacion contextual. |
| 15 | El ojo invisible | Ecos en la red (fantasy) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | No concreta coste, limite ni obligacion real. |
| 16 | El ojo invisible | El mapa y la noche (thriller) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | No diferencia cierre de arco frente a escenas previas. |
| 17 | El ojo invisible | El mapa y la noche (scienceFiction) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | El motivo acompana, pero no demuestra aplicabilidad. |
| 18 | El ojo invisible | El mapa y la noche (fantasy) | scene | systemConstraints | Usa la restriccion "Depende de quien lo mire"... | Comparte vocabulario con restriccion guardada | uso incorrecto del contexto | Repeticion total del mismo disparador contextual. |

## Metricas finales

- Total auditado: 18 escenas (reales) + 9 documentos excluidos por no ser escena.
- Dictamen:
- especifica por contexto: 0
- correcta pero generica: 0
- fallback adecuado: 0
- uso incorrecto del contexto: 18
- Distribucion por bucket:
- systemConstraints: 18
- worldRules: 0
- researchFindings: 0
- persistentConcepts: 0
- fallback: 0

## Hallazgos obligatorios

- Bucket con mas valor real observado:
- ninguno en esta muestra; no hubo casos claramente especificos por contexto.
- Bucket con mas ruido:
- `systemConstraints` (18/18), por falso positivo de overlap superficial.
- `persistentConcepts` funcionando o cajon desastre:
- en esta muestra no se activo; no hay evidencia para validarlo.
- Falsos positivos por overlap superficial:
- altos. El sistema reutiliza una frase dialogada corta ("Depende de quien lo mire") como si fuera restriccion persistente.
- Escenas que deberian usar contexto y aun caen a fallback:
- no se observaron en este corte porque no hubo fallback con perfil narrativo activo; hay senal de sobreuso contextual.
- El motivo mejora o solo acompana:
- solo acompana. El motivo es consistente con el bucket, pero no justifica relevancia narrativa real en la escena concreta.

## Recomendacion V1.6 minima

Aplicar una compuerta de calidad antes de aceptar contexto en `NextBestMove`:

1. Solo permitir `systemConstraints/worldRules` si el item contextual contiene un marcador estructural fuerte (`regla`, `limite`, `coste`, `obliga`, `prohibe`, `restriccion`) y no es cita dialogada corta.
2. Si no pasa esa compuerta, forzar fallback normal en lugar de contexto.
3. Mantener trazabilidad breve indicando cuando se descarta contexto por baja confianza.

Impacto esperado:
- reduce falsos positivos de contexto con cambio pequeno,
- recupera fallback digno cuando no hay match narrativo real,
- mejora utilidad editorial sin ampliar arquitectura.

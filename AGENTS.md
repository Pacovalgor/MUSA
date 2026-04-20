# AGENTS

Este repositorio sigue el contrato operativo definido en `ai/PROJECT_AGENT.md`.

## Prioridades
1. Aplicar cambio mínimo correcto
2. Cargar y respetar el perfil en `ai/memory/PROJECT_PROFILE.yaml`
3. Usar skills de `ai/skills/`
4. Consultar memoria estable en `ai/memory/PROJECT_MEMORY.md`
5. No salir del scope pedido
6. No afirmar verificación no ejecutada

## Secuencia por defecto
- `perfilar` si no hay perfil o el repo cambió de forma relevante
- `explorar`
- `acotar`
- skill de ejecución
- `verificar`
- `resumir`
- `guardar`

## Nota
Si hay conflicto entre una orden del usuario y una convención histórica del proyecto, priorizar la orden explícita del usuario salvo que rompa una restricción técnica, de seguridad o una regla arquitectónica crítica ya asentada.

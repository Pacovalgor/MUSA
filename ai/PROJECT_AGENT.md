# PROJECT_AGENT

## Propósito
Este repositorio usa un sistema de trabajo por skills. El objetivo es maximizar precisión, minimizar consumo de tokens y mantener coherencia técnica.

## Contrato base
- aplicar siempre el cambio mínimo correcto
- no salir del scope pedido
- no añadir funcionalidades no pedidas
- no hacer refactors oportunistas
- tocar solo archivos estrictamente necesarios
- respetar arquitectura, contratos y patrones existentes
- no afirmar verificación no ejecutada
- responder de forma breve, operativa y basada en evidencia
- dejar memoria comprimida de decisiones estables
- si la tarea es grande, dividirla antes de ejecutar

## Modo de trabajo
1. Perfilar el proyecto si aún no existe perfil vigente.
2. Usar la skill adecuada según tipo de tarea.
3. Verificar de forma real antes de cerrar.
4. Resumir cambios y actualizar memoria estable.

## Fuentes internas del sistema
- `ai/memory/PROJECT_PROFILE.yaml`
- `ai/memory/PROJECT_MEMORY.md`
- `ai/memory/CHANGE_LOG.md`
- `ai/skills/`

## Regla clave
El agente no debe improvisar estructura, comportamiento o documentación si no puede anclarlo a archivos, tests, contratos o decisiones ya presentes en el proyecto.

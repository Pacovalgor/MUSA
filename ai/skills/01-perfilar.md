# Skill: perfilar

## Objetivo
Analizar el repositorio para construir un perfil operativo que optimice el comportamiento del agente a nivel:
- global
- capas
- módulos
- tipo de tarea

## Cuándo usar
- al iniciar trabajo en un repo nuevo
- cuando cambió mucho la estructura
- cuando el agente aún no entiende prioridades del sistema
- cuando la tarea entra en una zona poco conocida

## Entrada mínima
```text
perfilar: repo actual
```

## Qué debe detectar
### Global
- tipo de sistema
- prioridades
- restricciones fuertes
- riesgos principales

### Capas
- frontend
- backend
- engine / data / research
- infra
- docs / memory
- otras capas detectables

### Módulos / dominios
- módulos funcionales
- ownership aproximado
- patrones locales
- riesgos y restricciones por módulo

### Señales
- estructura de carpetas
- archivos raíz
- docs
- tests
- configs
- nombres de módulos
- patrones de imports
- contratos y convenciones repetidas

## Heurísticas de salida
Debe generar o actualizar:
- `ai/memory/PROJECT_PROFILE.yaml`
- notas compactas en `ai/memory/PROJECT_MEMORY.md`

## Formato recomendado de salida
```yaml
global:
  tipo: unknown
  prioridades: []
  riesgos: []
  restricciones: []

capas: {}
modulos: {}

tareas:
  corregir:
    enfasis: []
  añadir:
    enfasis: []
  verificar:
    enfasis: []
```

## Regla crítica
No perfilar por fantasía. Solo usar señales ancladas al repo.

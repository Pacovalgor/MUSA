# PROJECT MEMORY

## Decisiones estables
- MUSA es un estudio de escritura asistida por IA **local-first** con foco en escritorio macOS y arquitectura Flutter + Riverpod.
- El flujo crítico del producto sigue la cadena: `main` → providers de workspace/libro → `editor_controller` → servicios IA/análisis → persistencia local.
- La persistencia del workspace y del documento `.musa` es un contrato central: cualquier cambio debe preservar compatibilidad de serialización y restauración.
- El dominio está segmentado en módulos (`books`, `manuscript`, `characters`, `scenarios`, `notes`, `continuity`, `musa`) con modelos inmutables y providers específicos por slice.

## Restricciones operativas recurrentes
- Priorizar cambio mínimo correcto y scope estricto.
- Evitar refactors oportunistas en `editor`, `providers` y `storage`.
- No declarar verificaciones no ejecutadas.
- Mantener coherencia con servicios IA locales y fallbacks explícitos para plataformas no soportadas.

## Guía de entrada rápida para futuras tareas
1. Confirmar impacto en capa (`ui`, `editor`, `dominio`, `ia`, `storage`).
2. Localizar contrato afectado (modelo/proveedor/servicio/controlador).
3. Aplicar parche mínimo.
4. Ejecutar verificación real (tests/checks relevantes).
5. Guardar solo aprendizaje estable.
EOF

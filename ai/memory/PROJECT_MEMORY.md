# PROJECT MEMORY

## Decisiones estables
- MUSA es un estudio de escritura asistida por IA **local-first** con foco en escritorio macOS y arquitectura Flutter + Riverpod.
- El flujo crítico del producto sigue la cadena: `main` → providers de workspace/libro → `editor_controller` → servicios IA/análisis → persistencia local.
- La persistencia del workspace y del documento `.musa` es un contrato central: cualquier cambio debe preservar compatibilidad de serialización y restauración.
- El dominio está segmentado en módulos (`books`, `manuscript`, `characters`, `scenarios`, `notes`, `continuity`, `musa`) con modelos inmutables y providers específicos por slice.
- **V1.3 (2026-04-20)**: Implementado gating estructural en `ChapterAnalysisService` y `NextBestMoveService`. Se ha añadido refinamiento por contexto local en `NextBestMoveService` y en Musas individuales (`ClarityMusa`, `StyleMusa`, `RhythmMusa`) para ofrecer instrucciones quirúrgicas basadas en el fragmento seleccionado.

## Restricciones operativas recurrentes
- Priorizar cambio mínimo correcto y scope estricto.
- Evitar refactors oportunistas en `editor`, `providers` y `storage`.
- No declarar verificaciones no ejecutadas.
- Mantener coherencia con servicios IA locales y fallbacks explícitos para plataformas no soportadas.
- **Auditabilidad**: Se han añadido fixtures literarios y de apoyo en `test/fixtures/` junto con un test de auditoría (`test/narrative_gating_audit_test.dart`) para garantizar la robustez del gating estructural. Las pruebas reproducibles actuales muestran que el gating estructural distingue bien entre el fixture narrativo auditado, el fixture de apoyo auditado y un caso ambiguo conservador, aunque la cobertura sigue siendo limitada.

## Guía de entrada rápida para futuras tareas
1. Confirmar impacto en capa (`ui`, `editor`, `dominio`, `ia`, `storage`).
2. Localizar contrato afectado (modelo/proveedor/servicio/controlador).
3. Aplicar parche mínimo.
4. Ejecutar verificación real (tests/checks relevantes).
5. Guardar solo aprendizaje estable.
EOF

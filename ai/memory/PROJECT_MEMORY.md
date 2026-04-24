# PROJECT MEMORY

## Decisiones estables
- MUSA es un estudio de escritura asistida por IA **local-first** con foco en escritorio macOS y arquitectura Flutter + Riverpod.
- El flujo crítico del producto sigue la cadena: `main` → providers de workspace/libro → `editor_controller` → servicios IA/análisis → persistencia local.
- La persistencia del workspace y del documento `.musa` es un contrato central: cualquier cambio debe preservar compatibilidad de serialización y restauración.
- El dominio está segmentado en módulos (`books`, `manuscript`, `characters`, `scenarios`, `notes`, `continuity`, `musa`) con modelos inmutables y providers específicos por slice.
- **V1.3 (2026-04-20)**: Implementado gating estructural en `ChapterAnalysisService` y `NextBestMoveService`. Se ha añadido refinamiento por contexto local en `NextBestMoveService` y en Musas individuales (`ClarityMusa`, `StyleMusa`, `RhythmMusa`, `TensionMusa`) para ofrecer instrucciones quirúrgicas basadas en el fragmento seleccionado. Se ha introducido la detección de **diálogo estancado** en `TensionMusa` y un sistema de **explicabilidad basada en señales** en `MusaAutopilot` para dotar de trazabilidad a las recomendaciones editoriales.
- **V1.4 (2026-04-24)**: 
  - ✅ Agregada música lofi embebida (30 pistas Open-Lofi, ~88 MB) con widget de selección por categoría y persistencia de preferencias
  - ✅ **Confidence scoring** en `NarrativeDocumentClassifier`: clasificaciones retornan probabilidad (0.0-1.0) permitiendo descartar sugerencias en textos ambiguos
  - ✅ **Ponderación de verbos** en `EditorialSignals`: verbos de acción divididos en 3 categorías (físicos, operacionales, dicendi) con blending contextual, evita penalizar escenas de diálogo puro
  - ✅ **Feedback loops** en pipelines: `_shouldSkipMusaByFeedback()` analiza salida de Musa N antes de ejecutar N+1, evita procesamiento redundante (ej: ClarityMusa + RhythmMusa no corren ambas si Clarity ya solucionó ritmo)
  - 🔄 **Pipeline transparency** (parcial): `musaExecutionHistory` rastrea musas ejecutadas/saltadas; falta exposición UI mejorada
  - ⏳ **Adaptive thresholds**: pendiente para future iteration

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

# PROJECT MEMORY

## Decisiones estables
- MUSA es un estudio de escritura asistida por IA **local-first** con foco en escritorio macOS y arquitectura Flutter + Riverpod.
- El repositorio público debe preservar esa tesis local-first: excluir secretos, credenciales, proyectos `.musa`, modelos `.gguf` y bases de datos locales mediante `.gitignore`.
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
- **V1.5 (2026-05-06)**:
  - ✅ **Aprendizaje adaptativo conectado**: `MusaEffectivenessTracker` aplica multiplicadores conservadores tras un mínimo de 5 muestras por Musa.
  - ✅ **Atribución precisa de feedback**: las sugerencias editoriales conservan `sourceMusaId`; aceptación/rechazo se registra sobre la Musa que produjo la propuesta final, no sobre toda la pipeline.
  - ✅ **Estado visible de aprendizaje**: `MusaSettingsDialog` muestra estado por Musa (`Aprendiendo`, `Estable`, `Afinada`, `En pausa`) con muestras, aceptación y descartes.
  - ✅ **Gating narrativo endurecido**: mejor separación entre escena, research, worldbuilding y técnico, con cobertura para `El ojo invisible`.
  - ✅ **Smoke FFI real validado**: `llama_processor_real_smoke_test.dart` puede ejecutarse con el modelo instalado en el contenedor macOS de MUSA.
- **V1.6 (2026-05-06)**:
  - ✅ **Calibración profesional separada**: `ProfessionalCorpusCalibration` usa perfiles derivados de los reportes de `Mithas y Karthay` (fantasy), `Tras la puerta` (thriller) y `Un lugar llamado libertad` (historical).
  - ✅ **No mezcla corpus con feedback personal**: la calibración profesional ajusta multiplicadores base por género; `MusaEffectivenessTracker` sigue representando únicamente aceptaciones/rechazos del usuario.
  - ✅ **Composición conservadora**: los multiplicadores profesionales y personales se combinan con límites para evitar sesgos bruscos en `MusaAutopilot`.
- **V1.7 (2026-05-06)**:
  - ✅ **Corpus profesional ampliado**: `ProfessionalCorpusCalibration` pasa a 15 referencias locales derivadas, con 5 libros por perfil (`fantasy`, `thriller`, `historical`).
  - ✅ **Métricas derivadas, no texto fuente**: se registran señales agregadas por género (`avgSentenceLength`, diálogo, preguntas, términos dramáticos y diversidad léxica) sin guardar prose, fragmentos de libros ni EPUBs en el repositorio.
  - ✅ **Tests golden de calibración**: `professional_corpus_calibration_test.dart` valida referencias, métricas y ausencia de `sampleText` para preservar privacidad/copyright.

## Restricciones operativas recurrentes
- Priorizar cambio mínimo correcto y scope estricto.
- Evitar refactors oportunistas en `editor`, `providers` y `storage`.
- No declarar verificaciones no ejecutadas.
- Mantener coherencia con servicios IA locales y fallbacks explícitos para plataformas no soportadas.
- **Auditabilidad**: Se han añadido fixtures literarios y de apoyo en `test/fixtures/` junto con un test de auditoría (`test/narrative_gating_audit_test.dart`) para garantizar la robustez del gating estructural. Las pruebas reproducibles actuales muestran que el gating estructural distingue bien entre el fixture narrativo auditado, el fixture de apoyo auditado y un caso ambiguo conservador, aunque la cobertura sigue siendo limitada.
- El aprendizaje de Musas debe mantenerse local-first y conservador: no ajustar selección hasta tener muestra mínima, y registrar feedback sobre la Musa fuente de la sugerencia final.
- La calibración de libros profesionales debe permanecer como criterio editorial general, separada del aprendizaje personal de Paco, y solo debe guardar señales derivadas agregadas.

## Guía de entrada rápida para futuras tareas
1. Confirmar impacto en capa (`ui`, `editor`, `dominio`, `ia`, `storage`).
2. Localizar contrato afectado (modelo/proveedor/servicio/controlador).
3. Aplicar parche mínimo.
4. Ejecutar verificación real (tests/checks relevantes).
5. Guardar solo aprendizaje estable.

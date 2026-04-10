import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../modules/books/providers/workspace_providers.dart';
import '../../modules/manuscript/models/document.dart';
import '../../modules/scenarios/models/scenario.dart';
import '../../modules/scenarios/providers/scenario_providers.dart';
import '../../ui/providers/ui_providers.dart';
import '../../ui/widgets/editorial_dialogs.dart';

class ScenarioEditor extends ConsumerStatefulWidget {
  const ScenarioEditor({super.key});

  @override
  ConsumerState<ScenarioEditor> createState() => _ScenarioEditorState();
}

class _ScenarioEditorState extends ConsumerState<ScenarioEditor> {
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _atmosphereController = TextEditingController();
  final _importanceController = TextEditingController();
  final _whatItHidesController = TextEditingController();
  final _currentStateController = TextEditingController();
  final _notesController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _scrollController = ScrollController();

  Timer? _saveDebounce;
  String? _syncedScenarioId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!mounted) return;
    ref.read(topBarContextVisibleProvider.notifier).state =
        _scrollController.offset > 48;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _nameController.dispose();
    _roleController.dispose();
    _summaryController.dispose();
    _atmosphereController.dispose();
    _importanceController.dispose();
    _whatItHidesController.dispose();
    _currentStateController.dispose();
    _notesController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    final scenario = ref.watch(selectedScenarioProvider);
    final linkedDocuments = ref.watch(selectedScenarioDocumentsProvider);
    final autofillState = ref.watch(scenarioAutofillProvider);
    _syncScenario(scenario, autofillState);

    if (scenario == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(topBarContextVisibleProvider.notifier).state = false;
      });
      return Center(
        child: Text(
          'Selecciona un escenario o crea uno nuevo para empezar.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: tokens.textMuted,
              ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final offset = _scrollController.hasClients ? _scrollController.offset : 0;
      ref.read(topBarContextVisibleProvider.notifier).state = offset > 48;
    });

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: Container(
          constraints:
              const BoxConstraints(maxWidth: MusaConstants.editorMaxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Escenarios',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tokens.textMuted,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          autofocus: scenario.name == 'Escenario nuevo' ||
                              scenario.name.trim().isEmpty,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: tokens.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                          decoration: _fieldDecoration(
                            context,
                            hintText: 'Nombre del escenario',
                            borderless: true,
                          ),
                          onChanged: (_) => _scheduleSave(scenario),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: TextButton.icon(
                      onPressed: () => _confirmDelete(context, scenario),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: tokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              if (autofillState.appliesTo(scenario.id) &&
                  autofillState.phase != ScenarioAutofillPhase.idle) ...[
                _buildAutofillBanner(context, autofillState),
                const SizedBox(height: 24),
              ],
              _buildField(
                context,
                label: 'Función en la historia',
                hintText: 'Qué papel cumple este lugar en la narración',
                controller: _roleController,
                scenario: scenario,
              ),
              _buildField(
                context,
                label: 'Qué es este lugar',
                hintText: 'Descríbelo en pocas líneas, con criterio editorial',
                controller: _summaryController,
                scenario: scenario,
                minLines: 3,
              ),
              _buildField(
                context,
                label: 'Qué ambiente tiene',
                hintText: 'Sensación, textura o clima emocional que transmite',
                controller: _atmosphereController,
                scenario: scenario,
                minLines: 3,
              ),
              _buildField(
                context,
                label: 'Por qué importa',
                hintText: 'Peso narrativo del escenario dentro de la historia',
                controller: _importanceController,
                scenario: scenario,
                minLines: 3,
              ),
              _buildField(
                context,
                label: 'Qué oculta',
                hintText: 'Lo que calla, tapa o concentra sin decirlo del todo',
                controller: _whatItHidesController,
                scenario: scenario,
                minLines: 3,
              ),
              _buildField(
                context,
                label: 'Estado actual',
                hintText: 'Cómo está ahora dentro de la historia',
                controller: _currentStateController,
                scenario: scenario,
                minLines: 3,
              ),
              _buildField(
                context,
                label: 'Notas',
                hintText: 'Observaciones libres del autor',
                controller: _notesController,
                scenario: scenario,
                minLines: 4,
              ),
              const SizedBox(height: 12),
              _buildLinkedDocumentsSection(context, linkedDocuments),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedDocumentsSection(
    BuildContext context,
    List<Document> linkedDocuments,
  ) {
    final tokens = MusaTheme.tokensOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aparece en',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        if (linkedDocuments.isEmpty)
          Text(
            'Todavía no está vinculado a ningún capítulo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textMuted,
                ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: linkedDocuments
                .map(
                  (document) => ActionChip(
                    label: Text(document.title),
                    onPressed: () {
                      ref
                          .read(narrativeWorkspaceProvider.notifier)
                          .selectDocument(document.id);
                    },
                    backgroundColor: tokens.panelBackground,
                    side: BorderSide(color: tokens.borderSubtle),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildAutofillBanner(
    BuildContext context,
    ScenarioAutofillState autofillState,
  ) {
    final tokens = MusaTheme.tokensOf(context);
    final isDrafting = autofillState.phase == ScenarioAutofillPhase.drafting;
    final isFailed = autofillState.phase == ScenarioAutofillPhase.failed;
    final isEnrich = autofillState.kind == ScenarioAutofillKind.enrich;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isFailed ? tokens.warningBackground : tokens.infoBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFailed ? tokens.borderStrong : tokens.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.canvasBackground.withValues(alpha: 0.75),
            ),
            child: Icon(
              isFailed ? Icons.info_outline : Icons.auto_awesome,
              size: 16,
              color: isFailed ? tokens.warningText : tokens.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  autofillState.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDrafting
                      ? (isEnrich
                          ? 'MUSA está incorporando nuevas capas del manuscrito sin borrar lo que ya funciona.'
                          : 'La ficha sigue abierta para que puedas escribir mientras tanto.')
                      : (isEnrich
                          ? 'La ficha acaba de enriquecerse con un nuevo matiz del manuscrito.'
                          : 'Puedes revisar y ajustar la propuesta con total libertad.'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required String label,
    required String hintText,
    required TextEditingController controller,
    required Scenario scenario,
    int minLines = 1,
  }) {
    final tokens = MusaTheme.tokensOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            minLines: minLines,
            maxLines: null,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: tokens.textPrimary,
                  height: 1.5,
                ),
            decoration: _fieldDecoration(context, hintText: hintText),
            onChanged: (_) => _scheduleSave(scenario),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hintText,
    bool borderless = false,
  }) {
    final tokens = MusaTheme.tokensOf(context);
    return InputDecoration(
      hintText: hintText,
      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: tokens.textMuted,
          ),
      filled: !borderless,
      fillColor: borderless ? null : tokens.panelBackground,
      border: borderless
          ? InputBorder.none
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: tokens.borderSubtle),
            ),
      enabledBorder: borderless
          ? InputBorder.none
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: tokens.borderSubtle),
            ),
      focusedBorder: borderless
          ? InputBorder.none
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: tokens.borderStrong),
            ),
      contentPadding: borderless
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  void _syncScenario(
    Scenario? scenario,
    ScenarioAutofillState autofillState,
  ) {
    if (scenario == null) return;

    final needsFullSync = _syncedScenarioId != scenario.id ||
        _nameController.text != scenario.name ||
        _roleController.text != scenario.role ||
        _summaryController.text != scenario.summary ||
        _atmosphereController.text != scenario.atmosphere ||
        _importanceController.text != scenario.importance ||
        _whatItHidesController.text != scenario.whatItHides ||
        _currentStateController.text != scenario.currentState ||
        _notesController.text != scenario.notes;

    if (!needsFullSync) return;

    final preserveLocalInput =
        autofillState.phase == ScenarioAutofillPhase.drafting &&
            autofillState.appliesTo(scenario.id);

    _syncFieldController(_nameController, scenario.name,
        preserveLocalInput: false);
    _syncFieldController(_roleController, scenario.role,
        preserveLocalInput: preserveLocalInput);
    _syncFieldController(_summaryController, scenario.summary,
        preserveLocalInput: preserveLocalInput);
    _syncFieldController(_atmosphereController, scenario.atmosphere,
        preserveLocalInput: preserveLocalInput);
    _syncFieldController(_importanceController, scenario.importance,
        preserveLocalInput: preserveLocalInput);
    _syncFieldController(_whatItHidesController, scenario.whatItHides,
        preserveLocalInput: preserveLocalInput);
    _syncFieldController(_currentStateController, scenario.currentState,
        preserveLocalInput: preserveLocalInput);
    _syncFieldController(_notesController, scenario.notes,
        preserveLocalInput: preserveLocalInput);
    _syncedScenarioId = scenario.id;

    if (scenario.name == 'Escenario nuevo' || scenario.name.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _nameFocusNode.requestFocus();
      });
    }
  }

  void _syncFieldController(
    TextEditingController controller,
    String value, {
    required bool preserveLocalInput,
  }) {
    if (preserveLocalInput && controller.text.trim().isNotEmpty) {
      return;
    }
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _scheduleSave(Scenario scenario) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      ref.read(narrativeWorkspaceProvider.notifier).updateScenario(
            scenario.copyWith(
              name: _nameController.text.trim().isEmpty
                  ? 'Escenario nuevo'
                  : _nameController.text.trim(),
              role: _roleController.text.trim(),
              summary: _summaryController.text.trim(),
              atmosphere: _atmosphereController.text.trim(),
              importance: _importanceController.text.trim(),
              whatItHides: _whatItHidesController.text.trim(),
              currentState: _currentStateController.text.trim(),
              notes: _notesController.text.trim(),
            ),
          );
    });
  }

  Future<void> _confirmDelete(BuildContext context, Scenario scenario) async {
    final confirmed = await EditorialDialogs.confirmDestructive(
      context,
      title: 'Eliminar escenario',
      message:
          'Se eliminará "${scenario.displayName}". Esta acción no se puede deshacer.',
    );

    if (confirmed != true || !mounted) return;
    await ref
        .read(narrativeWorkspaceProvider.notifier)
        .deleteScenario(scenario.id);
  }
}

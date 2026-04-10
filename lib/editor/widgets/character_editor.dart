import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../modules/books/providers/workspace_providers.dart';
import '../../modules/characters/models/character.dart';
import '../../modules/characters/providers/character_providers.dart';
import '../../modules/manuscript/models/document.dart';
import '../../ui/providers/ui_providers.dart';
import '../../ui/widgets/editorial_dialogs.dart';

class CharacterEditor extends ConsumerStatefulWidget {
  const CharacterEditor({super.key});

  @override
  ConsumerState<CharacterEditor> createState() => _CharacterEditorState();
}

class _CharacterEditorState extends ConsumerState<CharacterEditor> {
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _voiceController = TextEditingController();
  final _motivationController = TextEditingController();
  final _internalConflictController = TextEditingController();
  final _whatTheyHideController = TextEditingController();
  final _currentStateController = TextEditingController();
  final _notesController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _isProtagonist = false;

  Timer? _saveDebounce;
  String? _syncedCharacterId;
  bool _isSyncing = false;

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
    _voiceController.dispose();
    _motivationController.dispose();
    _internalConflictController.dispose();
    _whatTheyHideController.dispose();
    _currentStateController.dispose();
    _notesController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    final character = ref.watch(selectedCharacterProvider);
    final linkedDocuments = ref.watch(selectedCharacterDocumentsProvider);
    final autofillState = ref.watch(characterAutofillProvider);
    _syncCharacter(character, autofillState);

    if (character == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(topBarContextVisibleProvider.notifier).state = false;
      });
      return Center(
        child: Text(
          'Selecciona un personaje o crea uno nuevo para empezar.',
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
                          'Personajes',
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
                          autofocus: character.name == 'Nuevo personaje' ||
                              character.name == 'Protagonista' ||
                              character.name == 'Narrador' ||
                              character.name.trim().isEmpty,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: tokens.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                          decoration: _fieldDecoration(
                            context,
                            hintText: 'Nombre del personaje',
                            borderless: true,
                          ),
                          onChanged: (_) => _scheduleSave(character),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: TextButton.icon(
                      onPressed: () => _confirmDelete(context, character),
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
              if (autofillState.appliesTo(character.id) &&
                  autofillState.phase != CharacterAutofillPhase.idle) ...[
                _buildAutofillBanner(context, autofillState),
                const SizedBox(height: 24),
              ],
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: tokens.panelBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Protagonista',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: tokens.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Márcalo si este personaje lleva el punto de vista principal.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: tokens.textSecondary,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isProtagonist,
                      onChanged: (value) {
                        setState(() => _isProtagonist = value);
                        _scheduleSave(character);
                      },
                      activeThumbColor: tokens.textPrimary,
                      activeTrackColor: tokens.textPrimary.withValues(alpha: 0.28),
                      inactiveThumbColor: tokens.canvasBackground,
                      inactiveTrackColor: tokens.borderStrong,
                    ),
                  ],
                ),
              ),
              _buildField(
                context,
                label: 'Rol en la historia',
                hintText: 'Qué papel cumple en la narración',
                controller: _roleController,
                character: character,
              ),
              _buildField(
                context,
                label: 'Quién es',
                hintText: 'Preséntalo en pocas líneas',
                controller: _summaryController,
                character: character,
                minLines: 3,
              ),
              _buildField(
                context,
                label: 'Cómo habla',
                hintText: 'Cadencia, léxico, tono o gestos verbales',
                controller: _voiceController,
                character: character,
                minLines: 3,
              ),
              _buildField(
                context,
                label: 'Qué quiere',
                hintText: 'Deseo, necesidad o impulso central',
                controller: _motivationController,
                character: character,
                minLines: 3,
              ),
              _buildField(
                context,
                label: 'Qué lo fractura',
                hintText: 'Conflicto interno, tensión íntima',
                controller: _internalConflictController,
                character: character,
                minLines: 3,
              ),
              _buildField(
                context,
                label: 'Qué oculta',
                hintText: 'Lo que calla, disimula o no se atreve a decir',
                controller: _whatTheyHideController,
                character: character,
                minLines: 3,
              ),
              _buildField(
                context,
                label: 'Estado actual',
                hintText: 'Dónde está ahora dentro de la historia',
                controller: _currentStateController,
                character: character,
                minLines: 3,
              ),
              _buildField(
                context,
                label: 'Notas',
                hintText: 'Observaciones libres del autor',
                controller: _notesController,
                character: character,
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
                    labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildAutofillBanner(
    BuildContext context,
    CharacterAutofillState autofillState,
  ) {
    final tokens = MusaTheme.tokensOf(context);
    final isDrafting = autofillState.phase == CharacterAutofillPhase.drafting;
    final isFailed = autofillState.phase == CharacterAutofillPhase.failed;
    final isEnrich = autofillState.kind == CharacterAutofillKind.enrich;

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
                          ? 'MUSA está incorporando nuevas capas del manuscrito sin pisar tu trabajo.'
                          : 'La ficha sigue abierta para que puedas escribir mientras tanto.')
                      : (isEnrich
                          ? 'La ficha acaba de enriquecerse con un fragmento del manuscrito.'
                          : 'Puedes revisar y matizar la propuesta con total libertad.'),
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
    required Character character,
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
            onChanged: (_) => _scheduleSave(character),
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

  void _syncCharacter(
    Character? character,
    CharacterAutofillState autofillState,
  ) {
    if (character == null) return;

    final needsFullSync = _syncedCharacterId != character.id ||
        _nameController.text != character.name ||
        _roleController.text != character.role ||
        _summaryController.text != character.summary ||
        _voiceController.text != character.voice ||
        _motivationController.text != character.motivation ||
        _internalConflictController.text != character.internalConflict ||
        _whatTheyHideController.text != character.whatTheyHide ||
        _currentStateController.text != character.currentState ||
        _notesController.text != character.notes;

    if (!needsFullSync) return;

    _isSyncing = true;
    final preserveLocalInput =
        autofillState.phase == CharacterAutofillPhase.drafting &&
            autofillState.appliesTo(character.id);

    _syncFieldController(
      _nameController,
      character.name,
      preserveLocalInput: false,
    );
    _syncFieldController(
      _roleController,
      character.role,
      preserveLocalInput: preserveLocalInput,
    );
    _syncFieldController(
      _summaryController,
      character.summary,
      preserveLocalInput: preserveLocalInput,
    );
    _syncFieldController(
      _voiceController,
      character.voice,
      preserveLocalInput: preserveLocalInput,
    );
    _syncFieldController(
      _motivationController,
      character.motivation,
      preserveLocalInput: preserveLocalInput,
    );
    _syncFieldController(
      _internalConflictController,
      character.internalConflict,
      preserveLocalInput: preserveLocalInput,
    );
    _syncFieldController(
      _whatTheyHideController,
      character.whatTheyHide,
      preserveLocalInput: preserveLocalInput,
    );
    _syncFieldController(
      _currentStateController,
      character.currentState,
      preserveLocalInput: preserveLocalInput,
    );
    _syncFieldController(
      _notesController,
      character.notes,
      preserveLocalInput: preserveLocalInput,
    );
    _isProtagonist = character.isProtagonist;
    _isSyncing = false;
    _syncedCharacterId = character.id;

    if (character.name == 'Nuevo personaje' ||
        character.name == 'Protagonista' ||
        character.name == 'Narrador' ||
        character.name.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_nameFocusNode.hasFocus) {
          _nameFocusNode.requestFocus();
          _nameController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _nameController.text.length,
          );
        }
      });
    }
  }

  void _syncFieldController(
    TextEditingController controller,
    String incomingValue, {
    required bool preserveLocalInput,
  }) {
    final currentValue = controller.text;
    final normalizedIncoming = incomingValue;

    if (currentValue == normalizedIncoming) {
      return;
    }

    if (preserveLocalInput &&
        currentValue.trim().isNotEmpty &&
        normalizedIncoming.trim().isNotEmpty) {
      return;
    }

    controller.text = normalizedIncoming;
  }

  void _scheduleSave(Character character) {
    if (_isSyncing) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 180), () {
      ref.read(narrativeWorkspaceProvider.notifier).updateCharacter(
            character.copyWith(
              name: _nameController.text,
              role: _roleController.text,
              summary: _summaryController.text,
              voice: _voiceController.text,
              motivation: _motivationController.text,
              internalConflict: _internalConflictController.text,
              whatTheyHide: _whatTheyHideController.text,
              currentState: _currentStateController.text,
              notes: _notesController.text,
              isProtagonist: _isProtagonist,
            ),
          );
    });
  }

  Future<void> _confirmDelete(BuildContext context, Character character) async {
    final confirmed = await EditorialDialogs.confirmDestructive(
      context,
      title: 'Eliminar personaje',
      message:
          'Se eliminará "${character.displayName}". Esta acción no se puede deshacer.',
    );

    if (!confirmed || !mounted) return;
    await ref
        .read(narrativeWorkspaceProvider.notifier)
        .deleteCharacter(character.id);
  }
}

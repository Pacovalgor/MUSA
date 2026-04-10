import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/providers/workspace_providers.dart';
import '../../manuscript/models/document.dart';
import '../models/character.dart';
import '../models/character_relation.dart';

/// Progress states for AI-assisted character autofill.
enum CharacterAutofillPhase { idle, drafting, completed, failed }

/// Whether the autofill flow is creating a new sheet or enriching an existing one.
enum CharacterAutofillKind { create, enrich }

/// UI state for character autofill banners and progress indicators.
class CharacterAutofillState {
  final String? characterId;
  final CharacterAutofillPhase phase;
  final CharacterAutofillKind kind;
  final String message;

  const CharacterAutofillState({
    this.characterId,
    this.phase = CharacterAutofillPhase.idle,
    this.kind = CharacterAutofillKind.create,
    this.message = '',
  });

  bool appliesTo(String? id) => id != null && id == characterId;
}

/// Drives the transient UI state around character autofill operations.
class CharacterAutofillNotifier extends StateNotifier<CharacterAutofillState> {
  CharacterAutofillNotifier() : super(const CharacterAutofillState());

  void start(String characterId) {
    state = CharacterAutofillState(
      characterId: characterId,
      phase: CharacterAutofillPhase.drafting,
      kind: CharacterAutofillKind.create,
      message: 'MUSA está dando forma al personaje…',
    );
  }

  void startEnrichment(String characterId, String displayName) {
    state = CharacterAutofillState(
      characterId: characterId,
      phase: CharacterAutofillPhase.drafting,
      kind: CharacterAutofillKind.enrich,
      message: 'MUSA está revisando a $displayName…',
    );
  }

  void updateMessage(String characterId, String message) {
    if (!state.appliesTo(characterId) ||
        state.phase != CharacterAutofillPhase.drafting) {
      return;
    }
    state = CharacterAutofillState(
      characterId: characterId,
      phase: state.phase,
      message: message,
    );
  }

  void complete(String characterId) {
    if (!state.appliesTo(characterId)) return;
    state = CharacterAutofillState(
      characterId: characterId,
      phase: CharacterAutofillPhase.completed,
      kind: state.kind,
      message: state.kind == CharacterAutofillKind.enrich
          ? 'Ficha actualizada con contexto del manuscrito.'
          : 'MUSA ha dejado una primera propuesta en la ficha.',
    );
  }

  void fail(String characterId) {
    if (!state.appliesTo(characterId)) return;
    state = CharacterAutofillState(
      characterId: characterId,
      phase: CharacterAutofillPhase.failed,
      kind: state.kind,
      message: state.kind == CharacterAutofillKind.enrich
          ? 'No hemos podido enriquecer la ficha ahora mismo.'
          : 'No hemos podido completar la ficha ahora mismo.',
    );
  }

  void clear(String characterId) {
    if (!state.appliesTo(characterId)) return;
    state = const CharacterAutofillState();
  }
}

/// Characters available in the active book.
final charactersProvider = Provider<List<Character>>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.activeBookCharacters ??
      const [];
});

/// Character currently selected in the workspace.
final selectedCharacterProvider = Provider<Character?>((ref) {
  return ref.watch(narrativeWorkspaceProvider).value?.selectedCharacter;
});

/// Documents in which the selected character is explicitly referenced.
final selectedCharacterDocumentsProvider = Provider<List<Document>>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  final character = ref.watch(selectedCharacterProvider);
  if (workspace == null || character == null) return const [];
  final documents = workspace.documents
      .where((document) =>
          document.bookId == character.bookId &&
          document.characterIds.contains(character.id))
      .toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return documents;
});

/// Relations between characters scoped to the active book.
final characterRelationsProvider = Provider<List<CharacterRelation>>((ref) {
  final workspace = ref.watch(narrativeWorkspaceProvider).value;
  final activeBookId = workspace?.activeBook?.id;
  if (workspace == null || activeBookId == null) return const [];
  return workspace.characterRelations
      .where((relation) => relation.bookId == activeBookId)
      .toList();
});

/// Notifier that exposes the live character autofill status to the UI.
final characterAutofillProvider =
    StateNotifierProvider<CharacterAutofillNotifier, CharacterAutofillState>(
  (ref) => CharacterAutofillNotifier(),
);

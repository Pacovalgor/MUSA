import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../editor/models/musa_action.dart';

// Current visibility state
final sidebarVisibilityProvider = StateProvider<bool>((ref) => true);
final inspectorVisibilityProvider = StateProvider<bool>((ref) => false);
final sidebarAutoOpenedProvider = StateProvider<bool>((ref) => false);
final inspectorAutoOpenedProvider = StateProvider<bool>((ref) => false);

// Contextual Inspector content
final activeActionProvider = StateProvider<MusaAction?>((ref) => null);

// Focus and Layout specific UI state
final isZenModeProvider = StateProvider<bool>((ref) => false);
final isZenModeAutoProvider = StateProvider<bool>((ref) => true);
final editorFocusProvider = StateProvider<bool>((ref) => true);
final topBarContextVisibleProvider = StateProvider<bool>((ref) => false);

import '../../muses/musa.dart';

/// Descriptor for editor actions.
/// Now acts as a pure metadata container, removing any AI execution logic
/// which has been centralized in the EditorController.
abstract class MusaAction {
  final String label;
  final String icon;

  MusaAction({required this.label, required this.icon});
}

class MuseAction extends MusaAction {
  final Musa musa;

  MuseAction({
    required this.musa,
    String? label,
    String? icon,
  }) : super(
          label: label ?? musa.name,
          icon: icon ?? 'auto_awesome',
        );
}

class BasicEditorAction extends MusaAction {
  final void Function() onTrigger;

  BasicEditorAction({
    required super.label,
    required super.icon,
    required this.onTrigger,
  });
}

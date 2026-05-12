import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/creative/models/creative_card.dart';
import 'package:musa/modules/inbox/models/inbox_capture.dart';
import 'package:musa/modules/inbox/providers/inbox_captures_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/modules/inbox/providers/inbox_history_provider.dart';
import 'package:musa/modules/inbox/services/kind_detector_service.dart';
import 'package:musa/ui/inbox/iphone/inbox_settings_screen.dart';
import 'package:uuid/uuid.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _detector = const KindDetectorService();
  bool _saving = false;
  CreativeCardType _creativeType = CreativeCardType.idea;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text;
    if (text.trim().isEmpty || _saving) return;
    final storage = ref.read(inboxStorageProvider);
    if (storage == null) {
      _showSnack('Sin carpeta configurada');
      return;
    }
    setState(() => _saving = true);
    try {
      final det = _detector.detect(text);
      final deviceLabel = await ref.read(inboxDeviceLabelProvider.future);
      final capture = InboxCapture(
        schemaVersion: 1,
        id: const Uuid().v4(),
        capturedAt: DateTime.now().toUtc(),
        deviceLabel: deviceLabel,
        kind: det.kind,
        body: det.body,
        url: det.url,
        creativeTypeHint: _creativeType.name,
      );
      await storage.write(capture);
      await ref.read(inboxHistoryCacheProvider.notifier).add(capture.id);
      bumpInboxRefreshTick(ref);
      if (!mounted) return;
      _controller.clear();
      _showSnack('✓ Guardado a la bandeja');
      _focus.requestFocus();
    } catch (e) {
      _showSnack('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final folder = ref.watch(inboxFolderProvider);
    final detection = _detector.detect(_controller.text);
    final canSave = _controller.text.trim().isNotEmpty &&
        folder.health == InboxFolderHealth.healthy &&
        !_saving;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(folderHealth: folder.health),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    TextField(
                      controller: _controller,
                      focusNode: _focus,
                      maxLines: null,
                      expands: true,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Una idea, un link, una frase…',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 17, height: 1.5),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _KindChip(
                          kind:
                              _controller.text.isEmpty ? null : detection.kind),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CreativeTypeChoice(
                    key: const Key('iphone-capture-type-idea'),
                    label: 'Idea',
                    selected: _creativeType == CreativeCardType.idea,
                    onTap: () =>
                        setState(() => _creativeType = CreativeCardType.idea),
                  ),
                  _CreativeTypeChoice(
                    key: const Key('iphone-capture-type-sketch'),
                    label: 'Boceto',
                    selected: _creativeType == CreativeCardType.sketch,
                    onTap: () =>
                        setState(() => _creativeType = CreativeCardType.sketch),
                  ),
                  _CreativeTypeChoice(
                    key: const Key('iphone-capture-type-question'),
                    label: 'Pregunta',
                    selected: _creativeType == CreativeCardType.question,
                    onTap: () => setState(
                        () => _creativeType = CreativeCardType.question),
                  ),
                  _CreativeTypeChoice(
                    key: const Key('iphone-capture-type-research'),
                    label: 'Research',
                    selected: _creativeType == CreativeCardType.research,
                    onTap: () => setState(
                        () => _creativeType = CreativeCardType.research),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton(
                key: const Key('iphone-capture-save-button'),
                onPressed: canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar a la bandeja'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreativeTypeChoice extends StatelessWidget {
  const _CreativeTypeChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.folderHealth});
  final InboxFolderHealth folderHealth;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (folderHealth) {
      InboxFolderHealth.healthy => (Colors.green, 'Sincronizado'),
      InboxFolderHealth.unreachable => (Colors.red, 'Sin carpeta'),
      InboxFolderHealth.unconfigured => (Colors.orange, 'Configurar'),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          const Text('Capturar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({this.kind});
  final InboxCaptureKind? kind;

  @override
  Widget build(BuildContext context) {
    if (kind == null) return const SizedBox.shrink();
    final (icon, label) = switch (kind!) {
      InboxCaptureKind.text => ('📝', 'texto'),
      InboxCaptureKind.link => ('🔗', 'link'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text('$icon $label',
          style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600)),
    );
  }
}

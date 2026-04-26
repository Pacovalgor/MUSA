import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:musa/ui/inbox/iphone/capture_screen.dart';
import 'package:musa/ui/inbox/iphone/history_screen.dart';
import 'package:musa/ui/inbox/iphone/inbox_settings_screen.dart';
import 'package:musa/ui/inbox/iphone/onboarding_screen.dart';

/// Shell del iPhone para Ola 1 — "MUSA Capturar".
///
/// Los tabs históricos (Biblioteca, Documento) están ocultos en Ola 1; sólo
/// se exponen Capturar e Historial. La pantalla de onboarding aparece si no
/// hay carpeta configurada.
class CaptureToolShell extends ConsumerStatefulWidget {
  const CaptureToolShell({super.key});

  @override
  ConsumerState<CaptureToolShell> createState() => _CaptureToolShellState();
}

class _CaptureToolShellState extends ConsumerState<CaptureToolShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final folder = ref.watch(inboxFolderProvider);
    if (folder.health == InboxFolderHealth.unconfigured) {
      return InboxOnboardingScreen(onCompleted: () => setState(() {}));
    }
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          CaptureScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Capturar',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'inbox-settings',
        tooltip: 'Ajustes de la bandeja',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const InboxSettingsScreen()),
        ),
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}

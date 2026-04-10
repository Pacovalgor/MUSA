import 'package:flutter/material.dart';

import '../../adaptive/adaptive_spec.dart';
import '../../features/workspace/presentation/widgets/capture_workspace_view.dart';
import '../../features/workspace/presentation/widgets/document_focus_view.dart';
import '../../features/workspace/presentation/widgets/workspace_library_panel.dart';

class CaptureToolShell extends StatefulWidget {
  const CaptureToolShell({super.key});

  @override
  State<CaptureToolShell> createState() => _CaptureToolShellState();
}

class _CaptureToolShellState extends State<CaptureToolShell> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    final spec = context.musaAdaptiveSpec;

    final pages = [
      WorkspaceLibraryPanel(
        onDocumentSelected: (_) => setState(() => _currentIndex = 1),
        onNoteSelected: (_) => setState(() => _currentIndex = 2),
      ),
      const DocumentFocusView(
        titleOverride: 'Documento activo',
        subtitle: 'Escritura ligera centrada en el texto',
      ),
      CaptureWorkspaceView(
        onDocumentRequested: () => setState(() => _currentIndex = 1),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: spec.supportsBottomNavigation
          ? NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (value) =>
                  setState(() => _currentIndex = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.library_books_outlined),
                  selectedIcon: Icon(Icons.library_books),
                  label: 'Biblioteca',
                ),
                NavigationDestination(
                  icon: Icon(Icons.description_outlined),
                  selectedIcon: Icon(Icons.description),
                  label: 'Documento',
                ),
                NavigationDestination(
                  icon: Icon(Icons.edit_note_outlined),
                  selectedIcon: Icon(Icons.edit_note),
                  label: 'Captura',
                ),
              ],
            )
          : null,
    );
  }
}

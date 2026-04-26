import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';

class InboxOnboardingScreen extends ConsumerStatefulWidget {
  const InboxOnboardingScreen({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  ConsumerState<InboxOnboardingScreen> createState() =>
      _InboxOnboardingScreenState();
}

class _InboxOnboardingScreenState
    extends ConsumerState<InboxOnboardingScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _choose() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await ref.read(inboxFolderProvider.notifier).chooseNewFolder();
      if (ok && mounted) widget.onCompleted?.call();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text('MUSA Capturar',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text(
                'Guarda tus ideas en una carpeta que tú elijas — puede '
                'estar en iCloud, Drive, OneDrive, Dropbox… cualquier '
                'servicio de sync que ya uses.\n\n'
                'Tus capturas son archivos .json que tú controlas. MUSA '
                'no habla con ningún servicio en la nube.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              const Spacer(),
              if (_error != null) ...[
                Text(_error!,
                    style: TextStyle(color: Colors.red.shade700)),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _choose,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Elegir carpeta'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

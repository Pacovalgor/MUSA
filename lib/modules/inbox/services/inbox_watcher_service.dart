import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Vigila la carpeta `MUSA-Inbox/` y emite ticks de cambio agregados con
/// debounce. Sólo activo en macOS — en otras plataformas no inicia el
/// watcher.
class InboxWatcherService {
  InboxWatcherService({
    required this.rootDirectory,
    Duration debounce = const Duration(milliseconds: 250),
  })  : _debounce = debounce;

  final Directory rootDirectory;
  final Duration _debounce;

  final _controller = StreamController<void>.broadcast();
  Stream<void> get changes => _controller.stream;

  StreamSubscription<FileSystemEvent>? _sub;
  Timer? _flushTimer;

  Future<void> start() async {
    final inbox = Directory(p.join(rootDirectory.path, 'MUSA-Inbox'));
    if (!inbox.existsSync()) inbox.createSync(recursive: true);

    if (!Platform.isMacOS) {
      // En otras plataformas no instalamos watcher en Ola 1.
      return;
    }

    _sub = inbox
        .watch(events: FileSystemEvent.all, recursive: true)
        .listen((_) => _bump());
  }

  Future<void> stop() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await _sub?.cancel();
    _sub = null;
  }

  void _bump() {
    _flushTimer?.cancel();
    _flushTimer = Timer(_debounce, () {
      if (!_controller.isClosed) _controller.add(null);
    });
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}

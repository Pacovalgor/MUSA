import 'dart:convert';
import 'dart:io';

import 'package:musa/modules/inbox/models/inbox_capture.dart';
import 'package:musa/modules/inbox/models/inbox_capture_status.dart';
import 'package:path/path.dart' as p;

/// Una captura tal y como vive en el filesystem (puede estar legible o no).
class InboxCaptureRecord {
  const InboxCaptureRecord({
    required this.path,
    required this.status,
    this.capture,
    this.rawContent,
    this.parseError,
  });

  /// Path absoluto del archivo `.json`.
  final String path;
  final InboxCaptureStatus status;

  /// Captura parseada. `null` si `status == unreadable`.
  final InboxCapture? capture;

  /// Contenido bruto del archivo (sólo poblado si `unreadable`).
  final String? rawContent;
  final String? parseError;
}

/// Acceso al filesystem para la bandeja: leer, escribir y mover capturas.
///
/// La carpeta raíz pasada en el constructor es la elegida por el usuario
/// (NO ya con `MUSA-Inbox/` apendido). El servicio gestiona internamente
/// la subcarpeta `MUSA-Inbox/`.
class InboxStorageService {
  InboxStorageService({required this.rootDirectory});

  final Directory rootDirectory;

  static const String _inboxFolder = 'MUSA-Inbox';
  static const String _processedFolder = 'processed';
  static const String _discardedFolder = 'discarded';

  Directory get _inbox =>
      Directory(p.join(rootDirectory.path, _inboxFolder));
  Directory get _processed =>
      Directory(p.join(_inbox.path, _processedFolder));
  Directory get _discarded =>
      Directory(p.join(_inbox.path, _discardedFolder));

  /// `true` si la raíz existe y es escribible (escribe + lee + borra un
  /// `.musa-test`).
  Future<bool> isAccessible() async {
    if (!rootDirectory.existsSync()) return false;
    try {
      final probe =
          File(p.join(rootDirectory.path, '.musa-inbox-probe-${_now()}'));
      probe.writeAsStringSync('probe', flush: true);
      probe.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Escribe una captura en `MUSA-Inbox/<fecha-local>/<HH-MM-SS>-<id>.json`
  /// y devuelve el `File` resultante.
  Future<File> write(InboxCapture capture) async {
    final localDate = capture.capturedAt.toLocal();
    final dateFolder = _formatDate(localDate);
    final timePrefix = _formatTime(localDate);

    final dir = Directory(p.join(_inbox.path, dateFolder));
    dir.createSync(recursive: true);

    final filename = '$timePrefix-${capture.id}.json';
    final file = File(p.join(dir.path, filename));

    final encoded = const JsonEncoder.withIndent('  ').convert(capture.toJson());
    await file.writeAsString('$encoded\n', flush: true);
    return file;
  }

  /// Lee todas las capturas conocidas en MUSA-Inbox (pendientes + processed +
  /// discarded), reportando estado por carpeta.
  Future<List<InboxCaptureRecord>> readAll() async {
    if (!_inbox.existsSync()) return const [];
    final out = <InboxCaptureRecord>[];

    // Pending: subcarpetas por fecha (todo lo que no sea processed/discarded).
    for (final entity in _inbox.listSync()) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (name == _processedFolder || name == _discardedFolder) continue;
      _collectFromFolder(entity, InboxCaptureStatus.pending, out);
    }

    // Processed.
    if (_processed.existsSync()) {
      _collectFromFolder(_processed, InboxCaptureStatus.processed, out);
    }
    // Discarded.
    if (_discarded.existsSync()) {
      _collectFromFolder(_discarded, InboxCaptureStatus.discarded, out);
    }
    return out;
  }

  Future<List<InboxCaptureRecord>> readPending() async {
    final all = await readAll();
    return all
        .where((r) => r.status == InboxCaptureStatus.pending)
        .toList();
  }

  Future<void> markProcessed(File file) =>
      _moveTo(file, _processed);

  Future<void> markDiscarded(File file) =>
      _moveTo(file, _discarded);

  Future<void> _moveTo(File file, Directory destination) async {
    destination.createSync(recursive: true);
    final newPath = p.join(destination.path, p.basename(file.path));
    try {
      await file.rename(newPath);
    } on FileSystemException {
      // Cross-volume rename can fail. Fallback to copy + delete.
      await file.copy(newPath);
      await file.delete();
    }
  }

  void _collectFromFolder(
    Directory folder,
    InboxCaptureStatus status,
    List<InboxCaptureRecord> out,
  ) {
    for (final f in folder.listSync()) {
      if (f is! File) continue;
      if (!f.path.endsWith('.json')) continue;
      InboxCapture? parsed;
      String? rawContent;
      String? parseError;
      try {
        final raw = f.readAsStringSync();
        rawContent = raw;
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Top-level JSON no es objeto');
        }
        parsed = InboxCapture.fromJson(decoded);
      } catch (e) {
        parseError = e.toString();
      }
      out.add(InboxCaptureRecord(
        path: f.path,
        status: parsed == null ? InboxCaptureStatus.unreadable : status,
        capture: parsed,
        rawContent: parsed == null ? rawContent : null,
        parseError: parseError,
      ));
    }
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_2(d.month)}-${_2(d.day)}';

  static String _formatTime(DateTime d) =>
      '${_2(d.hour)}-${_2(d.minute)}-${_2(d.second)}';

  static String _2(int n) => n.toString().padLeft(2, '0');

  static int _now() => DateTime.now().microsecondsSinceEpoch;
}

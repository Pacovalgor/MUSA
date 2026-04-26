import 'package:musa/modules/inbox/models/inbox_capture.dart';

/// Resultado de la detección de kind a partir del input crudo del usuario.
class KindDetectionResult {
  const KindDetectionResult({
    required this.kind,
    required this.body,
    this.url,
  });
  final InboxCaptureKind kind;
  final String body;
  final String? url;
}

/// Detecta si el input es texto, link puro, o texto con URL embebida.
///
/// Reglas (Ola 1):
/// 1. Si el input trimeado es UNA URL válida (http/https/file): kind=link,
///    url=trimeado, body="" (la URL "es" la captura).
/// 2. Si el input contiene una URL pero no es solo eso: kind=link,
///    url=la primera URL extraída, body=input completo (el comentario rodea
///    la URL).
/// 3. En cualquier otro caso: kind=text, url=null, body=input.
class KindDetectorService {
  const KindDetectorService();

  static final RegExp _urlPattern = RegExp(
    r'(https?|file)://[^\s<>" -]+',
    caseSensitive: false,
  );

  KindDetectionResult detect(String rawInput) {
    final trimmed = rawInput.trim();

    if (_isFullUrl(trimmed)) {
      return KindDetectionResult(
        kind: InboxCaptureKind.link,
        body: '',
        url: trimmed,
      );
    }

    final match = _urlPattern.firstMatch(rawInput);
    if (match != null) {
      return KindDetectionResult(
        kind: InboxCaptureKind.link,
        body: rawInput,
        url: match.group(0),
      );
    }

    return KindDetectionResult(
      kind: InboxCaptureKind.text,
      body: rawInput,
      url: null,
    );
  }

  bool _isFullUrl(String s) {
    if (s.isEmpty) return false;
    final m = _urlPattern.firstMatch(s);
    return m != null && m.start == 0 && m.end == s.length;
  }
}

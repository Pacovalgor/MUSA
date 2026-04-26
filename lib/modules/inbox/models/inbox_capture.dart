import 'package:flutter/foundation.dart';

/// Tipo de contenido de la captura. Ola 1 sólo expone text y link.
/// Olas posteriores añadirán voice (Ola 2) e image (Ola 3).
enum InboxCaptureKind { text, link }

/// Captura editorial inmutable depositada por un dispositivo en la carpeta
/// sincronizada y leída por el Mac (o por el propio iPhone para historial).
@immutable
class InboxCapture {
  const InboxCapture({
    required this.schemaVersion,
    required this.id,
    required this.capturedAt,
    required this.deviceLabel,
    required this.kind,
    required this.body,
    this.url,
    this.title,
    this.projectHint,
  });

  final int schemaVersion;
  final String id;
  final DateTime capturedAt; // siempre UTC
  final String deviceLabel;
  final InboxCaptureKind kind;
  final String body;
  final String? url;
  final String? title;
  final String? projectHint;

  /// Schema version soportada por esta versión del cliente.
  static const int currentSchemaVersion = 1;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
        'deviceLabel': deviceLabel,
        'kind': kind.name,
        'body': body,
        'url': url,
        'title': title,
        'projectHint': projectHint,
      };

  factory InboxCapture.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version is! int) {
      throw const FormatException('schemaVersion ausente o no es int');
    }
    if (version > currentSchemaVersion) {
      throw UnsupportedError(
        'schemaVersion $version no soportada por este cliente '
        '(máximo soportado: $currentSchemaVersion)',
      );
    }
    final id = json['id'];
    final capturedAtRaw = json['capturedAt'];
    final deviceLabel = json['deviceLabel'];
    final kindRaw = json['kind'];
    final body = json['body'];
    if (id is! String ||
        capturedAtRaw is! String ||
        deviceLabel is! String ||
        kindRaw is! String ||
        body is! String) {
      throw const FormatException('Campos requeridos ausentes o de tipo erróneo');
    }
    final kind = InboxCaptureKind.values.firstWhere(
      (k) => k.name == kindRaw,
      orElse: () =>
          throw FormatException('kind desconocido en Ola 1: "$kindRaw"'),
    );
    return InboxCapture(
      schemaVersion: version,
      id: id,
      capturedAt: DateTime.parse(capturedAtRaw).toUtc(),
      deviceLabel: deviceLabel,
      kind: kind,
      body: body,
      url: json['url'] as String?,
      title: json['title'] as String?,
      projectHint: json['projectHint'] as String?,
    );
  }

  InboxCapture copyWith({
    String? body,
    String? url,
    String? title,
  }) {
    return InboxCapture(
      schemaVersion: schemaVersion,
      id: id,
      capturedAt: capturedAt,
      deviceLabel: deviceLabel,
      kind: kind,
      body: body ?? this.body,
      url: url ?? this.url,
      title: title ?? this.title,
      projectHint: projectHint,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is InboxCapture && other.id == id && other.capturedAt == capturedAt;

  @override
  int get hashCode => Object.hash(id, capturedAt);
}

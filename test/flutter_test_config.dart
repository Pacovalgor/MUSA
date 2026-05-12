// Configuración global que se ejecuta automáticamente antes de cualquier test.
// Desactiva la descarga en red de Google Fonts para que los widget tests
// que usan MusaTheme funcionen correctamente en CI sin conexión.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}

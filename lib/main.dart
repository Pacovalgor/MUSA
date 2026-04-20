import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/adaptive/adaptive_router.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'modules/books/models/app_settings.dart';
import 'modules/books/providers/workspace_providers.dart';
import 'services/ia/embedded/management/model_persistence.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/widgets/musa_settings_dialog.dart';

/// Exposes whether the initial model onboarding has already been completed.
final onboardingCompletedProvider = Provider<bool>((ref) => false);

/// Global navigator used by native menu callbacks to open dialogs safely.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Boots Flutter, restores onboarding state and mounts the application shell.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Google Fonts to use system fonts as fallback and load asynchronously
  GoogleFonts.config.allowRuntimeFetching = true;
  // Ensure all plugins are initialized before accessing SharedPreferences
  try {
    final persistence = ModelPersistence();
    final onboardingCompleted = await persistence.isOnboardingCompleted();

    runApp(
      ProviderScope(
        overrides: [
          onboardingCompletedProvider.overrideWithValue(onboardingCompleted),
        ],
        child: const MusaApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');

    // Fallback: run app without onboarding state
    runApp(
      ProviderScope(
        overrides: [
          onboardingCompletedProvider.overrideWithValue(false),
        ],
        child: const MusaApp(),
      ),
    );
  }
}

/// Root application widget that wires theme, onboarding and adaptive routing.
class MusaApp extends ConsumerStatefulWidget {
  const MusaApp({super.key});

  @override
  ConsumerState<MusaApp> createState() => _MusaAppState();
}

class _MusaAppState extends ConsumerState<MusaApp> {
  static const _appMenuChannel = MethodChannel('musa/app_menu');

  @override
  void initState() {
    super.initState();
    _appMenuChannel.setMethodCallHandler(_handleAppMenuCall);
  }

  Future<void> _handleAppMenuCall(MethodCall call) async {
    switch (call.method) {
      case 'showSettings':
        final context = rootNavigatorKey.currentContext;
        if (context == null) return;
        await showDialog<void>(
          context: context,
          builder: (_) => const MusaSettingsDialog(),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCompletedOnboarding = ref.watch(onboardingCompletedProvider);
    final appSettings = ref.watch(appSettingsProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: MusaConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: MusaTheme.light,
      darkTheme: MusaTheme.dark,
      themeMode: appSettings.appearance == AppAppearance.dark ? ThemeMode.dark : ThemeMode.light,
      home: hasCompletedOnboarding ? const MusaAdaptiveRouter() : const ModelOnboardingScreen(),
    );
  }
}

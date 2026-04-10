import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'core/constants.dart';
import 'modules/books/models/app_settings.dart';
import 'modules/books/providers/workspace_providers.dart';
import 'ui/layout/main_screen.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/widgets/musa_settings_dialog.dart';
import 'services/ia/embedded/management/model_persistence.dart';

final onboardingCompletedProvider = Provider<bool>((ref) => false);
final rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
}

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
      themeMode: appSettings.appearance == AppAppearance.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: hasCompletedOnboarding
          ? const MusaMainScreen()
          : const ModelOnboardingScreen(),
    );
  }
}

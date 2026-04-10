import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/adaptive/adaptive_router.dart';
import '../../services/ia/embedded/management/model_manager.dart';
import '../../services/ia/embedded/management/model_catalog.dart';
import '../../services/ia/embedded/management/hardware_detector.dart';
import '../../services/ia/embedded/management/model_persistence.dart';

class ModelOnboardingScreen extends ConsumerStatefulWidget {
  const ModelOnboardingScreen({super.key});

  @override
  ConsumerState<ModelOnboardingScreen> createState() =>
      _ModelOnboardingScreenState();
}

class _ModelOnboardingScreenState extends ConsumerState<ModelOnboardingScreen> {
  final PageController _pageController = PageController();
  MacHardwareProfile? _profile;
  bool _isAdvancedMode = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isMacOS) {
      _detectHardware();
    }
  }

  Future<void> _detectHardware() async {
    final profile =
        await ref.read(modelManagerProvider.notifier).detectHardware();
    setState(() => _profile = profile);
  }

  Future<void> _finishOnboarding() async {
    final prefs = ModelPersistence();
    await prefs.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const MusaAdaptiveRouter(),
        transitionsBuilder: (context, anim1, anim2, child) {
          return FadeTransition(opacity: anim1, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isMacOS) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: _OnboardingBase(
          title: "MUSA Compose",
          subtitle:
              "En iPad, MUSA se abre como herramienta de composición y revisión local-first. La IA local completa sigue reservada para macOS por ahora; puedes escribir, revisar contexto y usar análisis editorial ligero.",
          buttonLabel: "Entrar a Compose",
          onPressed: _finishOnboarding,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildWelcomeStep(),
          _buildHardwareStep(),
          _buildDownloadStep(),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return _OnboardingBase(
      title: "Bienvenido a MUSA",
      subtitle:
          "Tu estudio de escritura soberano. La IA que te asiste vive íntegramente en tu Mac, sin enviar tus ideas a la nube.",
      buttonLabel: "Configurar mi Musa",
      onPressed: () => _pageController.nextPage(
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
    );
  }

  Widget _buildHardwareStep() {
    if (_profile == null) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.black12));
    }

    final recommended = ModelCatalog.findRecommended(_profile!);

    return _OnboardingBase(
      title: "Analizando tu Mac",
      subtitle:
          "Hemos detectado un ${_profile!.cpuBrand} con ${_profile!.totalRamGB}GB de RAM.",
      child: Column(
        children: [
          const SizedBox(height: 32),
          if (!_isAdvancedMode) ...[
            _buildModelCard(recommended, isRecommended: true),
            TextButton(
              onPressed: () => setState(() => _isAdvancedMode = true),
              child: const Text("Ver todas las opciones",
                  style: TextStyle(color: Colors.black38, fontSize: 12)),
            ),
          ] else ...[
            ...ModelCatalog.availableModels.map((m) =>
                _buildModelCard(m, isRecommended: m.id == recommended.id)),
          ],
        ],
      ),
      buttonLabel: "Descargar e Instalar",
      onPressed: () {
        final selected =
            _isAdvancedMode ? ModelCatalog.availableModels.first : recommended;
        ref.read(modelManagerProvider.notifier).startDownload(selected);
        _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      },
    );
  }

  Widget _buildDownloadStep() {
    final state = ref.watch(modelManagerProvider);
    final progress = state.downloadProgress.values.firstOrNull ?? 0.0;
    final isDone =
        state.activeModelId != null && state.downloadProgress.isEmpty;

    return _OnboardingBase(
      title: isDone ? "Tu Musa está lista." : "Preparando a tu Musa",
      subtitle: isDone
          ? "El modelo está instalado. Puedes empezar a escribir."
          : "Esto solo ocurre una vez. Después, la Musa vive en tu Mac.",
      child: Column(
        children: [
          const SizedBox(height: 48),
          SizedBox(
            width: 480,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: isDone ? 1.0 : progress,
                minHeight: 1,
                backgroundColor: Colors.black.withOpacity(0.05),
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (!isDone)
            Text(
              "${(progress * 100).toInt()}%",
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black26,
                letterSpacing: 1,
              ),
            ),
          const SizedBox(height: 40),
          const _ZenMessageCycler(),
          if (isDone) ...[
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _finishOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text("Empezar a escribir"),
            ),
          ] else ...[
            const SizedBox(height: 40),
            TextButton(
              onPressed: _finishOnboarding,
              child: const Text(
                "Continuar sin Musa por ahora",
                style: TextStyle(color: Colors.black38, fontSize: 13),
              ),
            ),
          ]
        ],
      ),
      showButton: false,
    );
  }

  Widget _buildModelCard(ModelDefinition model, {bool isRecommended = false}) {
    return Container(
      width: 450,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isRecommended ? Colors.black.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isRecommended
                ? Colors.black.withOpacity(0.1)
                : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(model.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    if (isRecommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text("RECOMENDADO",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(model.description,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(model.sizeDisplay,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black38)),
        ],
      ),
    );
  }
}

class _OnboardingBase extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? child;
  final String? buttonLabel;
  final VoidCallback? onPressed;
  final bool showButton;

  const _OnboardingBase({
    required this.title,
    required this.subtitle,
    this.child,
    this.buttonLabel,
    this.onPressed,
    this.showButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 800,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 500,
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, color: Colors.black38, height: 1.5),
              ),
            ),
            if (child != null) child!,
            const SizedBox(height: 48),
            if (showButton)
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(buttonLabel ?? ""),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Zen message cycler ───────────────────────────────────────────────────────

class _ZenMessageCycler extends StatefulWidget {
  const _ZenMessageCycler();

  @override
  State<_ZenMessageCycler> createState() => _ZenMessageCyclerState();
}

class _ZenMessageCyclerState extends State<_ZenMessageCycler> {
  static const _messages = [
    "Cada palabra que escribas seguirá siendo solo tuya.",
    "Pronto tendrás una mente que escucha sin juzgar.",
    "Tu primera frase ya existe en algún lugar.\nLa Musa te ayudará a encontrarla.",
    "El silencio también forma parte de la escritura.",
    "No hay prisa. Las mejores ideas llegan despacio.",
    "Aquí no hay nube. Solo tú, tu texto y una mente local.",
    "Los grandes escritores también necesitaban un espejo.",
    "Estamos preparando el espacio para que tu historia respire.",
    "La historia que tienes dentro merece ser escuchada.",
    "Tu Musa aprenderá a escucharte.\nTú nunca tendrás que explicarte.",
  ];

  int _index = 0;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 4200));
      if (!mounted) return false;
      setState(() => _index = (_index + 1) % _messages.length);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      height: 68,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 900),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: Text(
          _messages[_index],
          key: ValueKey(_index),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.75,
            color: Colors.black38,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

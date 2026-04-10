import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../modules/books/models/app_settings.dart';
import '../../modules/books/models/writing_settings.dart';
import '../../modules/books/models/musa_settings.dart';
import '../../modules/books/models/typography_settings.dart';
import '../../modules/books/providers/workspace_providers.dart';
import 'musa_wordmark.dart';

class MusaSettingsDialog extends ConsumerWidget {
  const MusaSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = MusaTheme.tokensOf(context);
    final palette = _SettingsPalette.of(context);
    final appSettings = ref.watch(appSettingsProvider);
    final settings = ref.watch(musaSettingsProvider);
    final typography = ref.watch(typographySettingsProvider);
    final writingSettings = ref.watch(writingSettingsProvider);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
      backgroundColor: tokens.canvasBackground,
      child: SizedBox(
        width: 960,
        child: Container(
          color: tokens.subtleBackground,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: tokens.textPrimary,
                inactiveTrackColor: tokens.borderStrong,
                trackHeight: 2,
                thumbColor: tokens.textPrimary,
                overlayColor: tokens.textPrimary.withValues(alpha: 0.08),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTickMarkColor: tokens.textPrimary,
                inactiveTickMarkColor: tokens.borderStrong,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const MusaWordmark(size: 20, compact: true),
                              const SizedBox(height: 10),
                              Text(
                                'Ajustes editoriales',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: tokens.textPrimary,
                                      fontSize: 31,
                                      letterSpacing: -0.7,
                                      height: 1.05,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Configura cómo quieres escribir y cómo deben intervenir las Musas.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: tokens.textSecondary,
                                      height: 1.55,
                                      fontSize: 15,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          color: tokens.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _SectionCard(
                      title: 'Interfaz',
                      children: [
                        _ChoiceField<AppAppearance>(
                          label: 'Apariencia de la app',
                          value: appSettings.appearance,
                          options: const [
                            _ChoiceOption(
                              value: AppAppearance.light,
                              title: 'Claro',
                              subtitle: 'Fondo limpio y luminoso para sesiones editoriales diurnas.',
                            ),
                            _ChoiceOption(
                              value: AppAppearance.dark,
                              title: 'Oscuro',
                              subtitle: 'Contraste más bajo y ambiente más calmado para trabajar de noche.',
                            ),
                          ],
                          onSelected: (value) => _saveAppSettings(
                            ref,
                            appSettings.copyWith(appearance: value),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _BooleanField(
                          label: 'Autoabrir paneles al acercar el cursor',
                          description:
                              'Al acercarte al borde izquierdo o derecho, MUSA desplegará el sidebar o el inspector sin usar botones en la barra.',
                          value: appSettings.edgeHoverPanelsEnabled,
                          onChanged: (value) => _saveAppSettings(
                            ref,
                            appSettings.copyWith(
                              edgeHoverPanelsEnabled: value,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Escritura',
                      children: [
                        Text(
                          'MUSA mantiene el foco en el texto. Las opciones de formato están pensadas para apoyar la escritura, no para maquetar el manuscrito.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: palette.textSecondary,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Presentación del texto',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _TwoColumnGrid(
                          children: [
                            _ChoiceField<EditorLineHeightMode>(
                              label: 'Interlineado',
                              value: writingSettings.lineHeightMode,
                              options: const [
                                _ChoiceOption(
                                  value: EditorLineHeightMode.compact,
                                  title: 'Compacto',
                                  subtitle: 'Líneas más juntas para máxima densidad.',
                                ),
                                _ChoiceOption(
                                  value: EditorLineHeightMode.standard,
                                  title: 'Estándar',
                                  subtitle: 'Equilibrio perfecto (por defecto).',
                                ),
                                _ChoiceOption(
                                  value: EditorLineHeightMode.relaxed,
                                  title: 'Amplio',
                                  subtitle: 'Mayor respiración visual entre líneas.',
                                ),
                              ],
                              onSelected: (value) => _saveWritingSettings(
                                ref,
                                writingSettings.copyWith(lineHeightMode: value),
                              ),
                            ),
                            _ChoiceField<EditorMaxWidthMode>(
                              label: 'Ancho de lectura',
                              value: writingSettings.maxWidthMode,
                              options: const [
                                _ChoiceOption(
                                  value: EditorMaxWidthMode.narrow,
                                  title: 'Estrecho',
                                  subtitle: 'Columnas cortas para lectura rápida.',
                                ),
                                _ChoiceOption(
                                  value: EditorMaxWidthMode.medium,
                                  title: 'Medio',
                                  subtitle: 'El ancho cómodo tradicional (por defecto).',
                                ),
                                _ChoiceOption(
                                  value: EditorMaxWidthMode.wide,
                                  title: 'Amplio',
                                  subtitle: 'Más palabras por línea en pantallas grandes.',
                                ),
                              ],
                              onSelected: (value) => _saveWritingSettings(
                                ref,
                                writingSettings.copyWith(maxWidthMode: value),
                              ),
                            ),
                            _ChoiceField<EditorParagraphSpacing>(
                              label: 'Separación entre párrafos',
                              value: writingSettings.paragraphSpacing,
                              options: const [
                                _ChoiceOption(
                                  value: EditorParagraphSpacing.normal,
                                  title: 'Normal',
                                  subtitle: 'Salto de línea tradicional.',
                                ),
                                _ChoiceOption(
                                  value: EditorParagraphSpacing.generous,
                                  title: 'Generosa',
                                  subtitle: 'Marcada separación entre las ideas.',
                                ),
                              ],
                              onSelected: (value) => _saveWritingSettings(
                                ref,
                                writingSettings.copyWith(paragraphSpacing: value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Comportamiento en el editor',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _TwoColumnGrid(
                          children: [
                            _BooleanField(
                              label: 'Modo Máquina de Escribir (Focus)',
                              description: 'Desplaza el papel automáticamente para que la línea actual se mantenga centrada en la pantalla.',
                              value: writingSettings.typewriterModeEnabled,
                              onChanged: (value) => _saveWritingSettings(
                                ref,
                                writingSettings.copyWith(typewriterModeEnabled: value),
                              ),
                            ),
                            _BooleanField(
                              label: 'Focus mode visual',
                              description:
                                  'Atenúa paneles periféricos mientras escribes para dejar más peso visual al manuscrito.',
                              value: writingSettings.focusModeEnabled,
                              onChanged: (value) => _saveWritingSettings(
                                ref,
                                writingSettings.copyWith(focusModeEnabled: value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Soporte de formato base (modo silencioso)',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _TwoColumnGrid(
                          children: [
                            _BooleanField(
                              label: 'Soporte de cursiva (Cmd + I)',
                              description: 'Permite añadir énfasis silenciosamente. No añade botones.',
                              value: writingSettings.enableItalics,
                              onChanged: (value) => _saveWritingSettings(
                                ref,
                                writingSettings.copyWith(enableItalics: value),
                              ),
                            ),
                            _BooleanField(
                              label: 'Soporte de negrita (Cmd + B)',
                              description: 'Permite marcar peso visual. No añade botones.',
                              value: writingSettings.enableBold,
                              onChanged: (value) => _saveWritingSettings(
                                ref,
                                writingSettings.copyWith(enableBold: value),
                              ),
                            ),
                            _ChoiceField<FormatRenderMode>(
                              label: 'Cómo prefieres ver el formato',
                              value: writingSettings.formatRenderMode,
                              options: const [
                                _ChoiceOption(
                                  value: FormatRenderMode.visual,
                                  title: 'Visual (Rich Text)',
                                  subtitle: 'Verás la cursiva o negrita real en la pantalla.',
                                ),
                                _ChoiceOption(
                                  value: FormatRenderMode.markdown,
                                  title: 'Marcado (Markdown)',
                                  subtitle: 'Verás los asteriscos de markdown intactos (*texto*).',
                                ),
                              ],
                              onSelected: (value) => _saveWritingSettings(
                                ref,
                                writingSettings.copyWith(formatRenderMode: value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Comportamiento de Notas',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _TwoColumnGrid(
                          children: [
                            _BooleanField(
                              label: 'Mostrar indicadores de notas en el texto',
                              description: 'Dibuja un subrayado punteado sutil en los fragmentos que tienen una nota anclada.',
                              value: writingSettings.showNoteMarkers,
                              onChanged: (value) => _saveWritingSettings(
                                ref,
                                writingSettings.copyWith(showNoteMarkers: value),
                              ),
                            ),
                            _ChoiceField<NoteOpenBehavior>(
                              label: 'Dónde se abren las notas',
                              value: writingSettings.noteOpenBehavior,
                              options: const [
                                _ChoiceOption(
                                  value: NoteOpenBehavior.sidebar,
                                  title: 'Panel Lateral (Focus)',
                                  subtitle: 'Cambia el contexto del editor a la nota para trabajar en ella.',
                                ),
                                _ChoiceOption(
                                  value: NoteOpenBehavior.inspector,
                                  title: 'En el Inspector (Multitarea)',
                                  subtitle: 'Abre la nota a la derecha pudiendo seguir viendo tu manuscrito al lado.',
                                ),
                              ],
                              onSelected: (value) => _saveWritingSettings(
                                ref,
                                writingSettings.copyWith(noteOpenBehavior: value),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Tipografía del proyecto',
                      children: [
                        Text(
                          'Define una voz visual para cada tipo de texto. Los cambios se guardan por proyecto y se aplican al editor.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: palette.textSecondary,
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: 20),
                        _TwoColumnGrid(
                          children: [
                            _TypographyRoleEditor(
                              role: TypographyRole.title,
                              settings: typography.title,
                              onChanged: (value) => _saveTypography(
                                ref,
                                typography.copyWith(title: value),
                              ),
                            ),
                            _TypographyRoleEditor(
                              role: TypographyRole.subtitle,
                              settings: typography.subtitle,
                              onChanged: (value) => _saveTypography(
                                ref,
                                typography.copyWith(subtitle: value),
                              ),
                            ),
                            _TypographyRoleEditor(
                              role: TypographyRole.body,
                              settings: typography.body,
                              onChanged: (value) => _saveTypography(
                                ref,
                                typography.copyWith(body: value),
                              ),
                            ),
                            _TypographyRoleEditor(
                              role: TypographyRole.note,
                              settings: typography.note,
                              onChanged: (value) => _saveTypography(
                                ref,
                                typography.copyWith(note: value),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Estilo editorial',
                      children: [
                        _TwoColumnGrid(
                          children: [
                            _ChoiceField<EditorialIntensity>(
                              label: 'Cuánto quieres que la Musa transforme tu texto',
                              value: settings.editorialIntensity,
                              options: const [
                                _ChoiceOption(
                                  value: EditorialIntensity.gentle,
                                  title: 'Suave',
                                  subtitle: 'La Musa tocará lo justo para mejorar el texto.',
                                ),
                                _ChoiceOption(
                                  value: EditorialIntensity.balanced,
                                  title: 'Equilibrada',
                                  subtitle: 'Mejora el texto sin cambiar demasiado tu forma de escribir.',
                                ),
                                _ChoiceOption(
                                  value: EditorialIntensity.expressive,
                                  title: 'Expresiva',
                                  subtitle: 'Se permite una mano más creativa al dar forma a la frase.',
                                ),
                              ],
                              onSelected: (value) => _saveMusa(
                                ref,
                                settings.copyWith(editorialIntensity: value),
                              ),
                            ),
                            _ChoiceField<PreferredEditorialTone>(
                              label: 'Qué tipo de reescritura prefieres por defecto',
                              value: settings.preferredEditorialTone,
                              options: const [
                                _ChoiceOption(
                                  value: PreferredEditorialTone.sober,
                                  title: 'Sobrio',
                                  subtitle: 'Más contención y menos adorno.',
                                ),
                                _ChoiceOption(
                                  value: PreferredEditorialTone.literary,
                                  title: 'Literario',
                                  subtitle: 'Más cuidado en la prosa y en el matiz.',
                                ),
                                _ChoiceOption(
                                  value: PreferredEditorialTone.tense,
                                  title: 'Tenso',
                                  subtitle: 'Más nervio y una inquietud más visible.',
                                ),
                                _ChoiceOption(
                                  value: PreferredEditorialTone.clear,
                                  title: 'Claro',
                                  subtitle: 'Más limpieza y una lectura más directa.',
                                ),
                              ],
                              onSelected: (value) => _saveMusa(
                                ref,
                                settings.copyWith(
                                  preferredEditorialTone: value,
                                ),
                              ),
                            ),
                            _ChoiceField<OutputLanguageMode>(
                              label: 'Idioma en el que debe responder la Musa',
                              value: settings.outputLanguageMode,
                              options: const [
                                _ChoiceOption(
                                  value: OutputLanguageMode.matchSelection,
                                  title: 'Igual que el texto seleccionado',
                                  subtitle: 'La Musa seguirá el idioma del fragmento.',
                                ),
                                _ChoiceOption(
                                  value: OutputLanguageMode.spanish,
                                  title: 'Siempre en español',
                                  subtitle: 'La Musa responderá siempre en español.',
                                ),
                                _ChoiceOption(
                                  value: OutputLanguageMode.english,
                                  title: 'Siempre en inglés',
                                  subtitle: 'La Musa responderá siempre en inglés.',
                                ),
                              ],
                              onSelected: (value) => _saveMusa(
                                ref,
                                settings.copyWith(outputLanguageMode: value),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Control del fragmento',
                      children: [
                        _TwoColumnGrid(
                          children: [
                            _ChoiceField<FragmentFidelity>(
                              label: 'Qué fiel quieres que sea la Musa al fragmento original',
                              value: settings.fragmentFidelity,
                              options: const [
                                _ChoiceOption(
                                  value: FragmentFidelity.veryFaithful,
                                  title: 'Muy fiel',
                                  subtitle: 'Cambiará muy poco y se pegará al original.',
                                ),
                                _ChoiceOption(
                                  value: FragmentFidelity.faithful,
                                  title: 'Fiel',
                                  subtitle: 'Mejorará el texto sin apartarse de él.',
                                ),
                                _ChoiceOption(
                                  value: FragmentFidelity.freer,
                                  title: 'Con un poco más de libertad',
                                  subtitle: 'Podrá reformular un poco más la frase sin perder su sentido.',
                                ),
                              ],
                              onSelected: (value) => _saveMusa(
                                ref,
                                settings.copyWith(fragmentFidelity: value),
                              ),
                            ),
                            _ChoiceField<ScopeProtection>(
                              label: 'Hasta qué punto puede salirse del fragmento',
                              value: settings.scopeProtection,
                              options: const [
                                _ChoiceOption(
                                  value: ScopeProtection.strict,
                                  title: 'Estricto',
                                  subtitle: 'Si se sale del fragmento, la propuesta se bloqueará.',
                                ),
                                _ChoiceOption(
                                  value: ScopeProtection.balanced,
                                  title: 'Equilibrado',
                                  subtitle: 'Si se abre un poco, te lo avisaremos y podrás decidir.',
                                ),
                                _ChoiceOption(
                                  value: ScopeProtection.flexible,
                                  title: 'Flexible',
                                  subtitle: 'Le daremos algo más de aire si la frase lo pide.',
                                ),
                              ],
                              onSelected: (value) => _saveMusa(
                                ref,
                                settings.copyWith(scopeProtection: value),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Musas',
                      children: [
                        _TwoColumnGrid(
                          children: [
                            _ChoiceField<StyleMusaIntensity>(
                              label: 'Musa de Estilo',
                              value: settings.styleIntensity,
                              options: const [
                                _ChoiceOption(
                                  value: StyleMusaIntensity.contained,
                                  title: 'Contenida',
                                  subtitle: 'Pulirá sin mover apenas la frase.',
                                ),
                                _ChoiceOption(
                                  value: StyleMusaIntensity.balanced,
                                  title: 'Equilibrada',
                                  subtitle: 'Refinará con tacto y buena medida.',
                                ),
                                _ChoiceOption(
                                  value: StyleMusaIntensity.expressive,
                                  title: 'Más expresiva',
                                  subtitle: 'Podrá dar más relieve al lenguaje.',
                                ),
                              ],
                              onSelected: (value) => _saveMusa(
                                ref,
                                settings.copyWith(styleIntensity: value),
                              ),
                            ),
                            _ChoiceField<TensionMusaIntensity>(
                              label: 'Musa de Tensión',
                              value: settings.tensionIntensity,
                              options: const [
                                _ChoiceOption(
                                  value: TensionMusaIntensity.subtle,
                                  title: 'Sutil',
                                  subtitle: 'Añadirá inquietud con mucha contención.',
                                ),
                                _ChoiceOption(
                                  value: TensionMusaIntensity.medium,
                                  title: 'Media',
                                  subtitle: 'Subirá la tensión sin perder la medida.',
                                ),
                                _ChoiceOption(
                                  value: TensionMusaIntensity.marked,
                                  title: 'Marcada',
                                  subtitle: 'Marcará más el nervio de la frase.',
                                ),
                              ],
                              onSelected: (value) => _saveMusa(
                                ref,
                                settings.copyWith(tensionIntensity: value),
                              ),
                            ),
                            _ChoiceField<RhythmMusaIntensity>(
                              label: 'Musa de Ritmo',
                              value: settings.rhythmIntensity,
                              options: const [
                                _ChoiceOption(
                                  value: RhythmMusaIntensity.light,
                                  title: 'Ligera',
                                  subtitle: 'Retocará el ritmo sin mover demasiado la frase.',
                                ),
                                _ChoiceOption(
                                  value: RhythmMusaIntensity.medium,
                                  title: 'Media',
                                  subtitle: 'Buscará una lectura más fluida y natural.',
                                ),
                                _ChoiceOption(
                                  value: RhythmMusaIntensity.corrective,
                                  title: 'Correctiva',
                                  subtitle: 'Reordenará con más decisión si la frase lo necesita.',
                                ),
                              ],
                              onSelected: (value) => _saveMusa(
                                ref,
                                settings.copyWith(rhythmIntensity: value),
                              ),
                            ),
                            _ChoiceField<ClarityMusaIntensity>(
                              label: 'Musa de Claridad',
                              value: settings.clarityIntensity,
                              options: const [
                                _ChoiceOption(
                                  value: ClarityMusaIntensity.light,
                                  title: 'Ligera',
                                  subtitle: 'Despejará lo justo sin volverlo plano.',
                                ),
                                _ChoiceOption(
                                  value: ClarityMusaIntensity.medium,
                                  title: 'Media',
                                  subtitle: 'Hará la frase más clara sin perder tono.',
                                ),
                                _ChoiceOption(
                                  value: ClarityMusaIntensity.strict,
                                  title: 'Estricta',
                                  subtitle: 'Priorizará nitidez y precisión por encima de todo.',
                                ),
                              ],
                              onSelected: (value) => _saveMusa(
                                ref,
                                settings.copyWith(clarityIntensity: value),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Acompañamiento de MUSA',
                      children: [
                        _ChoiceField<VisualPresence>(
                          label: 'Cómo quieres que MUSA te acompañe mientras trabaja',
                          value: settings.visualPresence,
                          options: const [
                            _ChoiceOption(
                              value: VisualPresence.visible,
                              title: 'Visible',
                              subtitle: 'Verás con claridad que la Musa está trabajando.',
                            ),
                            _ChoiceOption(
                              value: VisualPresence.subtle,
                              title: 'Sutil',
                              subtitle: 'Acompañará de forma discreta y elegante.',
                            ),
                            _ChoiceOption(
                              value: VisualPresence.minimal,
                              title: 'Mínima',
                              subtitle: 'Se hará notar lo mínimo mientras trabaja.',
                            ),
                          ],
                          onSelected: (value) => _saveMusa(
                            ref,
                            settings.copyWith(visualPresence: value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveMusa(WidgetRef ref, MusaSettings settings) {
    ref.read(narrativeWorkspaceProvider.notifier).updateMusaSettings(settings);
  }

  void _saveTypography(WidgetRef ref, TypographySettings settings) {
    ref.read(narrativeWorkspaceProvider.notifier).updateTypographySettings(settings);
  }

  void _saveAppSettings(WidgetRef ref, AppSettings settings) {
    ref.read(narrativeWorkspaceProvider.notifier).updateAppSettings(settings);
  }

  void _saveWritingSettings(WidgetRef ref, WritingSettings settings) {
    ref.read(narrativeWorkspaceProvider.notifier).updateWritingSettings(settings);
  }
}

class _SettingsPalette {
  const _SettingsPalette({
    required this.sectionBackground,
    required this.softSurface,
    required this.softSurfaceAlt,
    required this.selectedSurface,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  final Color sectionBackground;
  final Color softSurface;
  final Color softSurfaceAlt;
  final Color selectedSurface;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  static _SettingsPalette of(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return _SettingsPalette(
      sectionBackground: tokens.canvasBackground,
      softSurface: tokens.panelBackground,
      softSurfaceAlt: tokens.subtleBackground,
      selectedSurface: tokens.canvasBackground,
      border: tokens.borderSubtle,
      borderStrong: tokens.borderStrong,
      textPrimary: tokens.textPrimary,
      textSecondary: tokens.textSecondary,
      textTertiary: tokens.textMuted,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: palette.sectionBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: palette.border.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _TwoColumnGrid extends StatelessWidget {
  const _TwoColumnGrid({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: 22),
        ],
      ],
    );
  }
}

class _ChoiceField<T extends Enum> extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final T value;
  final List<_ChoiceOption<T>> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: options.map((option) {
            final isSelected = option.value == value;
            return _ChoiceCard(
              title: option.title,
              subtitle: option.subtitle,
              selected: isSelected,
              onTap: () => onSelected(option.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatefulWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    final selected = widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 256,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
          decoration: BoxDecoration(
            color: selected ? palette.selectedSurface : palette.softSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? palette.borderStrong
                  : palette.border.withValues(alpha: 0.82),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              if (_hovered || selected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: selected ? 0.028 : 0.014),
                  blurRadius: selected ? 8 : 6,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: palette.textPrimary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BooleanField extends StatelessWidget {
  const _BooleanField({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: palette.softSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: palette.border.withValues(alpha: 0.82),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.textSecondary,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: palette.textPrimary,
            activeTrackColor: palette.textPrimary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _ChoiceOption<T extends Enum> {
  const _ChoiceOption({
    required this.value,
    required this.title,
    required this.subtitle,
  });

  final T value;
  final String title;
  final String subtitle;
}

class _TypographyRoleEditor extends StatelessWidget {
  const _TypographyRoleEditor({
    required this.role,
    required this.settings,
    required this.onChanged,
  });

  final TypographyRole role;
  final TypographyStyleSettings settings;
  final ValueChanged<TypographyStyleSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    final previewStyle = settings
        .applyTo(
          Theme.of(context).textTheme.bodyLarge,
        )
        .copyWith(
          color: palette.textPrimary,
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: palette.softSurfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: palette.border.withValues(alpha: 0.82),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _labelForRole(role),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _descriptionForRole(role),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final controls = [
                Expanded(
                  child: _DropdownField<String>(
                    label: 'Tipografía',
                    value: settings.fontFamily,
                    items: _fontOptions,
                    itemLabel: (value) => value.isEmpty ? 'Sistema' : value,
                    onChanged: (value) {
                      if (value == null) return;
                      onChanged(settings.copyWith(fontFamily: value));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DropdownField<TypographyStylePreset>(
                    label: 'Estilo',
                    value: settings.stylePreset,
                    items: TypographyStylePreset.values,
                    itemLabel: _labelForStylePreset,
                    onChanged: (value) {
                      if (value == null) return;
                      onChanged(settings.copyWith(stylePreset: value));
                    },
                  ),
                ),
              ];

              if (constraints.maxWidth >= 560) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: controls,
                );
              }

              return Column(
                children: [
                  _DropdownField<String>(
                    label: 'Tipografía',
                    value: settings.fontFamily,
                    items: _fontOptions,
                    itemLabel: (value) => value.isEmpty ? 'Sistema' : value,
                    onChanged: (value) {
                      if (value == null) return;
                      onChanged(settings.copyWith(fontFamily: value));
                    },
                  ),
                  const SizedBox(height: 12),
                  _DropdownField<TypographyStylePreset>(
                    label: 'Estilo',
                    value: settings.stylePreset,
                    items: TypographyStylePreset.values,
                    itemLabel: _labelForStylePreset,
                    onChanged: (value) {
                      if (value == null) return;
                      onChanged(settings.copyWith(stylePreset: value));
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _SliderField(
            label: 'Tamaño',
            value: settings.fontSize,
            min: _minFontSize(role),
            max: _maxFontSize(role),
            suffix: 'pt',
            onChanged: (value) => onChanged(settings.copyWith(fontSize: value)),
          ),
          const SizedBox(height: 12),
          _SliderField(
            label: 'Interlineado',
            value: settings.lineHeight,
            min: 1.0,
            max: 2.0,
            suffix: 'x',
            onChanged: (value) => onChanged(settings.copyWith(lineHeight: value)),
          ),
          const SizedBox(height: 14),
          Text(
            'Vista previa',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.sectionBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Text(
              _previewTextForRole(role),
              style: previewStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: palette.sectionBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: palette.border.withValues(alpha: 0.78),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: palette.border.withValues(alpha: 0.78),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: palette.borderStrong),
            ),
          ),
        ),
      ],
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    final safeValue = value.clamp(min, max).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
            ),
            const Spacer(),
            Text(
              '${safeValue.toStringAsFixed(suffix == 'pt' ? 0 : 2)} $suffix',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textTertiary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Slider(
          value: safeValue,
          min: min,
          max: max,
          divisions: suffix == 'pt' ? (max - min).round() : ((max - min) * 20).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

const List<String> _fontOptions = [
  '',
  'Georgia',
  'Helvetica Neue',
  'Times New Roman',
  'Courier New',
];

String _labelForRole(TypographyRole role) => switch (role) {
      TypographyRole.title => 'Título',
      TypographyRole.subtitle => 'Subtítulo',
      TypographyRole.body => 'Cuerpo',
      TypographyRole.note => 'Nota',
    };

String _descriptionForRole(TypographyRole role) => switch (role) {
      TypographyRole.title => 'Encabezados principales y títulos de documento.',
      TypographyRole.subtitle => 'Bajadas, apoyos y líneas secundarias.',
      TypographyRole.body => 'Texto principal del manuscrito o capítulo.',
      TypographyRole.note => 'Contenido de notas y escritura auxiliar.',
    };

String _previewTextForRole(TypographyRole role) => switch (role) {
      TypographyRole.title => 'La casa frente al mar',
      TypographyRole.subtitle => 'Un regreso, una deuda, una noche de agosto.',
      TypographyRole.body => 'La puerta seguía allí, igual que en mi infancia, aunque la pintura ya no resistía el salitre.',
      TypographyRole.note => 'Nota: revisar esta escena y añadir la reacción de Clara al final del párrafo.',
    };

String _labelForStylePreset(TypographyStylePreset preset) => switch (preset) {
      TypographyStylePreset.light => 'Ligera',
      TypographyStylePreset.regular => 'Regular',
      TypographyStylePreset.medium => 'Media',
      TypographyStylePreset.semibold => 'Semibold',
      TypographyStylePreset.bold => 'Negrita',
      TypographyStylePreset.italic => 'Cursiva',
      TypographyStylePreset.semiboldItalic => 'Semibold cursiva',
    };

double _minFontSize(TypographyRole role) => switch (role) {
      TypographyRole.title => 20,
      TypographyRole.subtitle => 14,
      TypographyRole.body => 14,
      TypographyRole.note => 12,
    };

double _maxFontSize(TypographyRole role) => switch (role) {
      TypographyRole.title => 48,
      TypographyRole.subtitle => 32,
      TypographyRole.body => 30,
      TypographyRole.note => 28,
    };

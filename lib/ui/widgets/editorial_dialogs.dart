import 'package:flutter/material.dart';

import '../../core/theme.dart';

class EditorialDialogs {
  static Future<String?> promptForText(
    BuildContext context, {
    required String title,
    required String label,
    required String initialValue,
    required String actionLabel,
    String? hintText,
  }) async {
    var currentValue = initialValue;

    return showDialog<String>(
      context: context,
      builder: (context) {
        final tokens = MusaTheme.tokensOf(context);
        return Dialog(
          backgroundColor: tokens.canvasBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            side: BorderSide(color: tokens.borderSubtle),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: initialValue,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: label,
                      hintText: hintText,
                      labelStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: tokens.textSecondary,
                              ),
                      hintStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: tokens.textMuted,
                              ),
                      filled: true,
                      fillColor: tokens.subtleBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusMd),
                        borderSide: BorderSide(color: tokens.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusMd),
                        borderSide: BorderSide(color: tokens.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusMd),
                        borderSide: BorderSide(color: tokens.borderStrong),
                      ),
                    ),
                    onChanged: (value) => currentValue = value,
                    onFieldSubmitted: (value) {
                      final trimmed = value.trim();
                      Navigator.of(context)
                          .pop(trimmed.isEmpty ? null : trimmed);
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: tokens.textSecondary,
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final trimmed = currentValue.trim();
                          Navigator.of(context)
                              .pop(trimmed.isEmpty ? null : trimmed);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: tokens.textPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(actionLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<bool> confirmDestructive(
    BuildContext context, {
    required String title,
    required String message,
    String cancelLabel = 'Cancelar',
    String confirmLabel = 'Eliminar',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final tokens = MusaTheme.tokensOf(context);
        return Dialog(
          backgroundColor: tokens.canvasBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            side: BorderSide(color: tokens.borderSubtle),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: tokens.textSecondary,
                        ),
                        child: Text(cancelLabel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: tokens.textPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(confirmLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result ?? false;
  }
}

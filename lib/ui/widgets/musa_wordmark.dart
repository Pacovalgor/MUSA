import 'package:flutter/material.dart';

import '../../core/theme.dart';

class MusaWordmark extends StatelessWidget {
  const MusaWordmark({
    super.key,
    this.size = 28,
    this.compact = false,
  });

  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = MusaTheme.tokensOf(context);
    return Text(
      'MUSA',
      maxLines: 1,
      overflow: TextOverflow.visible,
      style: MusaTheme.wordmarkStyle(context, size: size).copyWith(
        letterSpacing: compact ? 0.12 * size / 28 : 0.14 * size / 28,
        color: tokens.textPrimary,
      ),
    );
  }
}

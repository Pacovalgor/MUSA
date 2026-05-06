import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/editor_controller.dart';

class ComparisonView extends ConsumerWidget {
  const ComparisonView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final suggestion = editorState.currentSuggestion;
    final selection = editorState.selectionContext;

    if (suggestion == null || selection == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Original
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader('ORIGINAL'),
                    const SizedBox(height: 12),
                    Text(
                      selection.selectedText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.black54,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.red.withValues(alpha: 0.3),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(width: 1, height: 100, color: Colors.black12),
              const SizedBox(width: 20),
              // Suggestion
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader('PROPUESTA'),
                    const SizedBox(height: 12),
                    Text(
                      suggestion.suggestedText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.green.shade800,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (suggestion.editorComment?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 18),
            Container(height: 1, color: Colors.black12),
            const SizedBox(height: 12),
            _buildHeader('NOTA'),
            const SizedBox(height: 8),
            Text(
              suggestion.editorComment!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.black26,
        letterSpacing: 1.2,
      ),
    );
  }
}

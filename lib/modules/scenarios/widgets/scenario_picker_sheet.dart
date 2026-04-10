import 'package:flutter/material.dart';

import '../models/scenario.dart';

Future<Scenario?> showScenarioPickerSheet(
  BuildContext context, {
  required List<Scenario> scenarios,
  required List<String> linkedScenarioIds,
  String title = 'Vincular a escenario',
  String? description,
  bool showLinkedState = true,
}) {
  return showModalBottomSheet<Scenario>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                scenarios.isEmpty
                    ? 'Todavía no hay escenarios en este libro.'
                    : (description ?? 'Elige un escenario del libro activo.'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
              ),
              const SizedBox(height: 18),
              if (scenarios.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Crea uno nuevo desde la selección o desde la sidebar.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black38,
                        ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: scenarios.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final scenario = scenarios[index];
                      final isLinked = linkedScenarioIds.contains(scenario.id);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(scenario.displayName),
                        subtitle: Text(
                          scenario.role.trim().isNotEmpty
                              ? scenario.role
                              : scenario.summary.trim().isNotEmpty
                                  ? scenario.summary
                                  : 'Ficha editorial en construcción',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: showLinkedState && isLinked
                            ? Text(
                                'Ya está',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.black38,
                                      fontWeight: FontWeight.w600,
                                    ),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => Navigator.of(context).pop(scenario),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Etiqueta pequeña de estado ("Agotado", "Descontinuado").
class EtiquetaEstado extends StatelessWidget {
  const EtiquetaEstado({super.key, required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        texto,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }
}

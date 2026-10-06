import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Tarjeta con un dato grande y su etiqueta (p. ej. "Vendido hoy" / "$150.00").
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              etiqueta,
              style: tema.textTheme.titleSmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor, style: tema.textTheme.headlineMedium),
            ),
          ],
        ),
      ),
    );
  }
}

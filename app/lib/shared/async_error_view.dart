import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../core/theme.dart';

/// Estado de carga y de error común a las tres pantallas.
/// Con [cargando] muestra un spinner; si no, el mensaje de [error] con el
/// botón "Reintentar".
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({
    super.key,
    this.cargando = false,
    this.error,
    this.onReintentar,
  });

  final bool cargando;
  final Object? error;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: AppSizes.iconoGrande,
              color: tema.colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              error == null ? 'Algo salió mal.' : mensajeDeError(error!),
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyLarge,
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

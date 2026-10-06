import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import 'sales_controller.dart';

/// Panel fijo abajo: renglones del carrito, total y botón "Cobrar".
class CartPanel extends StatelessWidget {
  const CartPanel({
    super.key,
    required this.lineas,
    required this.total,
    required this.cobrando,
    required this.onSumar,
    required this.onRestar,
    required this.onCobrar,
  });

  final List<LineaCarrito> lineas;
  final double total;
  final bool cobrando;
  final ValueChanged<LineaCarrito> onSumar;
  final ValueChanged<LineaCarrito> onRestar;
  final VoidCallback onCobrar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Material(
      color: tema.colorScheme.surfaceContainer,
      elevation: AppSizes.elevacionPanel,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lineas.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Carrito vacío. Toca un producto para agregarlo.',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: AppSizes.altoMaxLineasCarrito,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final l in lineas)
                      _LineaTile(
                        linea: l,
                        onSumar: () => onSumar(l),
                        onRestar: () => onRestar(l),
                      ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total', style: tema.textTheme.labelMedium),
                      Text(
                        formatoDinero(total),
                        style: tema.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: lineas.isEmpty || cobrando ? null : onCobrar,
                  child: cobrando
                      ? const SizedBox(
                          width: AppSpacing.lg,
                          height: AppSpacing.lg,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cobrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineaTile extends StatelessWidget {
  const _LineaTile({
    required this.linea,
    required this.onSumar,
    required this.onRestar,
  });

  final LineaCarrito linea;
  final VoidCallback onSumar;
  final VoidCallback onRestar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                linea.producto.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tema.textTheme.titleSmall,
              ),
              Text(
                formatoDinero(linea.producto.salePrice),
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Quitar uno',
          onPressed: onRestar,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: AppSpacing.lg,
          child: Text(
            '${linea.cantidad}',
            textAlign: TextAlign.center,
            style: tema.textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Agregar uno',
          onPressed: onSumar,
          icon: const Icon(Icons.add_circle_outline),
        ),
        SizedBox(
          width: AppSizes.anchoSubtotal,
          child: Text(
            formatoDinero(linea.subtotal),
            textAlign: TextAlign.right,
            style: tema.textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}

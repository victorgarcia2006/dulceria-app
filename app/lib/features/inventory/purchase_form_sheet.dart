import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../shared/campos_texto.dart';
import '../../shared/form_sheet.dart';
import 'inventory_controller.dart';

/// Formulario "Recibir mercancía": registra una compra y suma existencias.
class PurchaseFormSheet extends StatefulWidget {
  const PurchaseFormSheet({
    super.key,
    required this.controller,
    required this.producto,
  });

  final InventoryController controller;
  final Product producto;

  @override
  State<PurchaseFormSheet> createState() => _PurchaseFormSheetState();
}

class _PurchaseFormSheetState extends State<PurchaseFormSheet> {
  final _form = GlobalKey<FormState>();
  final _cantidad = TextEditingController();
  // Se pre-llena con el costo actual del producto.
  late final _costo = TextEditingController(
    text: widget.producto.costPrice.toStringAsFixed(2),
  );
  bool _guardando = false;
  Object? _error;

  @override
  void dispose() {
    _cantidad.dispose();
    _costo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await widget.controller.recibirMercancia(
        widget.producto,
        cantidad: parseCantidad(_cantidad.text)!,
        costoUnitario: parseDinero(_costo.text)!,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Recibir mercancía', style: tema.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${widget.producto.name} · ${textoExistencias(widget.producto.existencias)}',
            style: tema.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Esta es la única forma de aumentar las existencias; nunca se editan directamente. '
            'El costo que escribas pasa a ser el costo actual del producto.',
            style: tema.textTheme.bodyMedium
                ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          CampoCantidad(
            controller: _cantidad,
            etiqueta: 'Cantidad recibida',
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.md),
          CampoDinero(
            controller: _costo,
            etiqueta: 'Costo por unidad',
            textInputAction: TextInputAction.done,
            alEnviar: _guardar,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_error != null) ErrorDeFormulario(error: _error!),
          FilledButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: AppSpacing.lg,
                    height: AppSpacing.lg,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Recibir'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../shared/campos_texto.dart';
import '../../shared/form_sheet.dart';
import 'inventory_controller.dart';

/// Formulario para agregar un producto nuevo o, si se pasa [producto], editarlo.
class ProductFormSheet extends StatefulWidget {
  const ProductFormSheet({super.key, required this.controller, this.producto});

  final InventoryController controller;
  final Product? producto;

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.producto?.name);
  late final _costo = TextEditingController(
    text: widget.producto?.costPrice.toStringAsFixed(2),
  );
  late final _precio = TextEditingController(
    text: widget.producto?.salePrice.toStringAsFixed(2),
  );
  bool _guardando = false;
  Object? _error;

  bool get _editando => widget.producto != null;

  @override
  void dispose() {
    _nombre.dispose();
    _costo.dispose();
    _precio.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final nombre = _nombre.text.trim();
    final costo = parseDinero(_costo.text)!;
    final precio = parseDinero(_precio.text)!;
    try {
      if (_editando) {
        await widget.controller.editarProducto(
          widget.producto!,
          nombre: nombre,
          costo: costo,
          precioVenta: precio,
        );
      } else {
        await widget.controller.agregarProducto(
          nombre: nombre,
          costo: costo,
          precioVenta: precio,
        );
      }
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
          Text(
            _editando ? 'Editar producto' : 'Agregar producto',
            style: tema.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _editando
                ? 'Las existencias no se editan aquí: cambian al recibir mercancía y al vender.'
                : 'Las existencias empiezan en 0. Para tener unidades disponibles, usa «Recibir mercancía».',
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Nombre'),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: validarNombre,
          ),
          const SizedBox(height: AppSpacing.md),
          CampoDinero(controller: _costo, etiqueta: 'Costo'),
          const SizedBox(height: AppSpacing.md),
          CampoDinero(
            controller: _precio,
            etiqueta: 'Precio de venta',
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
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

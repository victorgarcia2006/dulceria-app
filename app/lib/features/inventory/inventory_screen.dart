import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/dulceria_api.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/async_error_view.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/etiqueta_estado.dart';
import '../../shared/form_sheet.dart';
import 'inventory_controller.dart';
import 'product_form_sheet.dart';
import 'purchase_form_sheet.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // La pestaña se recrea cada vez que se entra, así que carga datos frescos.
    return ChangeNotifierProvider(
      create: (context) =>
          InventoryController(context.read<DulceriaApi>())..cargar(),
      child: const _InventoryView(),
    );
  }
}

enum _Accion { recibir, editar, descontinuar }

class _InventoryView extends StatelessWidget {
  const _InventoryView();

  void _avisar(BuildContext context, String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _agregar(BuildContext context) async {
    final c = context.read<InventoryController>();
    final guardado = await mostrarFormSheet<bool>(
      context,
      (_) => ProductFormSheet(controller: c),
    );
    if (guardado == true && context.mounted) {
      _avisar(context, 'Producto agregado. Sus existencias empiezan en 0.');
    }
  }

  Future<void> _ejecutar(
    BuildContext context,
    Product producto,
    _Accion accion,
  ) async {
    final c = context.read<InventoryController>();
    switch (accion) {
      case _Accion.recibir:
        final guardado = await mostrarFormSheet<bool>(
          context,
          (_) => PurchaseFormSheet(controller: c, producto: producto),
        );
        if (guardado == true && context.mounted) {
          _avisar(context, 'Mercancía recibida: ${producto.name}.');
        }
      case _Accion.editar:
        final guardado = await mostrarFormSheet<bool>(
          context,
          (_) => ProductFormSheet(controller: c, producto: producto),
        );
        if (guardado == true && context.mounted) {
          _avisar(context, 'Cambios guardados.');
        }
      case _Accion.descontinuar:
        final confirmado = await ConfirmDialog.mostrar(
          context,
          titulo: 'Descontinuar producto',
          mensaje:
              '¿Descontinuar ${producto.name}? Ya no aparecerá en Vender, pero se conserva su historial de ventas.',
          textoConfirmar: 'Descontinuar',
        );
        if (!confirmado) return;
        try {
          await c.descontinuar(producto);
          if (context.mounted) {
            _avisar(context, '${producto.name} se descontinuó.');
          }
        } catch (e) {
          if (context.mounted) _avisar(context, mensajeDeError(e));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InventoryController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      body: _cuerpo(context, c),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _agregar(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar producto'),
      ),
    );
  }

  Widget _cuerpo(BuildContext context, InventoryController c) {
    if (c.error != null) {
      return AsyncErrorView(error: c.error, onReintentar: c.cargar);
    }
    if (!c.cargado) return const AsyncErrorView(cargando: true);
    return RefreshIndicator(
      onRefresh: () => c.cargar(limpiar: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Espacio abajo para que el botón flotante no tape el último producto.
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xl * 3,
        ),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mostrar descontinuados'),
            value: c.mostrarDescontinuados,
            onChanged: c.cambiarMostrarDescontinuados,
          ),
          if (c.productos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Todavía no hay productos. Toca «Agregar producto» para empezar.',
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final p in c.productos)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ProductoTile(
                  producto: p,
                  onAccion: (a) => _ejecutar(context, p, a),
                ),
              ),
        ],
      ),
    );
  }
}

class _ProductoTile extends StatelessWidget {
  const _ProductoTile({required this.producto, required this.onAccion});

  final Product producto;
  final ValueChanged<_Accion> onAccion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final descontinuado = !producto.active;
    return Opacity(
      opacity: descontinuado ? 0.6 : 1,
      child: Card(
        child: ListTile(
          title: Text(producto.name),
          subtitle: Text(
            '${textoExistencias(producto.existencias)}'
            ' · Costo ${formatoDinero(producto.costPrice)}'
            ' · Venta ${formatoDinero(producto.salePrice)}',
          ),
          trailing: descontinuado
              ? EtiquetaEstado(
                  texto: 'Descontinuado',
                  color: tema.colorScheme.outline,
                )
              : PopupMenuButton<_Accion>(
                  tooltip: 'Acciones',
                  onSelected: onAccion,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _Accion.recibir,
                      child: Text('Recibir mercancía'),
                    ),
                    PopupMenuItem(value: _Accion.editar, child: Text('Editar')),
                    PopupMenuItem(
                      value: _Accion.descontinuar,
                      child: Text('Descontinuar'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

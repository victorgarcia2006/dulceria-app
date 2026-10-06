import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/async_error_view.dart';
import '../../shared/etiqueta_estado.dart';
import '../../shared/message_dialog.dart';
import 'cart_panel.dart';
import 'sales_controller.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  @override
  void initState() {
    super.initState();
    // La pestaña se recrea al entrar: recarga el catálogo con datos frescos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SalesController>().cargar();
    });
  }

  final _panelKey = GlobalKey();

  /// SnackBar que se muestra por encima del panel del carrito (sin tapar el
  /// total ni el botón "Cobrar").
  void _avisar(String texto) {
    final alturaPanel = _panelKey.currentContext?.size?.height ?? 0;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          margin: EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            alturaPanel + AppSpacing.sm,
          ),
        ),
      );
  }

  void _agregar(Product producto) {
    final agregado = context.read<SalesController>().agregar(producto);
    if (!agregado) {
      _avisar('Ya no hay más unidades disponibles de ${producto.name}.');
    }
  }

  void _sumar(LineaCarrito linea) => _agregar(linea.producto);

  Future<void> _cobrar() async {
    final c = context.read<SalesController>();
    try {
      final venta = await c.cobrar();
      if (!mounted) return;
      await MessageDialog.mostrar(
        context,
        titulo: '¡Listo!',
        mensaje: 'Venta registrada: ${formatoDinero(venta.total)}',
        icono: Icons.check_circle_outline,
        textoBoton: 'Aceptar',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      await MessageDialog.mostrar(
        context,
        titulo: 'No se pudo cobrar',
        mensaje: mensajeDeError(e),
        icono: Icons.error_outline,
        colorIcono: AppColors.agotado,
      );
    } on ConnectionException catch (e) {
      if (!mounted) return;
      await MessageDialog.mostrar(
        context,
        titulo: 'Sin conexión',
        mensaje: e.message,
        icono: Icons.cloud_off,
        colorIcono: AppColors.agotado,
      );
    } catch (e) {
      if (!mounted) return;
      await MessageDialog.mostrar(
        context,
        titulo: 'No se pudo cobrar',
        mensaje: mensajeDeError(e),
        icono: Icons.error_outline,
        colorIcono: AppColors.agotado,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SalesController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Vender')),
      body: _cuerpo(c),
      bottomNavigationBar: CartPanel(
        key: _panelKey,
        lineas: c.lineas,
        total: c.total,
        cobrando: c.cobrando,
        onSumar: _sumar,
        onRestar: (l) => c.restar(l.producto.id),
        onCobrar: _cobrar,
      ),
    );
  }

  Widget _cuerpo(SalesController c) {
    if (c.error != null) {
      return AsyncErrorView(error: c.error, onReintentar: c.cargar);
    }
    if (!c.cargado) return const AsyncErrorView(cargando: true);
    if (c.productos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Todavía no hay productos para vender. Agrégalos en Inventario.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => c.cargar(limpiar: false),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisExtent: 128,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemCount: c.productos.length,
        itemBuilder: (context, i) {
          final p = c.productos[i];
          return _ProductoTile(
            producto: p,
            enCarrito: c.cantidadEn(p.id),
            onTap: p.agotado ? null : () => _agregar(p),
          );
        },
      ),
    );
  }
}

class _ProductoTile extends StatelessWidget {
  const _ProductoTile({
    required this.producto,
    required this.enCarrito,
    required this.onTap,
  });

  final Product producto;
  final int enCarrito;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final agotado = producto.agotado;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Stack(
            children: [
              Opacity(
                opacity: agotado ? 0.5 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Espacio a la derecha para que la insignia no pise el nombre.
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xl),
                      child: Text(
                        producto.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.titleMedium,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatoDinero(producto.salePrice),
                      style: tema.textTheme.titleLarge
                          ?.copyWith(color: tema.colorScheme.primary),
                    ),
                    if (!agotado)
                      Text(
                        textoExistencias(producto.existencias),
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (agotado)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: EtiquetaEstado(
                    texto: 'Agotado',
                    color: AppColors.agotado,
                  ),
                ),
              if (enCarrito > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: CircleAvatar(
                    radius: AppSpacing.md,
                    backgroundColor: tema.colorScheme.primary,
                    child: Text(
                      '$enCarrito',
                      style: tema.textTheme.labelLarge
                          ?.copyWith(color: tema.colorScheme.onPrimary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

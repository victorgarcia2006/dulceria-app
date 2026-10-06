import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/dulceria_api.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/async_error_view.dart';
import '../../shared/stat_card.dart';
import 'home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // La pestaña se recrea cada vez que se entra, así que carga datos frescos.
    return ChangeNotifierProvider(
      create: (context) => HomeController(context.read<DulceriaApi>())..cargar(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<HomeController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Hoy')),
      body: _cuerpo(context, c),
    );
  }

  Widget _cuerpo(BuildContext context, HomeController c) {
    if (c.cargando && c.resumen == null) {
      return const AsyncErrorView(cargando: true);
    }
    final resumen = c.resumen;
    if (c.error != null || resumen == null) {
      return AsyncErrorView(error: c.error, onReintentar: c.cargar);
    }
    return RefreshIndicator(
      onRefresh: () => c.cargar(limpiar: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StatCard(
                  etiqueta: 'Vendido hoy',
                  valor: formatoDinero(resumen.total),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  etiqueta: 'Ganancia de hoy',
                  valor: formatoDinero(resumen.totalProfit),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          StatCard(
            etiqueta: 'Ventas de hoy',
            valor: '${resumen.salesCount}',
          ),
          const SizedBox(height: AppSpacing.lg),
          _SeccionPocasExistencias(productos: c.pocasExistencias),
        ],
      ),
    );
  }
}

class _SeccionPocasExistencias extends StatelessWidget {
  const _SeccionPocasExistencias({required this.productos});

  final List<Product> productos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pocas existencias', style: tema.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (productos.isEmpty)
          Text(
            'Todo en orden: ningún producto tiene pocas existencias.',
            style: tema.textTheme.bodyMedium
                ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          )
        else
          for (final p in productos)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                color: AppColors.warningContainer,
                child: ListTile(
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                  ),
                  title: Text(p.name),
                  trailing: Text(
                    textoExistencias(p.existencias),
                    style: tema.textTheme.titleSmall
                        ?.copyWith(color: AppColors.warning),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

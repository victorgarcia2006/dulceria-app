import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/sales/sales_screen.dart';

class DulceriaApp extends StatelessWidget {
  const DulceriaApp({super.key, this.api});

  /// Permite inyectar un cliente de prueba.
  final ApiClient? api;

  @override
  Widget build(BuildContext context) {
    return Provider<ApiClient>(
      create: (_) => api ?? ApiClient(),
      dispose: (_, cliente) => cliente.close(),
      child: MaterialApp(
        title: 'Dulcería',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const NavegacionPrincipal(),
      ),
    );
  }
}

/// Barra inferior con las tres pantallas. Abre en "Hoy".
class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indice = 0;

  // Solo se construye la pestaña activa: al volver a entrar a una pestaña se
  // recrea y recarga sus datos, así nunca se ven cifras viejas.
  Widget _pantalla() => switch (_indice) {
        0 => const HomeScreen(),
        1 => const SalesScreen(),
        _ => const InventoryScreen(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: KeyedSubtree(key: ValueKey(_indice), child: _pantalla()),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Hoy',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Vender',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
        ],
      ),
    );
  }
}

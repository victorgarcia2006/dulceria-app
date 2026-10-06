import 'package:flutter/material.dart';

import 'core/api_client.dart';

void main() {
  runApp(const DulceriaApp());
}

class DulceriaApp extends StatelessWidget {
  const DulceriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dulcería',
      debugShowCheckedModeBanner: false,
      home: const _PantallaConexion(),
    );
  }
}

/// Pantalla TEMPORAL del paso 1: solo verifica que la app conecta con la API.
class _PantallaConexion extends StatefulWidget {
  const _PantallaConexion();

  @override
  State<_PantallaConexion> createState() => _PantallaConexionState();
}

class _PantallaConexionState extends State<_PantallaConexion> {
  final _api = ApiClient();
  late Future<dynamic> _productos = _api.get('/products');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba de conexión')),
      body: FutureBuilder<dynamic>(
        future: _productos,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            final mensaje = error is ConnectionException
                ? error.message
                : error is ApiException
                    ? error.message
                    : 'Error inesperado';
            return Center(child: Text(mensaje));
          }
          final lista = snapshot.data as List<dynamic>;
          return ListView(
            children: [
              ListTile(title: Text('Conectado. Productos: ${lista.length}')),
              for (final p in lista)
                ListTile(title: Text(p['name'].toString())),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _productos = _api.get('/products')),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

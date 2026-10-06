import 'api_client.dart';
import 'models.dart';

/// Operaciones de la API de la dulcería, ya convertidas a modelos.
class DulceriaApi {
  DulceriaApi([ApiClient? client]) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Productos activos; con [incluirDescontinuados] también los descontinuados.
  Future<List<Product>> productos({bool incluirDescontinuados = false}) async {
    final json = await _client.get(
      '/products',
      query: incluirDescontinuados
          ? const {'includeDiscontinued': 'true'}
          : null,
    );
    return (json as List)
        .map((p) => Product.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<TodaySummary> resumenHoy() async {
    final json = await _client.get('/sales/today');
    return TodaySummary.fromJson(json as Map<String, dynamic>);
  }

  /// Registra una venta completa (todo o nada en el servidor).
  Future<Sale> registrarVenta(List<ItemVenta> items) async {
    final json = await _client.post(
      '/sales',
      body: {'items': items.map((i) => i.toJson()).toList()},
    );
    return Sale.fromJson(json as Map<String, dynamic>);
  }

  void close() => _client.close();
}

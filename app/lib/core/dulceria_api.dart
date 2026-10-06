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

  /// Crea un producto. Las existencias siempre inician en 0 (no se mandan).
  Future<Product> crearProducto({
    required String nombre,
    required double costo,
    required double precioVenta,
  }) async {
    final json = await _client.post(
      '/products',
      body: {'name': nombre, 'costPrice': costo, 'salePrice': precioVenta},
    );
    return Product.fromJson(json as Map<String, dynamic>);
  }

  /// Edita nombre, costo y precio. JAMÁS se manda `stock`: el backend lo rechaza.
  Future<Product> editarProducto(
    String id, {
    required String nombre,
    required double costo,
    required double precioVenta,
  }) async {
    final json = await _client.patch(
      '/products/$id',
      body: {'name': nombre, 'costPrice': costo, 'salePrice': precioVenta},
    );
    return Product.fromJson(json as Map<String, dynamic>);
  }

  Future<Product> descontinuarProducto(String id) async {
    final json = await _client.patch('/products/$id/discontinue');
    return Product.fromJson(json as Map<String, dynamic>);
  }

  /// Registra una compra: suma existencias y fija el costo actual del producto.
  /// Devuelve el producto ya actualizado.
  Future<Product> recibirMercancia({
    required String productId,
    required int cantidad,
    required double costoUnitario,
  }) async {
    final json = await _client.post(
      '/purchases',
      body: {
        'productId': productId,
        'quantity': cantidad,
        'unitCost': costoUnitario,
      },
    );
    return Product.fromJson(
      (json as Map<String, dynamic>)['product'] as Map<String, dynamic>,
    );
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

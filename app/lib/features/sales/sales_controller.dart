import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../../core/dulceria_api.dart';
import '../../core/models.dart';

/// Un renglón del carrito: el producto (con las existencias conocidas) y la cantidad.
class LineaCarrito {
  LineaCarrito(this.producto, this.cantidad);

  Product producto;
  int cantidad;

  double get subtotal => producto.salePrice * cantidad;
}

/// Estado de Vender: catálogo de venta y carrito en memoria.
/// Vive a nivel de app para que el carrito no se pierda al cambiar de pestaña.
class SalesController extends ChangeNotifier {
  SalesController(this._api);

  final DulceriaApi _api;

  List<Product> productos = const [];
  bool cargado = false;
  bool cargando = false;
  Object? error;
  bool cobrando = false;

  // Mapa con orden de inserción: los renglones salen en el orden en que se agregaron.
  final Map<String, LineaCarrito> _lineas = {};

  List<LineaCarrito> get lineas => _lineas.values.toList();
  bool get carritoVacio => _lineas.isEmpty;

  double get total {
    final suma = _lineas.values.fold<double>(0, (s, l) => s + l.subtotal);
    return (suma * 100).round() / 100;
  }

  int cantidadEn(String productId) => _lineas[productId]?.cantidad ?? 0;

  /// Agrega una unidad. Devuelve `false` si no quedan más unidades según las
  /// existencias conocidas (la pantalla avisa con un SnackBar).
  bool agregar(Product producto) {
    final actual = cantidadEn(producto.id);
    if (actual + 1 > producto.existencias) return false;
    final linea = _lineas[producto.id];
    if (linea == null) {
      _lineas[producto.id] = LineaCarrito(producto, 1);
    } else {
      linea.cantidad++;
    }
    notifyListeners();
    return true;
  }

  /// Quita una unidad; si llega a 0 se elimina el renglón.
  void restar(String productId) {
    final linea = _lineas[productId];
    if (linea == null) return;
    linea.cantidad--;
    if (linea.cantidad <= 0) _lineas.remove(productId);
    notifyListeners();
  }

  /// Carga el catálogo de venta. Con [limpiar] oculta la lista anterior
  /// mientras carga (para no mostrar existencias viejas).
  Future<void> cargar({bool limpiar = true}) async {
    if (limpiar) {
      productos = const [];
      cargado = false;
    }
    cargando = true;
    error = null;
    notifyListeners();
    try {
      productos = await _api.productos();
      cargado = true;
      _sincronizarCarrito();
    } catch (e) {
      error = e;
    }
    cargando = false;
    notifyListeners();
  }

  /// Actualiza las existencias conocidas de cada renglón y quita los productos
  /// que ya no se pueden vender (descontinuados). No toca las cantidades.
  void _sincronizarCarrito() {
    final porId = {for (final p in productos) p.id: p};
    _lineas.removeWhere((id, _) => !porId.containsKey(id));
    for (final linea in _lineas.values) {
      linea.producto = porId[linea.producto.id]!;
    }
  }

  /// Cobra el carrito. Si sale bien, lo vacía y devuelve la venta. Si falla,
  /// el carrito se conserva y se relanza el error; salvo falla de conexión,
  /// también se recarga el catálogo para ver las existencias reales.
  Future<Sale> cobrar() async {
    cobrando = true;
    notifyListeners();
    try {
      final venta = await _api.registrarVenta([
        for (final l in _lineas.values)
          ItemVenta(productId: l.producto.id, quantity: l.cantidad),
      ]);
      _lineas.clear();
      unawaited(cargar(limpiar: false));
      return venta;
    } on ConnectionException {
      rethrow;
    } on ApiException {
      unawaited(cargar(limpiar: false));
      rethrow;
    } finally {
      cobrando = false;
      notifyListeners();
    }
  }
}

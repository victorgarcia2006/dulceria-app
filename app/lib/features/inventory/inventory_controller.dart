import 'package:flutter/foundation.dart';

import '../../core/dulceria_api.dart';
import '../../core/models.dart';

/// Estado de Inventario. Cada acción llama a la API y, si sale bien, recarga
/// la lista sola. Si la API falla, la excepción llega a quien llamó.
class InventoryController extends ChangeNotifier {
  InventoryController(this._api);

  final DulceriaApi _api;

  List<Product> productos = const [];
  bool cargado = false;
  bool cargando = false;
  Object? error;
  bool mostrarDescontinuados = false;

  Future<void> cargar({bool limpiar = true}) async {
    if (limpiar) {
      productos = const [];
      cargado = false;
    }
    cargando = true;
    error = null;
    notifyListeners();
    try {
      productos = await _api.productos(
        incluirDescontinuados: mostrarDescontinuados,
      );
      cargado = true;
    } catch (e) {
      error = e;
    }
    cargando = false;
    notifyListeners();
  }

  Future<void> cambiarMostrarDescontinuados(bool valor) {
    mostrarDescontinuados = valor;
    return cargar();
  }

  Future<void> agregarProducto({
    required String nombre,
    required double costo,
    required double precioVenta,
  }) async {
    await _api.crearProducto(
      nombre: nombre,
      costo: costo,
      precioVenta: precioVenta,
    );
    await cargar(limpiar: false);
  }

  Future<void> editarProducto(
    Product producto, {
    required String nombre,
    required double costo,
    required double precioVenta,
  }) async {
    await _api.editarProducto(
      producto.id,
      nombre: nombre,
      costo: costo,
      precioVenta: precioVenta,
    );
    await cargar(limpiar: false);
  }

  Future<void> recibirMercancia(
    Product producto, {
    required int cantidad,
    required double costoUnitario,
  }) async {
    await _api.recibirMercancia(
      productId: producto.id,
      cantidad: cantidad,
      costoUnitario: costoUnitario,
    );
    await cargar(limpiar: false);
  }

  Future<void> descontinuar(Product producto) async {
    await _api.descontinuarProducto(producto.id);
    await cargar(limpiar: false);
  }
}

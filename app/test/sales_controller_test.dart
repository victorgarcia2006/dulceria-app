import 'package:flutter_test/flutter_test.dart';

import 'package:dulceria_app/core/api_client.dart';
import 'package:dulceria_app/core/dulceria_api.dart';
import 'package:dulceria_app/core/models.dart';
import 'package:dulceria_app/features/sales/sales_controller.dart';

const _gomita = Product(
  id: 'g',
  name: 'Gomita',
  costPrice: 1,
  salePrice: 3,
  existencias: 2,
  active: true,
);
const _chicle = Product(
  id: 'c',
  name: 'Chicle',
  costPrice: 0.1,
  salePrice: 0.3,
  existencias: 10,
  active: true,
);

class _ApiFalso extends DulceriaApi {
  Object? errorAlVender;
  int cargas = 0;
  List<ItemVenta>? ultimaVenta;

  @override
  Future<List<Product>> productos({bool incluirDescontinuados = false}) async {
    cargas++;
    return const [_gomita, _chicle];
  }

  @override
  Future<Sale> registrarVenta(List<ItemVenta> items) async {
    if (errorAlVender != null) throw errorAlVender!;
    ultimaVenta = items;
    return const Sale(id: 'v', total: 6.9, totalProfit: 1);
  }
}

void main() {
  late _ApiFalso api;
  late SalesController c;

  setUp(() async {
    api = _ApiFalso();
    c = SalesController(api);
    await c.cargar();
  });

  test('agregar suma de a uno y respeta las existencias conocidas', () {
    expect(c.agregar(_gomita), isTrue);
    expect(c.agregar(_gomita), isTrue);
    expect(c.agregar(_gomita), isFalse); // solo hay 2
    expect(c.cantidadEn('g'), 2);
  });

  test('restar quita el renglón al llegar a 0 y el total se recalcula', () {
    c.agregar(_gomita);
    c.agregar(_chicle);
    c.agregar(_chicle);
    c.agregar(_chicle);
    expect(c.total, 3.9);
    c.restar('g');
    expect(c.lineas.map((l) => l.producto.id), ['c']);
    expect(c.total, 0.9);
  });

  test('cobrar con éxito vacía el carrito y recarga los productos', () async {
    c.agregar(_gomita);
    final cargasAntes = api.cargas;
    final venta = await c.cobrar();
    expect(venta.total, 6.9);
    expect(c.carritoVacio, isTrue);
    expect(api.ultimaVenta!.single.quantity, 1);
    await Future<void>.delayed(Duration.zero);
    expect(api.cargas, greaterThan(cargasAntes));
  });

  test('un 422 conserva el carrito y recarga los productos', () async {
    api.errorAlVender =
        ApiException('Ya no hay suficiente Gomita, solo quedan 1.', statusCode: 422);
    c.agregar(_gomita);
    final cargasAntes = api.cargas;
    await expectLater(c.cobrar(), throwsA(isA<ApiException>()));
    expect(c.carritoVacio, isFalse);
    expect(c.cobrando, isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(api.cargas, greaterThan(cargasAntes));
  });

  test('una falla de conexión conserva el carrito y no recarga', () async {
    api.errorAlVender = ConnectionException();
    c.agregar(_gomita);
    final cargasAntes = api.cargas;
    await expectLater(c.cobrar(), throwsA(isA<ConnectionException>()));
    expect(c.carritoVacio, isFalse);
    expect(api.cargas, cargasAntes);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dulceria_app/app.dart';
import 'package:dulceria_app/core/api_client.dart';
import 'package:dulceria_app/core/dulceria_api.dart';
import 'package:dulceria_app/core/models.dart';

/// API falso: datos fijos, sin red. Con [sinConexion] todo falla como si el
/// servidor estuviera apagado.
class _ApiFalso extends DulceriaApi {
  bool sinConexion = false;

  @override
  Future<TodaySummary> resumenHoy() async {
    if (sinConexion) throw ConnectionException();
    return const TodaySummary(total: 150, totalProfit: 60.5, salesCount: 3);
  }

  @override
  Future<List<Product>> productos({bool incluirDescontinuados = false}) async {
    if (sinConexion) throw ConnectionException();
    return const [
      Product(
        id: '1',
        name: 'Gomita',
        costPrice: 1,
        salePrice: 2,
        existencias: 2,
        active: true,
      ),
      Product(
        id: '2',
        name: 'Chicle',
        costPrice: 0.1,
        salePrice: 0.5,
        existencias: 0,
        active: true,
      ),
    ];
  }
}

final _palabraProhibida = find.textContaining(
  RegExp('stock', caseSensitive: false),
);

void main() {
  testWidgets('abre en Hoy con los totales y la alerta de pocas existencias', (
    tester,
  ) async {
    await tester.pumpWidget(DulceriaApp(api: _ApiFalso()));
    await tester.pumpAndSettle();

    // Pestañas.
    expect(find.text('Hoy'), findsWidgets);
    expect(find.text('Vender'), findsOneWidget);
    expect(find.text('Inventario'), findsOneWidget);

    // Tarjetas del día.
    expect(find.text('Vendido hoy'), findsOneWidget);
    expect(find.text('\$150.00'), findsOneWidget);
    expect(find.text('\$60.50'), findsOneWidget);

    // Alerta.
    expect(find.text('Pocas existencias'), findsOneWidget);
    expect(find.text('Gomita'), findsOneWidget);
    expect(find.text('Quedan 2'), findsOneWidget);
  });

  testWidgets(
    'sin conexión muestra un mensaje amigable y Reintentar funciona',
    (tester) async {
      final api = _ApiFalso()..sinConexion = true;
      await tester.pumpWidget(DulceriaApp(api: api));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.',
        ),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);

      api.sinConexion = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Vendido hoy'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
    },
  );

  testWidgets('recorre las tres pantallas sin mostrar la palabra "stock"', (
    tester,
  ) async {
    await tester.pumpWidget(DulceriaApp(api: _ApiFalso()));
    await tester.pumpAndSettle();
    expect(_palabraProhibida, findsNothing);

    // Vender: catálogo, agotados y carrito vacío.
    await tester.tap(find.text('Vender'));
    await tester.pumpAndSettle();
    expect(find.text('Quedan 2'), findsOneWidget);
    expect(find.text('Agotado'), findsOneWidget);
    expect(
      find.text('Carrito vacío. Toca un producto para agregarlo.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Cobrar'))
          .onPressed,
      isNull,
    );
    expect(_palabraProhibida, findsNothing);

    // Tocar un producto lo agrega al carrito; un agotado no.
    await tester.tap(find.text('Gomita'));
    await tester.pump();
    expect(
      find.text('Carrito vacío. Toca un producto para agregarlo.'),
      findsNothing,
    );
    await tester.tap(find.text('Chicle'));
    await tester.pump();
    expect(
      find.text('Chicle'),
      findsOneWidget,
    ); // solo la tarjeta, no el carrito

    // Inventario.
    await tester.tap(find.text('Inventario'));
    await tester.pumpAndSettle();
    expect(find.text('Mostrar descontinuados'), findsOneWidget);
    expect(find.text('Agregar producto'), findsOneWidget);
    expect(
      find.textContaining('Quedan 2 · Costo \$1.00 · Venta \$2.00'),
      findsOneWidget,
    );
    expect(_palabraProhibida, findsNothing);
  });
}

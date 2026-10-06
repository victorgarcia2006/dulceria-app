import 'package:flutter_test/flutter_test.dart';

import 'package:dulceria_app/app.dart';
import 'package:dulceria_app/core/dulceria_api.dart';
import 'package:dulceria_app/core/models.dart';

/// API falso: datos fijos, sin red.
class _ApiFalso extends DulceriaApi {
  @override
  Future<TodaySummary> resumenHoy() async =>
      const TodaySummary(total: 150, totalProfit: 60.5, salesCount: 3);

  @override
  Future<List<Product>> productos({bool incluirDescontinuados = false}) async =>
      const [
        Product(
          id: '1',
          name: 'Gomita',
          costPrice: 1,
          salePrice: 2,
          existencias: 2,
          active: true,
        ),
      ];
}

void main() {
  testWidgets('abre en Hoy con los totales y la alerta de pocas existencias',
      (tester) async {
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
}

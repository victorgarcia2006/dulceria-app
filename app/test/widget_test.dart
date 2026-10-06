import 'package:flutter_test/flutter_test.dart';

import 'package:dulceria_app/app.dart';

void main() {
  testWidgets('abre en Hoy y muestra las tres pestañas', (tester) async {
    await tester.pumpWidget(const DulceriaApp());

    // Las etiquetas aparecen en la barra inferior (y "Hoy" también en pantalla).
    expect(find.text('Hoy'), findsWidgets);
    expect(find.text('Vender'), findsOneWidget);
    expect(find.text('Inventario'), findsOneWidget);
  });
}

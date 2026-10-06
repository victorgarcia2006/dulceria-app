import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dulceria_app/main.dart';

void main() {
  testWidgets('la app arranca y muestra la prueba de conexión', (tester) async {
    await tester.pumpWidget(const DulceriaApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Prueba de conexión'), findsOneWidget);
  });
}

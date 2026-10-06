import 'package:flutter_test/flutter_test.dart';

import 'package:dulceria_app/core/format.dart';
import 'package:dulceria_app/core/validators.dart';

void main() {
  group('validadores', () {
    test('nombre no puede estar vacío', () {
      expect(validarNombre('  '), kMensajeNombre);
      expect(validarNombre(null), kMensajeNombre);
      expect(validarNombre('Paleta'), isNull);
    });

    test('dinero acepta 0, decimales y coma; rechaza negativos y texto', () {
      expect(validarDinero('0'), isNull);
      expect(validarDinero('12.5'), isNull);
      expect(validarDinero('12,5'), isNull);
      expect(validarDinero('-1'), kMensajeNumero);
      expect(validarDinero(''), kMensajeNumero);
      expect(validarDinero('abc'), kMensajeNumero);
      expect(validarDinero('Infinity'), kMensajeNumero);
      expect(parseDinero('12,5'), 12.5);
    });

    test('cantidad solo enteros mayores que cero', () {
      expect(validarCantidad('3'), isNull);
      expect(validarCantidad('0'), kMensajeCantidad);
      expect(validarCantidad('2.5'), kMensajeCantidad);
      expect(validarCantidad('-4'), kMensajeCantidad);
      expect(validarCantidad(''), kMensajeCantidad);
    });
  });

  group('formato', () {
    test('dinero con símbolo, miles y 2 decimales', () {
      expect(formatoDinero(0), '\$0.00');
      expect(formatoDinero(5), '\$5.00');
      expect(formatoDinero(1234.5), '\$1,234.50');
      expect(formatoDinero(1234567.891), '\$1,234,567.89');
    });

    test('existencias en español natural', () {
      expect(textoExistencias(0), 'Agotado');
      expect(textoExistencias(1), 'Queda 1');
      expect(textoExistencias(7), 'Quedan 7');
    });
  });
}

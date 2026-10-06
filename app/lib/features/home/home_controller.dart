import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../../core/dulceria_api.dart';
import '../../core/models.dart';

/// Estado de la pantalla Hoy: totales del día y productos con pocas existencias.
class HomeController extends ChangeNotifier {
  HomeController(this._api);

  final DulceriaApi _api;

  bool cargando = true;
  Object? error;
  TodaySummary? resumen;
  List<Product> pocasExistencias = const [];

  /// Carga todo de nuevo. Con [limpiar] oculta lo anterior mientras carga, para
  /// no mostrar cifras viejas.
  Future<void> cargar({bool limpiar = true}) async {
    if (limpiar) {
      resumen = null;
      pocasExistencias = const [];
    }
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final resultados = await Future.wait([
        _api.resumenHoy(),
        _api.productos(),
      ]);
      resumen = resultados[0] as TodaySummary;
      final productos = resultados[1] as List<Product>;
      pocasExistencias = productos
          .where((p) => p.active && p.existencias < kUmbralPocasExistencias)
          .toList()
        ..sort((a, b) => a.existencias.compareTo(b.existencias));
    } catch (e) {
      error = e;
    }
    cargando = false;
    notifyListeners();
  }
}

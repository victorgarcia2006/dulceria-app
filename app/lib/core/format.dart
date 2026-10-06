/// Dinero con `$`, separador de miles y 2 decimales (sin intl): `$1,234.50`.
String formatoDinero(num valor) {
  final negativo = valor < 0;
  final partes = valor.abs().toStringAsFixed(2).split('.');
  final entero = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${negativo ? '-' : ''}\$$entero.${partes[1]}';
}

/// Texto de existencias para la usuaria: "Agotado", "Queda 1" o "Quedan 7".
String textoExistencias(int existencias) {
  if (existencias <= 0) return 'Agotado';
  if (existencias == 1) return 'Queda 1';
  return 'Quedan $existencias';
}

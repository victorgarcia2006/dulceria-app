// Validación en el cliente, antes de llamar a la API. Cada validador devuelve
// `null` si el texto es válido, o el mensaje simple para la usuaria.

const String kMensajeNombre = 'Escribe un nombre.';
const String kMensajeNumero = 'Escribe un número válido.';
const String kMensajeCantidad = 'Escribe una cantidad entera mayor que cero.';

/// Convierte "12.50" o "12,50" en número; `null` si no es un número válido (>= 0).
double? parseDinero(String? texto) {
  final limpio = (texto ?? '').trim().replaceAll(',', '.');
  if (limpio.isEmpty) return null;
  final valor = double.tryParse(limpio);
  if (valor == null || !valor.isFinite || valor < 0) return null;
  return valor;
}

/// Entero mayor que cero; `null` si no lo es.
int? parseCantidad(String? texto) {
  final valor = int.tryParse((texto ?? '').trim());
  if (valor == null || valor <= 0) return null;
  return valor;
}

String? validarNombre(String? texto) =>
    (texto ?? '').trim().isEmpty ? kMensajeNombre : null;

String? validarDinero(String? texto) =>
    parseDinero(texto) == null ? kMensajeNumero : null;

String? validarCantidad(String? texto) =>
    parseCantidad(texto) == null ? kMensajeCantidad : null;

import 'api_client.dart';

/// Mensaje amigable para mostrar a la usuaria; nunca texto crudo del servidor
/// ni de excepciones de Dart.
String mensajeDeError(Object error) {
  if (error is ConnectionException) return error.message;
  if (error is ApiException) {
    // 422: regla de negocio; el backend ya lo redacta en español amigable.
    if (error.statusCode == 422) return error.message;
    if (error.statusCode == 404) {
      return 'No encontramos ese producto. Actualiza la lista e inténtalo de nuevo.';
    }
    // 5xx: el cliente API ya puso un mensaje genérico.
    if ((error.statusCode ?? 0) >= 500) return error.message;
  }
  return 'Algo salió mal. Inténtalo de nuevo.';
}

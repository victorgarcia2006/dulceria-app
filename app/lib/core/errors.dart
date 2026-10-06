import 'api_client.dart';

/// Mensaje amigable para mostrar a la usuaria; nunca texto crudo del servidor
/// ni de excepciones de Dart.
String mensajeDeError(Object error) {
  if (error is ConnectionException) return error.message;
  if (error is ApiException) return error.message;
  return 'Algo salió mal. Inténtalo de nuevo.';
}

// lib/core/network/api_config.dart
//
// Dónde está la API y con qué clave se identifica la app.
// Se configuran al compilar, sin tocar el código:
//
//   flutter run --dart-define-from-file=config/prod.json
//
// config/prod.json (no se sube a git):
//   {"API_BASE_URL": "https://backend-unimarket-production.up.railway.app/api/v1",
//    "APP_KEY": "um_..."}
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backend-unimarket-production.up.railway.app/api/v1',
  );

  /// Clave que la API exige en la cabecera X-App-Key.
  static const String appKey = String.fromEnvironment('APP_KEY');

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}

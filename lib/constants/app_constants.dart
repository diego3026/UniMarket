// lib/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String appName = 'UniMarket';

  /// URL del backend en FastAPI (BackEnd-Unimarket, prefijo /api/v1).
  /// - Emulador Android: 10.0.2.2 apunta al localhost de tu PC.
  /// - Dispositivo físico: usa la IP de tu PC en la red local.
  static const String apiBaseUrl = 'http://10.0.2.2:8000/api/v1';

  /// Tiempo máximo de espera de las peticiones HTTP (ms).
  static const int apiTimeout = 15000;
}

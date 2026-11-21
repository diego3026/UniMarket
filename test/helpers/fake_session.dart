import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Deja una sesión guardada como si el usuario ya hubiera iniciado sesión.
/// Las llamadas a la API fallan en los tests (sin red) y la app debe seguir
/// mostrándose igual, con listas vacías.
void fakeSession(String role) {
  final ids = {'consumer': 'u-cliente', 'entrepreneur': 'u-laura', 'admin': 'u-admin'};
  SharedPreferences.setMockInitialValues({
    'has_seen_onboarding': true,
    'auth_user_v2': jsonEncode({
      'id': ids[role] ?? 'u-cliente',
      'email': '$role@demo.unimarket.app',
      'fullName': 'Usuario Demo',
      'phone': '3001234567',
      'role': role,
      'storeId': role == 'entrepreneur' ? 's-demo' : null,
      'emailVerified': true,
    }),
  });
  FlutterSecureStorage.setMockInitialValues({
    'um_access_token': 'test-access',
    'um_refresh_token': 'test-refresh',
  });
}

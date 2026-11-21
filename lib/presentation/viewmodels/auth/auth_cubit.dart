import 'dart:convert';

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unimarket/domain/entities/user_role.dart';

import '../../../core/network/api_client.dart';
import 'auth_state.dart';

/// Sesión del usuario contra la API.
///
/// - Los tokens se guardan cifrados (TokenStorage).
/// - Los datos básicos del usuario se guardan en SharedPreferences para abrir
///   la app sin esperar a la red; luego se actualizan con GET /me.
class AuthCubit extends Cubit<AuthState> {
  static const _kUser = 'auth_user_v2';

  final SharedPreferences _prefs;
  final ApiClient _api;

  AuthCubit(this._prefs, this._api) : super(AuthInitial()) {
    _api.onSessionExpired = () => _signOutLocal('Tu sesión expiró. Inicia sesión de nuevo.');
  }

  /// Recupera la sesión guardada al abrir la app.
  Future<void> restore() async {
    final raw = _prefs.getString(_kUser);
    final token = await _api.tokens.refreshToken;
    if (raw == null || token == null) {
      emit(Unauthenticated());
      return;
    }
    try {
      emit(Authenticated(AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>)));
    } catch (_) {
      emit(Unauthenticated());
      return;
    }
    // Actualiza en segundo plano (rol o tienda pudieron cambiar).
    unawaited(refreshMe());
  }

  /// Inicia sesión. Devuelve el mensaje de error o null si todo salió bien.
  Future<String?> login(String email, String password) async {
    try {
      final r = await _api.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
        auth: false,
      );
      await _saveSession(r as Map<String, dynamic>);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Crea la cuenta y deja la sesión iniciada.
  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool acceptTerms,
  }) async {
    try {
      final r = await _api.post(
        '/auth/register',
        data: {
          'fullName': name.trim(),
          'email': email.trim(),
          'phone': phone,
          'password': password,
          'acceptTerms': acceptTerms,
        },
        auth: false,
      );
      await _saveSession(r as Map<String, dynamic>);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Cuentas demo (solo en modo debug, para probar cada rol rápido).
  Future<String?> loginAs(UserRole role) {
    const emails = {
      UserRole.consumer: 'cliente@demo.unimarket.app',
      UserRole.entrepreneur: 'laura@demo.unimarket.app',
    };
    final email = emails[role];
    if (email == null) return Future.value('Para el admin usa tu correo y contraseña');
    return login(email, 'Demo12345');
  }

  Future<void> refreshMe() async {
    try {
      final me = await _api.get('/me');
      final user = AuthUser.fromJson(me as Map<String, dynamic>);
      await _prefs.setString(_kUser, jsonEncode(user.toJson()));
      emit(Authenticated(user));
    } on ApiException catch (e) {
      if (e.isUnauthorized) await _signOutLocal('Tu sesión expiró. Inicia sesión de nuevo.');
    }
  }

  /// Actualiza el usuario guardado (p. ej. tras crear su tienda o editar el perfil).
  Future<void> setUser(AuthUser user) async {
    await _prefs.setString(_kUser, jsonEncode(user.toJson()));
    emit(Authenticated(user));
  }

  Future<String?> verifyEmail(String code) async {
    try {
      await _api.post('/auth/verify-email', data: {'code': code});
      await refreshMe();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> resendVerification() async {
    try {
      await _api.post('/me/resend-verification');
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> requestPasswordReset(String email) async {
    try {
      await _api.post('/auth/forgot-password', data: {'email': email.trim()}, auth: false);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> resetPassword(String email, String code, String newPassword) async {
    try {
      await _api.post(
        '/auth/reset-password',
        data: {'email': email.trim(), 'code': code, 'newPassword': newPassword},
        auth: false,
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> changePassword(String current, String newPassword) async {
    try {
      await _api.post('/me/password', data: {'currentPassword': current, 'newPassword': newPassword});
      await _signOutLocal('Contraseña actualizada. Inicia sesión de nuevo.');
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    final refresh = await _api.tokens.refreshToken;
    if (refresh != null) {
      try {
        await _api.post('/auth/logout', data: {'refreshToken': refresh}, auth: false);
      } catch (_) {}
    }
    await _signOutLocal();
  }

  Future<void> _saveSession(Map<String, dynamic> r) async {
    await _api.tokens.save(r['accessToken'] as String, r['refreshToken'] as String);
    final user = AuthUser.fromJson(r['user'] as Map<String, dynamic>);
    await _prefs.setString(_kUser, jsonEncode(user.toJson()));
    emit(Authenticated(user));
  }

  Future<void> _signOutLocal([String? message]) async {
    await _api.tokens.clear();
    _api.clearCache();
    await _prefs.remove(_kUser);
    if (state is! Unauthenticated) emit(Unauthenticated(message));
  }

  bool isAuthenticated() => state is Authenticated;

  AuthUser? get currentUser =>
      state is Authenticated ? (state as Authenticated).user : null;
}

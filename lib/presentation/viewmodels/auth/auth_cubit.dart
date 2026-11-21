import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unimarket/domain/entities/user_role.dart';
import 'auth_state.dart';

/// Sesión del usuario (simulada hasta conectar el backend en FastAPI).
///
/// Credenciales de prueba:
/// - Cliente:      1234 / 1234
/// - Emprendedor:  emp  / emp
/// - Admin:        admin / admin
///
/// La sesión se guarda en SharedPreferences para no tener que iniciar sesión
/// cada vez que se reinicia la app durante el desarrollo.
class AuthCubit extends Cubit<AuthState> {
  static const _kEmail = 'auth_email';
  static const _kRole = 'auth_role';

  final SharedPreferences _prefs;

  AuthCubit(this._prefs) : super(AuthInitial()) {
    final email = _prefs.getString(_kEmail);
    final role = _prefs.getString(_kRole);
    if (email != null && role != null) {
      emit(
        Authenticated(AuthUser(email: email, role: UserRole.fromString(role))),
      );
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final UserRole role;
    if (email == '1234' && password == '1234') {
      role = UserRole.consumer;
    } else if (email == 'emp' && password == 'emp') {
      role = UserRole.entrepreneur;
    } else if (email == 'admin' && password == 'admin') {
      role = UserRole.admin;
    } else {
      emit(Unauthenticated());
      return;
    }
    await _signIn(email, role);
  }

  /// Acceso rápido para pruebas desde la pantalla de login.
  Future<void> loginAs(UserRole role) {
    const emails = {
      UserRole.consumer: '1234',
      UserRole.entrepreneur: 'emp',
      UserRole.admin: 'admin',
    };
    return _signIn(emails[role]!, role);
  }

  Future<void> _signIn(String email, UserRole role) async {
    await _prefs.setString(_kEmail, email);
    await _prefs.setString(_kRole, role.name);
    emit(Authenticated(AuthUser(email: email, role: role)));
  }

  Future<void> logout() async {
    await _prefs.remove(_kEmail);
    await _prefs.remove(_kRole);
    emit(Unauthenticated());
  }

  bool isAuthenticated() => state is Authenticated;

  AuthUser? get currentUser =>
      state is Authenticated ? (state as Authenticated).user : null;
}

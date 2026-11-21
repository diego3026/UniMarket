import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/injection_container.dart';
import '../auth/auth_cubit.dart';
import 'password_recovery_state.dart';

class PasswordRecoveryCubit extends Cubit<PasswordRecoveryState> {
  PasswordRecoveryCubit() : super(PasswordRecoveryInitial());

  String? _code;
  String? _recoveryEmail;

  /// Pide a la API que envíe el código de 6 dígitos al correo.
  Future<void> recoverPassword(String email) async {
    if (email.isEmpty) {
      emit(PasswordRecoveryFailure('Por favor ingresa tu correo electrónico'));
      return;
    }

    if (!_isValidEmail(email)) {
      emit(PasswordRecoveryFailure('Correo inválido'));
      return;
    }

    emit(PasswordRecoveryLoading());

    final error = await sl<AuthCubit>().requestPasswordReset(email);
    if (error != null) {
      emit(PasswordRecoveryFailure(error));
      return;
    }
    _recoveryEmail = email.trim();
    emit(PasswordRecoveryCodeSent(email));
  }

  /// Guarda el código; el servidor lo valida al cambiar la contraseña
  /// (vence en 15 minutos y se bloquea tras 5 intentos).
  Future<void> verifyCode(String code) async {
    final c = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(c)) {
      emit(PasswordRecoveryFailure('El código tiene 6 dígitos'));
      return;
    }
    _code = c;
    emit(PasswordRecoveryCodeVerified());
  }

  /// Restablece la contraseña
  Future<void> resetPassword(String newPassword, String confirmPassword) async {
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      emit(PasswordRecoveryFailure('Por favor completa todos los campos'));
      return;
    }

    if (newPassword.length < 8) {
      emit(PasswordRecoveryFailure('La contraseña debe tener al menos 8 caracteres'));
      return;
    }

    if (!_isStrongPassword(newPassword)) {
      emit(PasswordRecoveryFailure('La contraseña debe tener letras y números'));
      return;
    }

    if (newPassword != confirmPassword) {
      emit(PasswordRecoveryFailure('Las contraseñas no coinciden'));
      return;
    }

    emit(PasswordRecoveryLoading());

    final email = _recoveryEmail ?? '';
    final error = await sl<AuthCubit>().resetPassword(email, _code ?? '', newPassword);
    if (error != null) {
      emit(PasswordRecoveryFailure(error));
      return;
    }
    _code = null;
    emit(PasswordRecoverySuccess(email));
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    return password.contains(RegExp(r'[A-Za-z]')) && password.contains(RegExp(r'\d'));
  }

  void reset() => emit(PasswordRecoveryInitial());
}

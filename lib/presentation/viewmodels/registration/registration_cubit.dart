import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/auth_cubit.dart';
import 'registration_state.dart';

class RegistrationCubit extends Cubit<RegistrationState> {
  final AuthCubit _auth;
  RegistrationCubit(this._auth) : super(RegistrationInitial());

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required bool acceptTerms,
  }) async {
    emit(RegistrationLoading());

    // Validaciones
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      emit(RegistrationFailure('Por favor completa todos los campos'));
      return;
    }

    if (name.length < 3) {
      emit(RegistrationFailure('El nombre debe tener al menos 3 caracteres'));
      return;
    }

    if (!_isValidEmail(email)) {
      emit(RegistrationFailure('Correo inválido'));
      return;
    }

    if (!_isValidPhone(phone)) {
      emit(RegistrationFailure('Teléfono inválido (10 dígitos requeridos)'));
      return;
    }

    if (password.length < 8) {
      emit(
        RegistrationFailure('La contraseña debe tener al menos 8 caracteres'),
      );
      return;
    }

    if (!_isStrongPassword(password)) {
      emit(
        RegistrationFailure('La contraseña debe tener letras y números'),
      );
      return;
    }

    if (password != confirmPassword) {
      emit(RegistrationFailure('Las contraseñas no coinciden'));
      return;
    }

    if (!acceptTerms) {
      emit(RegistrationFailure('Debes aceptar los términos y condiciones'));
      return;
    }

    final error = await _auth.register(
      name: name,
      email: email,
      phone: phone.replaceAll(RegExp(r'\D'), ''),
      password: password,
      acceptTerms: acceptTerms,
    );
    emit(error == null ? RegistrationSuccess() : RegistrationFailure(error));
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^3\d{9}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'\D'), ''));
  }

  bool _isStrongPassword(String password) {
    final hasLetters = password.contains(RegExp(r'[A-Za-z]'));
    final hasDigits = password.contains(RegExp(r'\d'));
    return hasLetters && hasDigits;
  }
}

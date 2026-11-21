import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unimarket/core/injection_container.dart';
import 'package:unimarket/domain/entities/user_role.dart';

import '../../../core/network/api_client.dart';
import '../../models/user_model.dart';
import '../auth/auth_cubit.dart';
import '../auth/auth_state.dart';
import 'profile_state.dart';

/// Perfil del usuario: se arma con los datos de la sesión y se edita con PATCH /me.
class ProfileCubit extends Cubit<ProfileState> {
  final ApiClient _api;
  ProfileCubit(this._api) : super(ProfileInitial());

  UserModel _from(AuthUser u) => UserModel(
    id: u.id,
    name: u.name.isEmpty ? u.firstName : u.name,
    email: u.email,
    avatarUrl: u.avatarUrl.isEmpty ? null : u.avatarUrl,
    role: u.role,
  );

  Future<void> loadProfile() async {
    final user = sl<AuthCubit>().currentUser;
    if (user == null) {
      emit(ProfileFailure('Usuario no autenticado'));
      return;
    }
    emit(ProfileLoaded(_from(user)));
  }

  /// Guarda nombre, teléfono o foto. Devuelve el error o null.
  Future<String?> updateProfile({String? name, String? email, String? avatarUrl, String? phone, UserRole? role}) async {
    try {
      final r = await _api.patch(
        '/me',
        data: {
          if (name != null && name.trim().isNotEmpty) 'fullName': name.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone,
          if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
        },
      );
      final user = AuthUser.fromJson(r as Map<String, dynamic>);
      await sl<AuthCubit>().setUser(user);
      emit(ProfileLoaded(_from(user)));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

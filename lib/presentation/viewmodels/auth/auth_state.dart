import 'package:unimarket/domain/entities/user_role.dart';

class AuthUser {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String avatarUrl;
  final UserRole role;
  final String? storeId;
  final bool emailVerified;

  const AuthUser({
    this.id = '',
    required this.email,
    this.name = '',
    this.phone = '',
    this.avatarUrl = '',
    this.role = UserRole.consumer,
    this.storeId,
    this.emailVerified = false,
  });

  String get firstName => name.trim().isEmpty ? email.split('@').first : name.trim().split(' ').first;

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id: (j['id'] ?? '').toString(),
    email: (j['email'] ?? '').toString(),
    name: (j['fullName'] ?? '').toString(),
    phone: (j['phone'] ?? '').toString(),
    avatarUrl: (j['avatarUrl'] ?? '').toString(),
    role: UserRole.fromString((j['role'] ?? 'consumer').toString()),
    storeId: j['storeId']?.toString(),
    emailVerified: j['emailVerified'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': name,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'role': role.name,
    'storeId': storeId,
    'emailVerified': emailVerified,
  };
}

abstract class AuthState {}

class AuthInitial extends AuthState {}

class Authenticated extends AuthState {
  final AuthUser user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {
  /// Motivo para mostrar en el login (p. ej. "Tu sesión expiró").
  final String? message;
  Unauthenticated([this.message]);
}

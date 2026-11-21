import 'package:equatable/equatable.dart';

/// Estados para el manejo de usuarios del sistema
abstract class AdminUsersState extends Equatable {
  const AdminUsersState();

  @override
  List<Object?> get props => [];
}

class AdminUsersInitial extends AdminUsersState {
  const AdminUsersInitial();
}

class AdminUsersLoading extends AdminUsersState {
  const AdminUsersLoading();
}

class AdminUsersLoaded extends AdminUsersState {
  final List<AdminUserModel> users;
  final int totalCount;
  final int currentPage;

  const AdminUsersLoaded({
    required this.users,
    required this.totalCount,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [users, totalCount, currentPage];
}

class AdminUserUpdated extends AdminUsersState {
  final AdminUserModel user;

  const AdminUserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

class AdminUserDeleted extends AdminUsersState {
  final String userId;

  const AdminUserDeleted(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AdminUsersError extends AdminUsersState {
  final String message;

  const AdminUsersError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Modelo de usuario para administración
class AdminUserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role; // 'Consumidor', 'Emprendedor', 'Administrador'
  final String status; // 'Activo', 'Inactivo', 'Suspendido'
  final DateTime joinDate;
  final DateTime? lastActiveDate;
  final int totalOrders;
  final double totalSpent;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.joinDate,
    this.lastActiveDate,
    required this.totalOrders,
    required this.totalSpent,
  });

  bool get isActive => status == 'Activo';

  static const roleLabels = {'consumer': 'Consumidor', 'entrepreneur': 'Emprendedor', 'admin': 'Administrador'};

  factory AdminUserModel.fromJson(Map<String, dynamic> j) => AdminUserModel(
    id: j['id'].toString(),
    name: (j['fullName'] ?? '').toString(),
    email: (j['email'] ?? '').toString(),
    role: roleLabels[j['role']] ?? j['role'].toString(),
    status: j['status'] == 'suspended' ? 'Suspendido' : 'Activo',
    joinDate: DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal() ?? DateTime.now(),
    lastActiveDate: DateTime.tryParse((j['lastLoginAt'] ?? '').toString())?.toLocal(),
    totalOrders: (j['totalOrders'] as num?)?.toInt() ?? 0,
    totalSpent: (j['totalSpent'] as num?)?.toDouble() ?? 0,
  );

  AdminUserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? status,
    DateTime? joinDate,
    DateTime? lastActiveDate,
    int? totalOrders,
    double? totalSpent,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      joinDate: joinDate ?? this.joinDate,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    role,
    status,
    joinDate,
    lastActiveDate,
    totalOrders,
    totalSpent,
  ];
}

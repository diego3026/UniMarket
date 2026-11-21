import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import 'admin_users_state.dart';

/// Administración de usuarios (GET /admin/users, PATCH /admin/users/{id}).
class AdminUsersCubit extends Cubit<AdminUsersState> {
  final ApiClient _api;
  AdminUsersCubit(this._api) : super(const AdminUsersInitial());

  List<AdminUserModel> _users = [];
  String? _query;
  String? _role;

  static const _roleKeys = {'Consumidor': 'consumer', 'Emprendedor': 'entrepreneur', 'Administrador': 'admin'};

  Future<void> loadUsers({int page = 1, int pageSize = 50}) async {
    if (_users.isEmpty) emit(const AdminUsersLoading());
    try {
      final r = await _api.get('/admin/users', query: {
        'page': page,
        'size': pageSize,
        if (_query != null && _query!.isNotEmpty) 'q': _query,
        if (_role != null) 'role': _role,
      }) as Map<String, dynamic>;
      _users = [for (final u in r['items'] as List) AdminUserModel.fromJson(u as Map<String, dynamic>)];
      emit(AdminUsersLoaded(users: _users, totalCount: (r['total'] as num).toInt(), currentPage: page));
    } on ApiException catch (e) {
      emit(AdminUsersError(e.message));
    }
  }

  Future<void> _setStatus(String userId, String status) async {
    try {
      await _api.patch('/admin/users/$userId', data: {'status': status});
      final u = _users.where((x) => x.id == userId).firstOrNull;
      if (u != null) {
        emit(AdminUserUpdated(u.copyWith(status: status == 'active' ? 'Activo' : 'Suspendido')));
      }
    } on ApiException catch (e) {
      emit(AdminUsersError(e.message));
    }
    await loadUsers();
  }

  Future<void> suspendUser(String userId) => _setStatus(userId, 'suspended');
  Future<void> activateUser(String userId) => _setStatus(userId, 'active');

  /// No se borran cuentas (hay pedidos e historial asociados): se suspenden.
  Future<void> deleteUser(String userId) => suspendUser(userId);

  Future<void> searchUsers(String query) {
    _query = query.trim();
    return loadUsers();
  }

  Future<void> filterByRole(String role) {
    _role = _roleKeys[role];
    return loadUsers();
  }

  Map<String, int> getUserStatistics() => {
    'totalUsers': _users.length,
    'activeUsers': _users.where((u) => u.isActive).length,
    'consumers': _users.where((u) => u.role == 'Consumidor').length,
    'entrepreneurs': _users.where((u) => u.role == 'Emprendedor').length,
  };
}

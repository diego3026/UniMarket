import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unimarket/domain/entities/notification_entity.dart';
import 'package:unimarket/domain/entities/user_role.dart';

import '../../../core/network/api_client.dart';
import '../../../data/api/mappers.dart';

part 'notifications_state.dart';

/// Avisos de la cuenta: estados de pedidos, pagos, reseñas y mensajes del admin.
class NotificationsCubit extends Cubit<NotificationsState> {
  final ApiClient _api;
  NotificationsCubit(this._api) : super(const NotificationsInitial());

  String _userId = '';

  Future<void> loadNotifications(String userId, [UserRole? _]) async {
    _userId = userId;
    if (state is! NotificationsLoaded) emit(const NotificationsLoading());
    try {
      final r = await _api.getCached('/me/notifications', query: {'size': 50}) as Json;
      emit(
        NotificationsLoaded(
          notifications: [for (final n in r['items'] as List) notificationFrom(n as Json, userId)],
        ),
      );
    } on ApiException catch (e) {
      if (state is! NotificationsLoaded) emit(NotificationsError(message: e.message));
    }
  }

  Future<void> refresh() => loadNotifications(_userId);

  List<NotificationEntity> get _items =>
      state is NotificationsLoaded ? (state as NotificationsLoaded).notifications : const [];

  Future<void> markAsRead(String notificationId) async {
    emit(
      NotificationsLoaded(
        notifications: [for (final n in _items) n.id == notificationId ? n.copyWith(isRead: true) : n],
      ),
    );
    try {
      await _api.post('/me/notifications/$notificationId/read');
    } on ApiException {
      // No es crítico: se corrige en la próxima carga.
    }
  }

  Future<void> markAllAsRead() async {
    emit(NotificationsLoaded(notifications: [for (final n in _items) n.copyWith(isRead: true)]));
    try {
      await _api.post('/me/notifications/read-all');
    } on ApiException {
      // No es crítico.
    }
  }

  int getUnreadCount() => _items.where((n) => !n.isRead).length;

  /// Oculta las leídas en este dispositivo.
  Future<void> deleteReadNotifications() async {
    emit(NotificationsLoaded(notifications: _items.where((n) => !n.isRead).toList()));
  }

  Future<void> deleteOldNotifications(DateTime beforeDate) async {
    emit(NotificationsLoaded(notifications: _items.where((n) => n.createdAt.isAfter(beforeDate)).toList()));
  }

  void clear() => emit(const NotificationsInitial());
}

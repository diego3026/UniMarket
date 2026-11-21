import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import 'reports_state.dart';

/// Reportes de la plataforma (GET /admin/reports?days=N).
class ReportsCubit extends Cubit<ReportsState> {
  final ApiClient _api;
  ReportsCubit(this._api) : super(const ReportsInitial());

  String selectedPeriod = 'Hoy';
  ReportsData? _data;
  Map<String, dynamic> _raw = const {};

  static const _days = {'Hoy': 1, 'Esta semana': 7, 'Este mes': 30, 'Este año': 365};

  Future<void> loadReports(String period) async {
    selectedPeriod = period;
    emit(const ReportsLoading());
    try {
      final days = _days[period] ?? 30;
      final r = await _api.get('/admin/reports', query: {'days': days}) as Map<String, dynamic>;
      // Para el crecimiento comparamos con usuarios totales (el backend no
      // expone altas por fecha); se muestra el total por rol.
      final users = Map<String, dynamic>.from(r['usersByRole'] as Map);
      final stores = Map<String, dynamic>.from(r['storesByStatus'] as Map);
      int sum(Map<String, dynamic> m) => m.values.fold(0, (a, v) => a + (v as num).toInt());
      final top = r['topStores'] as List;
      _raw = r;
      _data = ReportsData(
        totalSales: (r['grossSales'] as num).toDouble(),
        totalOrders: (r['ordersTotal'] as num).toInt(),
        totalUsers: sum(users),
        totalBusinesses: (stores['approved'] as num?)?.toInt() ?? 0,
        topSellers: [
          for (var i = 0; i < top.length; i++)
            TopSeller(
              rank: i + 1,
              name: (top[i]['name'] ?? '').toString(),
              revenue: (top[i]['total'] as num).toDouble(),
              sales: (top[i]['orders'] as num).toInt(),
            ),
        ],
        salesData: [
          for (final d in r['ordersByDay'] as List)
            SalesData(
              date: DateTime.tryParse(d['date'].toString()) ?? DateTime.now(),
              amount: (d['total'] as num).toDouble(),
              orderCount: (d['orders'] as num).toInt(),
            ),
        ],
        userGrowth: UserGrowthData(
          newUsersToday: (users['consumer'] as num?)?.toInt() ?? 0,
          newUsersThisWeek: (users['entrepreneur'] as num?)?.toInt() ?? 0,
          newUsersThisMonth: sum(users),
          growthPercentage: 0,
        ),
        reportDate: DateTime.now(),
      );
      emit(ReportsLoaded(_data!));
    } on ApiException catch (e) {
      emit(ReportsError(e.message));
    }
  }

  /// Resumen en CSV (separado por ;) listo para pegar en una hoja de cálculo.
  String? exportCsv() {
    final d = _data;
    if (d == null) return null;
    final b = StringBuffer()
      ..writeln('Reporte UniMarket;$selectedPeriod')
      ..writeln('Ventas;${d.totalSales.toInt()}')
      ..writeln('Pedidos;${d.totalOrders}')
      ..writeln('Ticket promedio;${_raw['averageTicket'] ?? 0}')
      ..writeln('Usuarios;${d.totalUsers}')
      ..writeln('Tiendas activas;${d.totalBusinesses}')
      ..writeln()
      ..writeln('Fecha;Pedidos;Ventas');
    for (final s in d.salesData) {
      b.writeln('${s.date.toIso8601String().substring(0, 10)};${s.orderCount};${s.amount.toInt()}');
    }
    b
      ..writeln()
      ..writeln('Tienda;Pedidos;Ventas');
    for (final t in d.topSellers) {
      b.writeln('${t.name};${t.sales};${t.revenue.toInt()}');
    }
    return b.toString();
  }
}

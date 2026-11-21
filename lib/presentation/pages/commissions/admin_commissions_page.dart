import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';
import '../../../core/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import 'commission_statement.dart';

/// Admin: comisión del mes por tienda (GET /admin/commissions).
class AdminCommissionsPage extends StatefulWidget {
  const AdminCommissionsPage({super.key});

  @override
  State<AdminCommissionsPage> createState() => _AdminCommissionsPageState();
}

class _AdminCommissionsPageState extends State<AdminCommissionsPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<Map<String, dynamic>>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _rows = null;
      _error = null;
    });
    try {
      final r =
          await sl<ApiClient>().get(
                '/admin/commissions',
                query: {'month': monthKey(_month)},
              )
              as List;
      if (mounted)
        setState(
          () =>
              _rows = [for (final x in r) Map<String, dynamic>.from(x as Map)],
        );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _detail(Map<String, dynamic> row) async {
    try {
      final r = await sl<ApiClient>().get(
        '/admin/commissions/${row['storeId']}',
        query: {'month': monthKey(_month)},
      );
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (c) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          builder: (c, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${row['storeName']} · ${monthName(_month)}',
                style: Theme.of(c).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              CommissionStatementView(
                data: Map<String, dynamic>.from(r as Map),
              ),
            ],
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _copyCsv() {
    final b = StringBuffer(
      'Tienda;Ventas;Exentas;Con comisión;Comisión;En revisión\n',
    );
    for (final r in _rows ?? const <Map<String, dynamic>>[]) {
      b.writeln(
        '${r['storeName']};${r['totalSales']};${r['freeSales']};${r['chargeableSales']};'
        '${r['commission']};${r['disputedOrders']}',
      );
    }
    Clipboard.setData(ClipboardData(text: b.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copiado. Pégalo en Excel o Google Sheets.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final rows = _rows ?? const <Map<String, dynamic>>[];
    final total = rows.fold<int>(
      0,
      (s, r) => s + (r['commission'] as num).toInt(),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comisiones'),
        actions: [
          IconButton(
            tooltip: 'Copiar CSV',
            onPressed: rows.isEmpty ? null : _copyCsv,
            icon: const Icon(Icons.copy_all_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            MonthSwitcher(
              month: _month,
              onChanged: (m) {
                setState(() => _month = m);
                _load();
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              )
            else if (_rows == null)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightPanel,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total a cobrar', style: t.bodySmall),
                    Text(formatCop(total), style: t.headlineSmall),
                    Text(
                      '${rows.length} tienda(s) con ventas',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const Center(child: Text('No hubo ventas en este mes')),
              for (final r in rows)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => _detail(r),
                  title: Text('${r['storeName']}'),
                  subtitle: Text(
                    'Ventas ${formatCop((r['totalSales'] as num).toInt())}'
                    '${(r['freeSales'] as num) > 0 ? ' · exentas ${formatCop((r['freeSales'] as num).toInt())}' : ''}'
                    '${(r['disputedOrders'] as num) > 0 ? ' · ${r['disputedOrders']} en revisión' : ''}',
                  ),
                  trailing: Text(
                    formatCop((r['commission'] as num).toInt()),
                    style: t.titleSmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

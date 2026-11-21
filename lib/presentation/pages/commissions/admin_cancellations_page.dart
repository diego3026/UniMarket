import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../core/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';

/// Admin: cancelaciones por tienda (alertas) y pedidos en revisión.
class AdminCancellationsPage extends StatefulWidget {
  const AdminCancellationsPage({super.key});

  @override
  State<AdminCancellationsPage> createState() => _AdminCancellationsPageState();
}

class _AdminCancellationsPageState extends State<AdminCancellationsPage> {
  List<Map<String, dynamic>>? _risk;
  List<Map<String, dynamic>>? _disputes;
  String? _error;

  ApiClient get _api => sl<ApiClient>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([
        _api.get('/admin/stores-risk'),
        _api.get('/admin/disputes'),
      ]);
      if (!mounted) return;
      setState(() {
        _risk = [
          for (final x in r[0] as List) Map<String, dynamic>.from(x as Map),
        ];
        _disputes = [
          for (final x in r[1] as List) Map<String, dynamic>.from(x as Map),
        ];
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _decide(Map<String, dynamic> o, String decision) async {
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          decision == 'confirmed' ? 'Contar como venta' : 'Descartar revisión',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              decision == 'confirmed'
                  ? 'El pedido #${o['id']} sumará a la comisión de ${o['storeName']}.'
                  : 'El pedido #${o['id']} no contará como venta.',
            ),
            TextField(
              controller: note,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Nota para la tienda (opcional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(
              decision == 'confirmed' ? 'Contar como venta' : 'Descartar',
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.post(
        '/admin/orders/${o['id']}/dispute',
        data: {'decision': decision, 'note': note.text.trim()},
      );
      await _load();
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cancelaciones'),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Tiendas'),
              Tab(
                text:
                    'En revisión${_disputes == null || _disputes!.isEmpty ? '' : ' (${_disputes!.length})'}',
              ),
            ],
          ),
        ),
        body: _error != null
            ? Center(child: Text(_error!))
            : _risk == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Últimos 30 días. Se marca en rojo si la tienda cancela más del 15 % de sus pedidos '
                          '(mínimo 5) o tiene cancelaciones con pago o contradichas por el cliente.',
                          style: t.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        if (_risk!.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Sin pedidos'),
                          ),
                        for (final r in _risk!)
                          Card(
                            elevation: 0,
                            color: r['alert'] == true
                                ? AppColors.danger.withValues(alpha: 0.06)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: r['alert'] == true
                                    ? AppColors.danger
                                    : AppColors.border,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${r['storeName']}',
                                          style: t.titleSmall,
                                        ),
                                      ),
                                      Text(
                                        '${((r['cancelRate'] as num) * 100).round()} % cancelados',
                                        style: t.titleSmall?.copyWith(
                                          color: r['alert'] == true
                                              ? AppColors.danger
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${r['orders']} pedidos · ${r['cancelled']} cancelados '
                                    '(${r['cancelledByStore']} por la tienda)',
                                    style: t.bodySmall,
                                  ),
                                  Text(
                                    'Después de aceptar: ${r['cancelledAfterAccept']} · Con pago: '
                                    '${r['cancelledWithPayment']} · Contradichas: ${r['contradictedByCustomer']}',
                                    style: t.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_disputes!.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No hay pedidos en revisión'),
                          ),
                        for (final o in _disputes!)
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pedido #${o['id']} · ${o['storeName']}',
                                    style: t.titleSmall,
                                  ),
                                  Text(
                                    '${o['customerName']} · ${formatCop((o['total'] as num).toInt())} · '
                                    '${DateFormat('d MMM, h:mm a', 'es_CO').format(DateTime.parse('${o['createdAt']}').toLocal())}',
                                    style: t.bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (o['paidCancelled'] == true)
                                        const Chip(
                                          label: Text('Cancelado con pago'),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      if (o['customerConfirmation'] ==
                                          'received')
                                        const Chip(
                                          label: Text(
                                            'El cliente dice que lo recibió',
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      if ('${o['paymentReference']}'.isNotEmpty)
                                        Chip(
                                          label: Text(
                                            'Ref. pago ${o['paymentReference']}',
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                  if ('${o['cancelReason']}'.isNotEmpty)
                                    Text(
                                      'Motivo de la tienda: ${o['cancelReason']}',
                                      style: t.bodySmall,
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              _decide(o, 'dismissed'),
                                          child: const Text('Descartar'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () =>
                                              _decide(o, 'confirmed'),
                                          child: const Text(
                                            'Contar como venta',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

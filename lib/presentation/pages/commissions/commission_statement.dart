import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../core/utils/formatters.dart';

/// Resumen de comisión de un mes (respuesta de /seller/commissions o /admin/commissions/{id}).
class CommissionStatementView extends StatelessWidget {
  final Map<String, dynamic> data;
  const CommissionStatementView({super.key, required this.data});

  static String pct(num r) =>
      '${(r * 100).toStringAsFixed(r * 100 % 1 == 0 ? 0 : 1)} %';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    int n(String k) => (data[k] as num?)?.toInt() ?? 0;
    final freeUntil = DateTime.tryParse(
      '${data['freeUntil'] ?? ''}',
    )?.toLocal();
    final isFreeNow = freeUntil != null && freeUntil.isAfter(DateTime.now());
    final lines = (data['lines'] as List?) ?? const [];
    final low = (data['lowRate'] as num?) ?? 0.01;
    final high = (data['highRate'] as num?) ?? 0.02;
    final limit = n('tierLimit');
    final date = DateFormat("d 'de' MMMM 'de' y", 'es_CO');

    Widget row(String a, String b, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(a, style: t.bodyMedium)),
          Text(b, style: bold ? t.titleMedium : t.bodyMedium),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isFreeNow)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Sin comisión hasta el ${date.format(freeUntil)} (primeros 2 meses).',
              style: t.bodyMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row('Ventas del mes', formatCop(n('totalSales'))),
              if (n('freeSales') > 0)
                row(
                  'Exentas (primeros 2 meses)',
                  '− ${formatCop(n('freeSales'))}',
                ),
              row('Ventas con comisión', formatCop(n('chargeableSales'))),
              const Divider(height: 20),
              Text(
                '${pct(low)} hasta ${formatCop(limit)} y ${pct(high)} sobre el excedente',
                style: t.bodySmall,
              ),
              row('Comisión a pagar', formatCop(n('commission')), bold: true),
              if (n('disputedOrders') > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Incluye ${n('disputedOrders')} pedido(s) cancelado(s) que el cliente indicó haber recibido.',
                    style: t.bodySmall?.copyWith(color: AppColors.warning),
                  ),
                ),
            ],
          ),
        ),
        if (lines.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Pedidos del mes', style: t.titleSmall),
          for (final l in lines)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                l['kind'] == 'disputed'
                    ? Icons.report_problem_outlined
                    : Icons.check_circle_outline_rounded,
                color: l['kind'] == 'disputed'
                    ? AppColors.warning
                    : AppColors.success,
              ),
              title: Text('Pedido #${l['orderId']}'),
              subtitle: Text(
                [
                  DateFormat(
                    'd MMM',
                    'es_CO',
                  ).format(DateTime.parse('${l['date']}').toLocal()),
                  if (l['kind'] == 'disputed') 'en revisión',
                  if (l['free'] == true) 'exento',
                ].join(' · '),
              ),
              trailing: Text(formatCop((l['amount'] as num).toInt())),
            ),
        ],
      ],
    );
  }
}

/// Mes en formato AAAA-MM y su nombre ("noviembre 2026").
String monthKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
String monthName(DateTime d) => DateFormat('MMMM y', 'es_CO').format(d);

/// Selector de mes: ‹ noviembre 2026 ›
class MonthSwitcher extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Mes anterior',
          onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Flexible(
          child: Text(
            monthName(month),
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Mes siguiente',
          onPressed: isCurrent
              ? null
              : () => onChanged(DateTime(month.year, month.month + 1)),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:unimarket/presentation/viewmodels/catalog/catalog_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/market_entities.dart';
import '../../viewmodels/market/market_cubits.dart';
import '../../widgets/ui/app_widgets.dart';

/// Inicio del emprendedor (Figma Emprendedor: "Principal Tienda").
/// Las órdenes son las mismas que el cliente sigue en "Mis pedidos".
class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  static const _tabs = [
    'Por aceptar',
    'En preparación',
    'Listas / en camino',
    'Entregadas',
  ];
  String _tab = 'Por aceptar';
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Los pedidos nuevos llegan sin recargar: se consulta cada 20 s.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) context.read<MarketOrdersCubit>().loadStore();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  bool _match(MarketOrder o) => switch (_tab) {
    'Por aceptar' => o.status == OrderStatus.pending,
    'En preparación' => o.status == OrderStatus.preparing,
    'Listas / en camino' =>
      o.status == OrderStatus.ready || o.status == OrderStatus.onTheWay,
    _ => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled,
  };

  @override
  Widget build(BuildContext context) {
    context.watch<CatalogCubit>(); // se reconstruye cuando llegan los datos de la API
    final t = Theme.of(context).textTheme;
    final store = Catalog.myStoreOrEmpty;
    final settings = context.watch<StoreSettingsCubit>().of(store.id);
    final all = context.watch<MarketOrdersCubit>().forStore(store.id);
    final orders = all.where(_match).toList();
    final pending = all.where((o) => o.status == OrderStatus.pending).length;
    final today = all
        .where((o) => o.status == OrderStatus.delivered)
        .fold<double>(0, (s, o) => s + o.total);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.sellerGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    16,
                    AppTheme.pagePadding,
                    22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bienvenido a',
                                  style: t.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  store.name,
                                  style: t.headlineSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CircleIconButton(
                            icon: Icons.tune_rounded,
                            tooltip: 'Configurar tienda',
                            onPressed: () =>
                                context.push(AppRoutes.sellerSettings),
                          ),
                          const SizedBox(width: 8),
                          CircleIconButton(
                            icon: Icons.notifications_none_rounded,
                            tooltip: 'Notificaciones',
                            onPressed: () =>
                                context.push(AppRoutes.notifications),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.info,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Horario',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    settings.isOpen
                                        ? 'Abierto ahora'
                                        : 'Cerrado',
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Switch(
                                  value: settings.isOpen,
                                  activeTrackColor: AppColors.success,
                                  onChanged: (v) => context
                                      .read<StoreSettingsCubit>()
                                      .update(settings.copyWith(isOpen: v)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Recogen en ${Catalog.place(settings.pickupPlaceId).name} · ${store.schedule}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.seller,
                                      minimumSize: const Size.fromHeight(44),
                                    ),
                                    onPressed: () =>
                                        context.push(AppRoutes.sellerSchedule),
                                    icon: const Icon(
                                      Icons.edit_calendar_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Horario'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white38,
                                      ),
                                      minimumSize: const Size.fromHeight(44),
                                    ),
                                    onPressed: () =>
                                        context.go(AppRoutes.sellerPromos),
                                    icon: const Icon(
                                      Icons.local_offer_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Promos'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding,
                16,
                AppTheme.pagePadding,
                0,
              ),
              child: Row(
                children: [
                  _Kpi(
                    label: 'Por aceptar',
                    value: '$pending',
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  _Kpi(
                    label: 'Activas',
                    value: '${all.where((o) => o.status.isActive).length}',
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 10),
                  _Kpi(
                    label: 'Vendido',
                    value: formatCop(today),
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding,
                20,
                AppTheme.pagePadding,
                12,
              ),
              child: Text('Órdenes', style: t.headlineSmall),
            ),
          ),
          SliverToBoxAdapter(
            child: ChoiceChipsRow(
              options: _tabs,
              selected: _tab,
              color: AppColors.seller,
              onSelected: (v) => setState(() => _tab = v),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (orders.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.inbox_outlined,
                title: 'Sin órdenes aquí',
                message:
                    'Cuando lleguen pedidos nuevos aparecerán en esta lista.',
              ),
            )
          else
            SliverList.separated(
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.pagePadding,
                ),
                child: _SellerOrderCard(order: orders[i]),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Kpi({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: SurfaceCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              child: Text(value, style: t.titleLarge?.copyWith(color: color)),
            ),
            Text(
              label,
              style: t.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerOrderCard extends StatelessWidget {
  final MarketOrder order;
  const _SellerOrderCard({required this.order});

  static void _snack(BuildContext context, String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<String?> _ask(BuildContext context, {required String title, required String label, String? hint,
      bool digits = false, required String confirm, String? warning}) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (warning != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(warning, style: const TextStyle(fontSize: 13)),
              ),
            TextField(
              controller: c,
              autofocus: true,
              maxLength: digits ? 4 : 200,
              keyboardType: digits ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(labelText: label, hintText: hint),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: Text(confirm)),
        ],
      ),
    );
  }

  Future<void> _advance(BuildContext context, MarketOrder o) async {
    final cubit = context.read<MarketOrdersCubit>();
    String? code;
    if (o.status == OrderStatus.ready && o.mode == FulfillmentMode.pickup) {
      code = await _ask(context,
          title: 'Entregar pedido #${o.id}',
          label: 'Código de 4 dígitos del cliente',
          hint: '0000',
          digits: true,
          confirm: 'Entregar pedido');
      if (code == null) return;
      if (!RegExp(r'^\d{4}$').hasMatch(code)) {
        if (context.mounted) _snack(context, 'El código tiene 4 dígitos');
        return;
      }
    }
    final err = await cubit.advance(o.id, pickupCode: code);
    if (!context.mounted) return;
    _snack(context, err ?? 'Orden #${o.id}: ${cubit.byId(o.id)?.status.label.toLowerCase() ?? 'actualizada'}. El cliente ya lo ve.');
  }

  Future<void> _reject(BuildContext context, MarketOrder o) async {
    final cubit = context.read<MarketOrdersCubit>();
    final reason = await _ask(context,
        title: 'Rechazar pedido #${o.id}',
        label: 'Motivo (lo verá el cliente)',
        hint: 'Ej. Se nos acabó el producto',
        confirm: 'Rechazar pedido',
        warning: o.paymentStatus == PaymentStatus.reported || o.paymentStatus == PaymentStatus.paid
            ? 'El cliente ya reportó o confirmaste el pago. Si cancelas debes devolverle el 100 % en máximo 2 días '
                  'hábiles y el pedido quedará en revisión.'
            : 'Le preguntaremos al cliente si recibió el pedido. Cancelar pedidos que sí vendiste va contra los '
                  'términos y condiciones.');
    if (reason == null) return;
    final err = await cubit.cancel(o.id, reason: reason);
    if (context.mounted) _snack(context, err ?? 'Pedido #${o.id} rechazado');
  }

  Future<void> _confirmPayment(BuildContext context, MarketOrder o, bool received) async {
    final err = await context.read<MarketOrdersCubit>().confirmPayment(o.id, received);
    if (context.mounted) {
      _snack(context, err ?? (received ? 'Pago confirmado' : 'Le avisamos al cliente que no llegó el pago'));
    }
  }

  Widget _paymentBox(BuildContext context, MarketOrder o) {
    final t = Theme.of(context).textTheme;
    final (Color color, String text) = switch (o.paymentStatus) {
      PaymentStatus.paid => (AppColors.success, 'Pago recibido'),
      PaymentStatus.reported => (
        AppColors.warning,
        'El cliente dice que ya pagó${o.paymentReference.isEmpty ? '' : ' · ref. ${o.paymentReference}'}. Revisa tu ${o.paymentKind == PaymentKind.nequi ? 'Nequi' : 'banco'}.',
      ),
      PaymentStatus.failed => (AppColors.danger, 'Marcaste que el pago no llegó'),
      _ => (AppColors.textSecondary, 'Esperando la transferencia del cliente'),
    };
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: t.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
          if (o.paymentStatus == PaymentStatus.reported)
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _confirmPayment(context, o, false),
                  child: const Text('No me llegó'),
                ),
                FilledButton.tonal(
                  onPressed: () => _confirmPayment(context, o, true),
                  child: const Text('Confirmar pago'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = order;
    final pickup = o.mode == FulfillmentMode.pickup;
    final action = switch (o.status) {
      OrderStatus.pending => 'Aceptar',
      OrderStatus.preparing => pickup ? 'Marcar listo' : 'Enviar pedido',
      OrderStatus.ready => 'Entregar (pedir código)',
      OrderStatus.onTheWay => 'Marcar entregado',
      _ => null,
    };

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Orden #${o.id}',
                  style: t.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: o.mode.label,
                color: pickup ? AppColors.info : AppColors.seller,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateFormat('h:mm a', 'es_CO').format(o.createdAt),
                  style: t.bodySmall,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${o.customerName} · ${pickup ? 'Recoge en tu punto' : 'Entregar en ${Catalog.place(o.placeId).name}${o.notes.isEmpty ? '' : ' (${o.notes})'}'}',
            style: t.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final l in o.lines)
            Text('${l.quantity} × ${l.name}', style: t.bodyMedium),
          if (o.couponCode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Cupón ${o.couponCode} (-${formatCop(o.couponDiscount)})',
                style: t.bodySmall?.copyWith(color: AppColors.success),
              ),
            ),
          if (o.paymentKind.isTransfer && o.status != OrderStatus.cancelled) _paymentBox(context, o),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatCop(o.total), style: t.titleLarge),
                  Text(o.paymentLabel, style: t.bodySmall),
                ],
              ),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (o.status == OrderStatus.pending)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: () => _reject(context, o),
                      child: const Text('Rechazar'),
                    ),
                  if (action != null)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.seller,
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () => _advance(context, o),
                      child: Text(action),
                    )
                  else
                    StatusChip.forOrder(o.status.label),
                ],
              ),
            ],
          ),
          if (o.rating != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < o.rating!
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    o.review.isEmpty
                        ? o.reviewTags.join(', ')
                        : '“${o.review}”',
                    style: t.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

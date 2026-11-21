import 'package:unimarket/presentation/viewmodels/catalog/catalog_cubit.dart';
import 'package:flutter/material.dart';
import 'package:unimarket/core/network/api_client.dart';
import 'package:unimarket/presentation/viewmodels/product/product_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/market_entities.dart';
import '../../models/cart_item.dart';
import '../../viewmodels/cart/cart_cubit.dart';
import '../../viewmodels/market/market_cubits.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/campus_map.dart';
import '../../widgets/ui/payment_widgets.dart';
import '../../widgets/ui/product_image.dart';

/// Finalizar compra en una sola pantalla (Figma: "Pedido").
///
/// Todo sale de lo que configuró el emprendedor: si hace domicilios, el costo,
/// dónde se recoge, el tiempo de preparación, qué medios de pago recibe y
/// qué cupones están activos.
class CheckoutPage extends StatefulWidget {
  final String storeId;
  final String storeName;

  const CheckoutPage({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late FulfillmentMode _mode;
  String _deliveryPlaceId = 'b8';
  final _notes = TextEditingController();
  final _coupon = TextEditingController();
  CouponResult? _couponResult;
  PaymentChoice? _payment;
  bool _showMap = false;
  bool _paying = false;
  bool _checkingCoupon = false;

  /// Si la red falla y se vuelve a tocar "Pagar", el servidor no duplica el pedido.
  final String _idempotencyKey = MarketOrdersCubit.newIdempotencyKey();

  @override
  void initState() {
    super.initState();
    final s = context.read<StoreSettingsCubit>().of(widget.storeId);
    _mode = s.allowsDelivery
        ? FulfillmentMode.delivery
        : FulfillmentMode.pickup;
    final card = context.read<WalletCubit>().state.defaultCard;
    _payment = s.acceptsBreb
        ? const PaymentChoice.breb()
        : s.acceptsNequi
        ? const PaymentChoice.nequi()
        : s.acceptsCash
        ? const PaymentChoice.cash()
        : (s.acceptsCard && card != null ? PaymentChoice.card(card) : null);
    final places = Catalog.places;
    if (places.isNotEmpty && !places.any((p) => p.id == _deliveryPlaceId)) {
      _deliveryPlaceId = places.first.id;
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _coupon.dispose();
    super.dispose();
  }

  List<CartItem> _items(CartState state) => state is CartLoaded
      ? state.items.where((i) => i.product.storeId == widget.storeId).toList()
      : <CartItem>[];

  Future<void> _applyCoupon(double subtotal) async {
    FocusScope.of(context).unfocus();
    setState(() => _checkingCoupon = true);
    final r = await context.read<PromotionsCubit>().validateCoupon(
      _coupon.text,
      widget.storeId,
      subtotal,
    );
    if (!mounted) return;
    setState(() {
      _couponResult = r;
      _checkingCoupon = false;
    });
  }

  Future<void> _pay({
    required StoreSettings settings,
    required List<CartItem> items,
    required double couponDiscount,
    required double deliveryFee,
  }) async {
    if (_payment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige un método de pago para continuar')),
      );
      return;
    }
    setState(() => _paying = true);
    try {
      final order = await context.read<MarketOrdersCubit>().place(
        storeId: widget.storeId,
        items: items,
        mode: _mode,
        placeId: _mode == FulfillmentMode.pickup
            ? settings.pickupPlaceId
            : _deliveryPlaceId,
        notes: _notes.text.trim(),
        coupon: _couponResult?.promotion,
        payment: _payment!,
        idempotencyKey: _idempotencyKey,
      );
      if (!mounted) return;
      context.read<CartCubit>().removeStore(widget.storeId);
      context.pushReplacement(AppRoutes.orderSuccessPath(order.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      // Si cambió el precio o el stock, se actualiza el catálogo para mostrar lo real.
      if (e.code == 'out_of_stock' || e.code == 'product_unavailable') {
        context.read<ProductCubit>().loadProducts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final settings = context.watch<StoreSettingsCubit>().of(widget.storeId);
    final coupons = context.watch<PromotionsCubit>().activeCoupons(
      widget.storeId,
    );

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final items = _items(cartState);
        if (items.isEmpty && !_paying) {
          return Scaffold(
            appBar: AppBar(title: const Text('Finalizar compra')),
            body: EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'No hay productos de ${widget.storeName}',
              message: 'Vuelve a la tienda para agregar algo.',
              actionLabel: 'Ir a la tienda',
              onAction: () =>
                  context.pushReplacement(AppRoutes.storePath(widget.storeId)),
            ),
          );
        }
        final subtotal = items.fold<double>(0, (s, i) => s + i.totalPrice);
        final savings = items.fold<double>(
          0,
          (s, i) => s + (i.product.price - i.product.finalPrice) * i.quantity,
        );
        // Si cambian las cantidades, el cupón se recalcula (el servidor confirma al pagar).
        final promo = _couponResult?.promotion;
        final CouponResult? coupon = promo == null
            ? _couponResult
            : subtotal < promo.minPurchase
            ? CouponResult(error: 'Compra mínima de ${formatCop(promo.minPurchase)} para este cupón')
            : CouponResult(promotion: promo, discount: promo.couponDiscount(subtotal));
        final couponDiscount = coupon?.discount ?? 0;
        final deliveryFee = _mode == FulfillmentMode.delivery
            ? settings.deliveryFee
            : 0.0;
        final total = subtotal - couponDiscount + deliveryFee;
        final pickupPlace = Catalog.place(settings.pickupPlaceId);
        final deliveryPlace = Catalog.place(_deliveryPlaceId);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Finalizar compra'),
                Text(widget.storeName, style: t.bodySmall),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              4,
              AppTheme.pagePadding,
              24,
            ),
            children: [
              // 1. Cómo recibir
              SegmentedButton<FulfillmentMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                segments: [
                  ButtonSegment(
                    value: FulfillmentMode.delivery,
                    enabled: settings.allowsDelivery,
                    icon: const Icon(Icons.delivery_dining_rounded),
                    label: const Text('Domicilio'),
                  ),
                  ButtonSegment(
                    value: FulfillmentMode.pickup,
                    enabled: settings.allowsPickup,
                    icon: const Icon(Icons.storefront_rounded),
                    label: const Text('Ir a recoger'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (v) => setState(() => _mode = v.first),
              ),
              if (!settings.allowsDelivery)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${widget.storeName} solo entrega para recoger.',
                    style: t.bodySmall,
                  ),
                ),
              const SizedBox(height: 16),

              // 2. Dónde
              if (_mode == FulfillmentMode.delivery)
                _Section(
                  title: 'Entregar en',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const _RoundIcon(Icons.place_rounded),
                        title: Text(deliveryPlace.name),
                        subtitle: Text(deliveryPlace.hint),
                        trailing: TextButton(
                          onPressed: () async {
                            final p = await showCampusPlacePicker(
                              context,
                              title: '¿Dónde te lo llevamos?',
                              selectedId: _deliveryPlaceId,
                            );
                            if (p != null) {
                              setState(() => _deliveryPlaceId = p.id);
                            }
                          },
                          child: const Text('Cambiar'),
                        ),
                      ),
                      TextField(
                        controller: _notes,
                        decoration: const InputDecoration(
                          hintText: 'Salón, piso o indicaciones (opcional)',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _InfoLine(
                        icon: Icons.schedule_rounded,
                        text:
                            'Llega en ~${settings.prepMinutes + 10} min · Domicilio ${deliveryFee == 0 ? 'gratis' : formatCop(deliveryFee)}',
                      ),
                    ],
                  ),
                )
              else
                _Section(
                  title: 'Recoger en',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const _RoundIcon(Icons.storefront_rounded),
                        title: Text(pickupPlace.name),
                        subtitle: Text(
                          settings.pickupNotes.isEmpty
                              ? pickupPlace.hint
                              : settings.pickupNotes,
                        ),
                      ),
                      _InfoLine(
                        icon: Icons.timer_outlined,
                        text:
                            'Listo para recoger en ~${settings.prepMinutes} min. Te avisamos cuando esté listo.',
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _showMap = !_showMap),
                          icon: Icon(
                            _showMap
                                ? Icons.expand_less_rounded
                                : Icons.map_outlined,
                          ),
                          label: Text(
                            _showMap ? 'Ocultar mapa' : 'Ver en el mapa',
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        child: _showMap
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: CampusMap(
                                  height: 200,
                                  routeFrom: _deliveryPlaceId,
                                  routeTo: settings.pickupPlaceId,
                                  selectedPlaceId: settings.pickupPlaceId,
                                  pins: [
                                    MapPin(
                                      placeId: _deliveryPlaceId,
                                      icon: Icons.person_rounded,
                                      color: AppColors.info,
                                      label: 'Tú',
                                    ),
                                    MapPin(
                                      placeId: settings.pickupPlaceId,
                                      icon: Icons.storefront_rounded,
                                      color: AppColors.primary,
                                      label: widget.storeName,
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ),

              // 3. Productos
              _Section(
                title: 'Tu pedido',
                child: Column(
                  children: [
                    for (final i in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            ProductImage(
                              imageUrl: i.product.imageUrl,
                              category: i.product.category,
                              width: 52,
                              height: 52,
                              radius: 12,
                              iconSize: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    i.product.name,
                                    style: t.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    formatCop(i.totalPrice),
                                    style: t.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            QuantityStepper(
                              value: i.quantity,
                              onIncrement: () => context
                                  .read<CartCubit>()
                                  .updateQuantity(i.product.id, i.quantity + 1),
                              onDecrement: () => context
                                  .read<CartCubit>()
                                  .updateQuantity(i.product.id, i.quantity - 1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // 4. Cupón
              _Section(
                title: 'Cupón de descuento',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (coupon?.promotion != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_offer_rounded,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${coupon!.promotion!.code} aplicado · ahorras ${formatCop(couponDiscount)}',
                                style: t.titleSmall?.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Quitar cupón',
                              onPressed: () => setState(() {
                                _couponResult = null;
                                _coupon.clear();
                              }),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _coupon,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'Escribe tu código',
                                errorText: coupon?.error,
                              ),
                              onSubmitted: (_) => _applyCoupon(subtotal),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 54),
                            ),
                            onPressed: _checkingCoupon ? null : () => _applyCoupon(subtotal),
                            child: _checkingCoupon
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Aplicar'),
                          ),
                        ],
                      ),
                      if (coupons.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in coupons)
                              ActionChip(
                                avatar: const Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 18,
                                ),
                                label: Text('${c.code} · ${c.valueLabel}'),
                                onPressed: () {
                                  _coupon.text = c.code;
                                  _applyCoupon(subtotal);
                                },
                              ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              // 5. Pago
              _Section(
                title: 'Método de pago',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () async {
                    final p = await showPaymentPicker(
                      context,
                      settings: settings,
                      mode: _mode,
                      current: _payment,
                    );
                    if (p != null) setState(() => _payment = p);
                  },
                  leading: _RoundIcon(switch (_payment?.kind) {
                    PaymentKind.cash => Icons.payments_rounded,
                    PaymentKind.nequi => Icons.phone_iphone_rounded,
                    PaymentKind.breb => Icons.bolt_rounded,
                    PaymentKind.card => Icons.credit_card_rounded,
                    null => Icons.wallet_rounded,
                  }),
                  title: Text(
                    _payment?.label(_mode) ?? 'Elegir método de pago',
                  ),
                  subtitle: Text(
                    [
                      if (settings.acceptsBreb) 'Bre-B',
                      if (settings.acceptsNequi) 'Nequi',
                      if (settings.acceptsCash) 'Efectivo',
                      if (settings.acceptsCard) 'Tarjeta',
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ),

              // 6. Resumen
              _Section(
                title: 'Resumen de pago',
                child: Column(
                  children: [
                    _SummaryRow('Productos', formatCop(subtotal)),
                    if (savings > 0)
                      _SummaryRow(
                        'Ahorro por promociones',
                        '-${formatCop(savings)}',
                        color: AppColors.success,
                        hint: true,
                      ),
                    if (couponDiscount > 0)
                      _SummaryRow(
                        'Cupón ${coupon!.promotion!.code}',
                        '-${formatCop(couponDiscount)}',
                        color: AppColors.success,
                      ),
                    _SummaryRow(
                      _mode == FulfillmentMode.delivery
                          ? 'Domicilio'
                          : 'Recoger en tienda',
                      deliveryFee == 0 ? 'Gratis' : formatCop(deliveryFee),
                    ),
                    const Divider(height: 20),
                    _SummaryRow('Total', formatCop(total), bold: true),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Puedes cancelar sin costo mientras el emprendedor no haya aceptado tu pedido.',
                      style: t.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: BottomActionBar(
            child: FilledButton(
              onPressed: _paying
                  ? null
                  : () => _pay(
                      settings: settings,
                      items: items,
                      couponDiscount: couponDiscount,
                      deliveryFee: deliveryFee,
                    ),
              child: _paying
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Enviando pedido…'),
                      ],
                    )
                  : Text('Confirmar pedido · ${formatCop(total)}'),
            ),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    ),
  );
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  const _RoundIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: c),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool hint;
  final Color? color;
  const _SummaryRow(
    this.label,
    this.value, {
    this.bold = false,
    this.hint = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hint ? '$label (ya incluido)' : label,
              style: bold
                  ? t.titleMedium
                  : t.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: bold
                ? t.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  )
                : t.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: color != null ? FontWeight.w700 : null,
                  ),
          ),
        ],
      ),
    );
  }
}

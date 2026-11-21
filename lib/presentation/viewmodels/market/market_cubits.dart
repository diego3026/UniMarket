// lib/presentation/viewmodels/market/market_cubits.dart
//
// Estado compartido entre cliente y emprendedor (en memoria por ahora):
// - StoreSettingsCubit: ubicación de recogida, entregas y pagos de cada tienda.
// - PromotionsCubit: descuentos y cupones que crea el emprendedor.
// - MarketOrdersCubit: pedidos que crea el cliente y gestiona el emprendedor.
// - WalletCubit: tarjetas y Nequi del cliente.
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/datasources/mock/market_mock_data.dart';
import '../../../domain/entities/market_entities.dart';
import '../../models/cart_item.dart';

class StoreSettingsCubit extends Cubit<Map<String, StoreSettings>> {
  StoreSettingsCubit() : super(Map.of(MarketMockData.storeSettings));

  StoreSettings of(String storeId) =>
      state[storeId] ?? StoreSettings(storeId: storeId, pickupPlaceId: 'plaza');

  void update(StoreSettings settings) =>
      emit({...state, settings.storeId: settings});
}

/// Resultado de validar un cupón.
class CouponResult {
  final PromotionEntity? promotion;
  final double discount;
  final String? error;
  const CouponResult({this.promotion, this.discount = 0, this.error});
}

class PromotionsCubit extends Cubit<List<PromotionEntity>> {
  PromotionsCubit() : super(MarketMockData.promotions());

  List<PromotionEntity> forStore(String storeId) =>
      state.where((p) => p.storeId == storeId).toList();

  List<PromotionEntity> activeCoupons(String storeId) => state
      .where(
        (p) =>
            p.storeId == storeId &&
            p.kind == PromotionKind.coupon &&
            p.isRunning,
      )
      .toList();

  /// Promoción automática que aplica a un producto (la de mayor ahorro).
  PromotionEntity? bestFor(String storeId, String productId, double price) {
    PromotionEntity? best;
    for (final p in state) {
      if (p.storeId != storeId ||
          p.kind != PromotionKind.productDiscount ||
          !p.isRunning) {
        continue;
      }
      if (p.productIds.isNotEmpty && !p.productIds.contains(productId)) {
        continue;
      }
      if (best == null || p.apply(price) < best.apply(price)) best = p;
    }
    return best;
  }

  CouponResult validateCoupon(String code, String storeId, double subtotal) {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return const CouponResult(error: 'Escribe un código');
    PromotionEntity? promo;
    for (final p in state) {
      if (p.kind == PromotionKind.coupon && p.code.toUpperCase() == c) {
        promo = p;
      }
    }
    if (promo == null) return const CouponResult(error: 'Ese cupón no existe');
    if (promo.storeId != storeId) {
      return const CouponResult(error: 'Este cupón es de otro emprendimiento');
    }
    if (!promo.isRunning) {
      return const CouponResult(error: 'Este cupón ya no está activo');
    }
    if (subtotal < promo.minPurchase) {
      return CouponResult(
        error:
            'Compra mínima de ${formatCop(promo.minPurchase)} para usar este cupón',
      );
    }
    return CouponResult(
      promotion: promo,
      discount: subtotal - promo.apply(subtotal),
    );
  }

  void save(PromotionEntity promo) {
    final exists = state.any((p) => p.id == promo.id);
    emit(
      exists
          ? [for (final p in state) p.id == promo.id ? promo : p]
          : [promo, ...state],
    );
  }

  void toggle(String id, bool active) => emit([
    for (final p in state) p.id == id ? p.copyWith(active: active) : p,
  ]);

  void delete(String id) => emit(state.where((p) => p.id != id).toList());

  String newId() => 'pr${DateTime.now().millisecondsSinceEpoch}';
}

class MarketOrdersCubit extends Cubit<List<MarketOrder>> {
  MarketOrdersCubit() : super(MarketMockData.orders());

  final _rand = Random();

  MarketOrder? byId(String id) {
    for (final o in state) {
      if (o.id == id) return o;
    }
    return null;
  }

  List<MarketOrder> forCustomer(String name) =>
      state.where((o) => o.customerName == name).toList();

  List<MarketOrder> forStore(String storeId) =>
      state.where((o) => o.storeId == storeId).toList();

  MarketOrder place({
    required String storeId,
    required String storeName,
    required String customerName,
    required List<CartItem> items,
    required FulfillmentMode mode,
    required String placeId,
    required String notes,
    required double deliveryFee,
    required PromotionEntity? coupon,
    required double couponDiscount,
    required String paymentLabel,
  }) {
    final now = DateTime.now();
    final subtotal = items.fold<double>(0, (s, i) => s + i.totalPrice);
    final order = MarketOrder(
      id: '${1046 + state.length}',
      pickupCode: (1000 + _rand.nextInt(9000)).toString(),
      storeId: storeId,
      storeName: storeName,
      customerName: customerName,
      lines: [
        for (final i in items)
          OrderLine(
            productId: i.product.id,
            name: i.product.name,
            category: i.product.category,
            unitPrice: i.product.finalPrice,
            quantity: i.quantity,
          ),
      ],
      subtotal: subtotal,
      couponCode: coupon?.code ?? '',
      couponDiscount: couponDiscount,
      deliveryFee: deliveryFee,
      mode: mode,
      placeId: placeId,
      notes: notes,
      paymentLabel: paymentLabel,
      status: OrderStatus.pending,
      createdAt: now,
      history: {OrderStatus.pending: now},
    );
    emit([order, ...state]);
    return order;
  }

  void _set(String id, OrderStatus status) => emit([
    for (final o in state)
      o.id == id
          ? o.copyWith(
              status: status,
              history: {...o.history, status: DateTime.now()},
            )
          : o,
  ]);

  /// Avanza al siguiente estado del flujo (aceptar, listo, entregado…).
  void advance(String id) {
    final next = byId(id)?.next;
    if (next != null) _set(id, next);
  }

  void cancel(String id) => _set(id, OrderStatus.cancelled);

  void rate(String id, int stars, String review, List<String> tags) => emit([
    for (final o in state)
      o.id == id
          ? o.copyWith(rating: stars, review: review, reviewTags: tags)
          : o,
  ]);
}

class WalletState {
  final List<PaymentCard> cards;
  final String nequiPhone;
  const WalletState({required this.cards, required this.nequiPhone});

  PaymentCard? get defaultCard {
    for (final c in cards) {
      if (c.isDefault) return c;
    }
    return cards.isEmpty ? null : cards.first;
  }
}

class WalletCubit extends Cubit<WalletState> {
  WalletCubit()
    : super(
        const WalletState(
          cards: MarketMockData.cards,
          nequiPhone: '300 123 4567',
        ),
      );

  void addCard({
    required String number,
    required String holder,
    required String expiry,
  }) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    final brand = digits.startsWith('4')
        ? 'Visa'
        : digits.startsWith('5')
        ? 'Mastercard'
        : digits.startsWith('3')
        ? 'Amex'
        : 'Tarjeta';
    final card = PaymentCard(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      brand: brand,
      last4: digits.substring(max(0, digits.length - 4)),
      holder: holder.toUpperCase(),
      expiry: expiry,
      isDefault: state.cards.isEmpty,
    );
    emit(
      WalletState(cards: [...state.cards, card], nequiPhone: state.nequiPhone),
    );
  }

  void remove(String id) {
    final rest = state.cards.where((c) => c.id != id).toList();
    if (rest.isNotEmpty && !rest.any((c) => c.isDefault)) {
      rest[0] = rest[0].copyWith(isDefault: true);
    }
    emit(WalletState(cards: rest, nequiPhone: state.nequiPhone));
  }

  void setDefault(String id) => emit(
    WalletState(
      cards: [for (final c in state.cards) c.copyWith(isDefault: c.id == id)],
      nequiPhone: state.nequiPhone,
    ),
  );

  void setNequi(String phone) =>
      emit(WalletState(cards: state.cards, nequiPhone: phone));
}

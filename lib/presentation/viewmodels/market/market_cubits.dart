// lib/presentation/viewmodels/market/market_cubits.dart
//
// Estado compartido entre cliente y emprendedor, conectado a la API:
// - StoreSettingsCubit: configuración de cada tienda (recogida, entregas, pagos).
// - PromotionsCubit: descuentos y cupones.
// - MarketOrdersCubit: pedidos (los del cliente o los de la tienda).
// - WalletCubit: tarjetas guardadas del cliente.
import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../data/api/mappers.dart';
import '../../../domain/entities/market_entities.dart';
import '../../models/cart_item.dart';
import '../catalog/catalog_cubit.dart';

class StoreSettingsCubit extends Cubit<Map<String, StoreSettings>> {
  final CatalogCubit _catalog;
  final ApiClient _api;
  late final StreamSubscription _sub;

  StoreSettingsCubit(this._catalog, this._api) : super(const {}) {
    _sub = _catalog.stream.listen((_) => emit(Map.of(_catalog.settings)));
  }

  StoreSettings of(String storeId) =>
      state[storeId] ?? _catalog.settings[storeId] ?? StoreSettings(storeId: storeId, pickupPlaceId: 'plaza');

  /// Guarda "Configurar tienda". Devuelve el error o null.
  Future<String?> update(StoreSettings settings) async {
    try {
      final j = await _api.patch('/seller/store', data: settingsToJson(settings)) as Json;
      _catalog.setMyStore(j);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}

/// Resultado de validar un cupón.
class CouponResult {
  final PromotionEntity? promotion;
  final double discount;
  final String? error;
  const CouponResult({this.promotion, this.discount = 0, this.error});
}

class PromotionsCubit extends Cubit<List<PromotionEntity>> {
  final ApiClient _api;
  PromotionsCubit(this._api) : super(const []);

  void _merge(List<PromotionEntity> items) {
    final byId = {for (final p in state) p.id: p};
    for (final p in items) {
      byId[p.id] = p;
    }
    emit(byId.values.toList());
  }

  /// Cupones y descuentos vigentes de todas las tiendas (pantalla Promos, banners).
  Future<void> loadPublic() async {
    try {
      final r = await Future.wait([
        _api.getCached('/promotions/coupons'),
        _api.getCached('/promotions/discounts'),
      ]);
      _merge([
        for (final list in r)
          for (final p in list as List) promotionFrom(p as Json),
      ]);
    } on ApiException {
      // Sin promociones no se bloquea la app.
    }
  }

  /// Promociones del emprendedor (incluye pausadas y vencidas).
  Future<void> loadMine() async {
    try {
      final r = await _api.get('/seller/promotions') as List;
      _merge([for (final p in r) promotionFrom(p as Json)]);
    } on ApiException {
      // Se reintenta al abrir la pantalla.
    }
  }

  /// Descuento automático vigente que aplica a un producto (para mostrar su nombre).
  PromotionEntity? discountFor(String storeId, String productId) {
    for (final p in state) {
      if (p.storeId == storeId &&
          p.kind == PromotionKind.productDiscount &&
          p.isRunning &&
          (p.productIds.isEmpty || p.productIds.contains(productId))) {
        return p;
      }
    }
    return null;
  }

  List<PromotionEntity> forStore(String storeId) => state.where((p) => p.storeId == storeId).toList();

  List<PromotionEntity> activeCoupons(String storeId) => state
      .where((p) => p.storeId == storeId && p.kind == PromotionKind.coupon && p.isRunning)
      .toList();

  /// Valida el cupón con el servidor (mínimo de compra, usos, vigencia).
  Future<CouponResult> validateCoupon(String code, String storeId, double subtotal) async {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return const CouponResult(error: 'Escribe un código');
    try {
      final r = await _api.post(
        '/orders/coupon-check',
        data: {'storeId': storeId, 'code': c, 'subtotal': subtotal.round()},
      ) as Json;
      if (r['valid'] != true) {
        return CouponResult(error: (r['message'] ?? 'El cupón no es válido').toString());
      }
      return CouponResult(
        promotion: r['promotion'] is Map ? promotionFrom(r['promotion'] as Json) : null,
        discount: (r['discount'] as num).toDouble(),
      );
    } on ApiException catch (e) {
      return CouponResult(error: e.message);
    }
  }

  static final _uuid = RegExp(r'^[0-9a-f-]{36}$');

  /// Crea o actualiza una promoción. Devuelve el error o null.
  Future<String?> save(PromotionEntity promo) async {
    try {
      final isNew = !_uuid.hasMatch(promo.id);
      final r = isNew
          ? await _api.post('/seller/promotions', data: promotionToJson(promo))
          : await _api.put('/seller/promotions/${promo.id}', data: promotionToJson(promo));
      final saved = promotionFrom(r as Json);
      emit([saved, ...state.where((p) => p.id != promo.id && p.id != saved.id)]);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> toggle(String id, bool active) async {
    try {
      final r = await _api.post('/seller/promotions/$id/${active ? 'resume' : 'pause'}');
      final p = promotionFrom(r as Json);
      emit([for (final x in state) x.id == id ? p : x]);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _api.delete('/seller/promotions/$id');
      emit(state.where((p) => p.id != id).toList());
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  String newId() => 'nuevo-${DateTime.now().millisecondsSinceEpoch}';

  void clear() => emit(const []);
}

class MarketOrdersCubit extends Cubit<List<MarketOrder>> {
  final ApiClient _api;
  MarketOrdersCubit(this._api) : super(const []);

  /// true si los pedidos cargados son los de la tienda (emprendedor).
  bool _asSeller = false;

  MarketOrder? byId(String id) {
    for (final o in state) {
      if (o.id == id) return o;
    }
    return null;
  }

  void _upsert(MarketOrder o) {
    final exists = state.any((x) => x.id == o.id);
    emit(exists ? [for (final x in state) x.id == o.id ? o : x] : [o, ...state]);
  }

  /// Pedidos del cliente.
  Future<void> loadMine() async {
    _asSeller = false;
    try {
      final r = await _api.getCached('/orders', query: {'size': 50}) as Json;
      emit([for (final o in r['items'] as List) orderFrom(o as Json)]);
    } on ApiException {
      // Se mantiene lo que ya había.
    }
  }

  /// Pedidos que recibe la tienda del emprendedor.
  Future<void> loadStore() async {
    _asSeller = true;
    try {
      final r = await _api.getCached('/seller/orders', query: {'size': 50}) as Json;
      emit([for (final o in r['items'] as List) orderFrom(o as Json)]);
    } on ApiException {
      // Se mantiene lo que ya había.
    }
  }

  Future<void> refresh() => _asSeller ? loadStore() : loadMine();

  /// Actualiza un pedido (seguimiento). Con ETag casi no gasta datos.
  Future<MarketOrder?> fetch(String id) async {
    try {
      final j = await _api.getCached('/orders/$id') as Json;
      final o = orderFrom(j);
      _upsert(o);
      return o;
    } on ApiException {
      return byId(id);
    }
  }

  List<MarketOrder> forCustomer(String _) => state;

  List<MarketOrder> forStore(String storeId) => state.where((o) => o.storeId == storeId).toList();

  /// Crea el pedido. El servidor calcula precios y totales. Lanza ApiException si falla.
  Future<MarketOrder> place({
    required String storeId,
    required List<CartItem> items,
    required FulfillmentMode mode,
    required String placeId,
    required String notes,
    required PromotionEntity? coupon,
    required PaymentChoice payment,
    required String idempotencyKey,
  }) async {
    final r = await _api.post(
      '/orders',
      headers: {'Idempotency-Key': idempotencyKey},
      data: {
        'storeId': storeId,
        'lines': [
          for (final i in items) {'productId': i.product.id, 'quantity': i.quantity},
        ],
        'mode': mode.name,
        if (mode == FulfillmentMode.delivery) 'placeId': placeId,
        'notes': notes,
        if (coupon != null && coupon.code.isNotEmpty) 'couponCode': coupon.code,
        'paymentKind': payment.kind.name,
        if (payment.card != null) 'paymentMethodId': payment.card!.id,
      },
    );
    final order = orderFrom(r as Json);
    _upsert(order);
    return order;
  }

  static String newIdempotencyKey() {
    final r = Random.secure();
    return List.generate(24, (_) => r.nextInt(16).toRadixString(16)).join();
  }

  Future<String?> _run(Future<dynamic> Function() call) async {
    try {
      final r = await call();
      if (r is Map) _upsert(orderFrom(r as Json));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Avanza al siguiente estado (emprendedor). Para entregar un pedido de
  /// recogida puede enviar el código que dicta el cliente.
  Future<String?> advance(String id, {String? pickupCode}) {
    final next = byId(id)?.next;
    if (next == null) return Future.value('El pedido ya terminó');
    return _run(
      () => _api.post(
        '/seller/orders/$id/status',
        data: {'status': next.name, if (pickupCode != null && pickupCode.isNotEmpty) 'pickupCode': pickupCode},
      ),
    );
  }

  /// Cancelar: el cliente (solo si está pendiente) o la tienda (rechazar).
  Future<String?> cancel(String id, {String reason = ''}) => _run(
    () => _asSeller
        ? _api.post('/seller/orders/$id/status', data: {'status': 'cancelled', 'reason': reason})
        : _api.post('/orders/$id/cancel', data: {'reason': reason}),
  );

  Future<String?> rate(String id, int stars, String review, List<String> tags) async {
    try {
      await _api.post('/orders/$id/review', data: {'rating': stars, 'comment': review, 'tags': tags});
      await fetch(id);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// "Ya pagué": el cliente avisa que transfirió.
  Future<String?> reportPayment(String id, String reference) =>
      _run(() => _api.post('/orders/$id/payment-report', data: {'reference': reference}));

  /// La tienda confirma si le llegó la transferencia.
  Future<String?> confirmPayment(String id, bool received) =>
      _run(() => _api.post('/seller/orders/$id/payment-confirm', data: {'received': received}));

  void clear() => emit(const []);
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
  final ApiClient _api;
  WalletCubit(this._api) : super(const WalletState(cards: [], nequiPhone: ''));

  Future<void> load() async {
    try {
      final r = await _api.get('/me/payment-methods') as List;
      emit(WalletState(cards: [for (final c in r) cardFrom(c as Json)], nequiPhone: state.nequiPhone));
    } on ApiException {
      // Se reintenta al abrir la billetera.
    }
  }

  /// Guarda la tarjeta. Al servidor solo viajan la marca y los últimos 4 dígitos:
  /// el número completo y el CVV nunca salen del teléfono.
  Future<String?> addCard({required String number, required String holder, required String expiry}) async {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    final brand = digits.startsWith('4')
        ? 'Visa'
        : digits.startsWith('5')
        ? 'Mastercard'
        : digits.startsWith('3')
        ? 'Amex'
        : 'Otra';
    final parts = expiry.split('/');
    final month = int.tryParse(parts.first.trim()) ?? 1;
    final year = 2000 + (int.tryParse(parts.length > 1 ? parts[1].trim() : '') ?? 0) % 100;
    try {
      await _api.post(
        '/me/payment-methods',
        data: {
          'brand': brand,
          'last4': digits.substring(max(0, digits.length - 4)),
          'holder': holder,
          'expMonth': month,
          'expYear': year,
          'isDefault': state.cards.isEmpty,
        },
      );
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> remove(String id) async {
    try {
      await _api.delete('/me/payment-methods/$id');
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> setDefault(String id) async {
    try {
      await _api.post('/me/payment-methods/$id/default');
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  void setNequi(String phone) => emit(WalletState(cards: state.cards, nequiPhone: phone));

  void clear() => emit(const WalletState(cards: [], nequiPhone: ''));
}

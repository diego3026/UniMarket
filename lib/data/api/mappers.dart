// lib/data/api/mappers.dart
//
// JSON de la API (camelCase) → entidades de la app.
import 'dart:ui';

import '../../domain/entities/market_entities.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/store_entity.dart';

typedef Json = Map<String, dynamic>;

double _d(Object? v) => v == null ? 0 : (v as num).toDouble();
int _i(Object? v) => v == null ? 0 : (v as num).toInt();
String _s(Object? v) => v?.toString() ?? '';
DateTime _dt(Object? v) => v == null ? DateTime.now() : DateTime.parse(v.toString()).toLocal();
DateTime? _dtn(Object? v) => v == null ? null : DateTime.parse(v.toString()).toLocal();

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

CampusPlace placeFrom(Json j) => CampusPlace(
  _s(j['id']),
  _s(j['name']),
  _s(j['hint']),
  description: _s(j['description']),
  kind: _enum(PlaceKind.values, j['kind'], PlaceKind.building),
  isDeliveryPoint: j['isDeliveryPoint'] != false,
  latitude: (j['latitude'] as num?)?.toDouble(),
  longitude: (j['longitude'] as num?)?.toDouble(),
  isActive: j['isActive'] != false,
);

Json placeToJson(CampusPlace p) => {
  'name': p.name.trim(),
  'hint': p.hint.trim(),
  'description': p.description.trim(),
  'kind': p.kind.name,
  'isDeliveryPoint': p.isDeliveryPoint,
  'latitude': p.latitude,
  'longitude': p.longitude,
  'isActive': p.isActive,
};

StoreEntity storeFrom(Json j) => StoreEntity(
  id: _s(j['id']),
  name: _s(j['name']),
  category: _s(j['category']),
  description: _s(j['description']),
  ownerName: _s(j['ownerName']),
  location: j['pickupPlace'] is Map ? _s((j['pickupPlace'] as Map)['name']) : 'Campus Universidad del Magdalena',
  schedule: _s(j['schedule']),
  rating: _d(j['rating']),
  ratingCount: _i(j['ratingCount']),
  deliveryMinutes: _i(j['prepMinutes']),
  isOpen: j['isOpen'] == true,
  imageUrl: _s(j['imageUrl']),
  menuSections: [for (final m in (j['menuSections'] as List? ?? const [])) m.toString()],
  status: _s(j['status']).isEmpty ? 'approved' : _s(j['status']),
);

StoreSettings settingsFrom(Json j) => StoreSettings(
  storeId: _s(j['id']),
  isOpen: j['isOpen'] == true,
  allowsDelivery: j['allowsDelivery'] == true,
  allowsPickup: j['allowsPickup'] == true,
  deliveryFee: _d(j['deliveryFee']),
  minOrder: _d(j['minOrder']),
  prepMinutes: _i(j['prepMinutes']),
  pickupPlaceId: _s(j['pickupPlaceId']).isEmpty ? 'plaza' : _s(j['pickupPlaceId']),
  pickupNotes: _s(j['pickupNotes']),
  acceptsCash: j['acceptsCash'] == true,
  acceptsNequi: j['acceptsNequi'] == true,
  acceptsCard: j['acceptsCard'] == true,
  acceptsBreb: j['acceptsBreb'] == true,
  nequiPhone: _s(j['nequiPhone']),
  brebKey: _s(j['brebKey']),
  phone: _s(j['phone']),
  address: _s(j['address']),
  latitude: (j['latitude'] as num?)?.toDouble(),
  longitude: (j['longitude'] as num?)?.toDouble(),
);

Json settingsToJson(StoreSettings s) => {
  'isOpen': s.isOpen,
  'allowsDelivery': s.allowsDelivery,
  'allowsPickup': s.allowsPickup,
  'deliveryFee': s.deliveryFee.round(),
  'minOrder': s.minOrder.round(),
  'prepMinutes': s.prepMinutes,
  'pickupPlaceId': s.pickupPlaceId,
  'pickupNotes': s.pickupNotes,
  'acceptsCash': s.acceptsCash,
  'acceptsNequi': s.acceptsNequi,
  'acceptsBreb': s.acceptsBreb,
  'nequiPhone': s.nequiPhone.replaceAll(RegExp(r'\D'), ''),
  'brebKey': s.brebKey.trim(),
  'phone': s.phone,
  'address': s.address.trim(),
  'latitude': s.latitude,
  'longitude': s.longitude,
};

ProductEntity productFrom(Json j) => ProductEntity(
  id: _s(j['id']),
  name: _s(j['name']),
  description: _s(j['description']),
  price: _d(j['price']),
  discountPrice: j['discountPrice'] == null ? null : _d(j['discountPrice']),
  category: _s(j['category']),
  imageUrl: _s(j['imageUrl']),
  stock: _i(j['stock']),
  rating: _d(j['rating']),
  isFeatured: j['isFeatured'] == true,
  createdAt: _dt(j['createdAt']),
  storeId: _s(j['storeId']),
  storeName: _s(j['storeName']),
);

PromotionEntity promotionFrom(Json j) => PromotionEntity(
  id: _s(j['id']),
  storeId: _s(j['storeId']),
  title: _s(j['title']),
  kind: _enum(PromotionKind.values, j['kind'], PromotionKind.coupon),
  type: _enum(DiscountType.values, j['type'], DiscountType.percent),
  value: _d(j['value']),
  productIds: [for (final p in (j['productIds'] as List? ?? const [])) p.toString()],
  code: _s(j['code']),
  minPurchase: _d(j['minPurchase']),
  endsAt: _dtn(j['endsAt']),
  active: j['active'] == true,
  uses: _i(j['uses']),
);

Json promotionToJson(PromotionEntity p) => {
  'title': p.title,
  'kind': p.kind.name,
  'type': p.type.name,
  'value': p.value.round(),
  'productIds': p.productIds,
  if (p.kind == PromotionKind.coupon) 'code': p.code.trim().toUpperCase(),
  'minPurchase': p.minPurchase.round(),
  'endsAt': p.endsAt?.toUtc().toIso8601String(),
  'active': p.active,
};

MarketOrder orderFrom(Json j) {
  final history = <OrderStatus, DateTime>{};
  final h = j['history'];
  if (h is Map) {
    h.forEach((k, v) {
      final st = _enum(OrderStatus.values, k, OrderStatus.pending);
      history[st] = _dt(v);
    });
  }
  final review = j['review'] is Map ? j['review'] as Json : null;
  final payTo = j['payTo'] is Map ? j['payTo'] as Json : null;
  return MarketOrder(
    id: _s(j['id']),
    pickupCode: _s(j['pickupCode']),
    storeId: _s(j['storeId']),
    storeName: _s(j['storeName']),
    customerName: _s(j['customerName']),
    customerPhone: _s(j['customerPhone']),
    lines: [
      for (final l in (j['lines'] as List? ?? const []))
        OrderLine(
          productId: _s((l as Json)['productId']),
          name: _s(l['name']),
          category: _s(l['category']),
          unitPrice: _d(l['unitPrice']),
          quantity: _i(l['quantity']),
        ),
    ],
    subtotal: _d(j['subtotal']),
    productDiscount: _d(j['productDiscount']),
    couponDiscount: _d(j['couponDiscount']),
    couponCode: _s(j['couponCode']),
    deliveryFee: _d(j['deliveryFee']),
    mode: _enum(FulfillmentMode.values, j['mode'], FulfillmentMode.pickup),
    placeId: _s(j['placeId']),
    placeName: _s(j['placeName']),
    notes: _s(j['notes']),
    paymentLabel: _s(j['paymentLabel']),
    paymentKind: _enum(PaymentKind.values, j['paymentKind'], PaymentKind.cash),
    paymentStatus: _enum(PaymentStatus.values, j['paymentStatus'], PaymentStatus.pending),
    paymentReference: _s(j['paymentReference']),
    payTo: payTo == null
        ? null
        : PayTo(
            kind: _enum(PaymentKind.values, payTo['kind'], PaymentKind.breb),
            key: _s(payTo['key']),
            holderName: _s(payTo['holderName']),
            amount: _d(payTo['amount']),
            referenceHint: _s(payTo['referenceHint']),
          ),
    status: _enum(OrderStatus.values, j['status'], OrderStatus.pending),
    createdAt: _dt(j['createdAt']),
    history: history.isEmpty ? {OrderStatus.pending: _dt(j['createdAt'])} : history,
    cancelReason: _s(j['cancelReason']),
    rating: review == null ? null : _i(review['rating']),
    review: review == null ? '' : _s(review['comment']),
    reviewTags: review == null ? const [] : [for (final t in (review['tags'] as List? ?? const [])) t.toString()],
    sellerReply: review == null ? '' : _s(review['sellerReply']),
  );
}

PaymentCard cardFrom(Json j) => PaymentCard(
  id: _s(j['id']),
  brand: _s(j['brand']),
  last4: _s(j['last4']),
  holder: _s(j['holder']),
  expiry: _s(j['expiry']),
  isDefault: j['isDefault'] == true,
);

NotificationEntity notificationFrom(Json j, String userId) {
  final data = j['data'] is Map ? j['data'] as Map : const {};
  final orderId = data['orderId'];
  return NotificationEntity(
    id: _s(j['id']),
    userId: userId,
    type: _s(j['type']) == 'order' ? 'order_update' : _s(j['type']),
    title: _s(j['title']),
    body: _s(j['body']),
    isRead: j['isRead'] == true,
    actionUrl: orderId == null ? null : '/order/$orderId',
    createdAt: _dt(j['createdAt']),
  );
}

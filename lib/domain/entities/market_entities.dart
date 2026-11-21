// lib/domain/entities/market_entities.dart
//
// Modelo compartido entre cliente y emprendedor: lugares del campus,
// configuración de cada tienda, promociones/cupones, pedidos y medios de pago.
import 'dart:ui';

import 'package:equatable/equatable.dart';

import '../../core/utils/formatters.dart';

/// Punto del campus de la Universidad del Magdalena.
/// [position] va de 0 a 1 en ambos ejes del mapa ilustrado.
class CampusPlace extends Equatable {
  final String id;
  final String name;
  final String hint;
  final Offset position;

  const CampusPlace(this.id, this.name, this.hint, this.position);

  @override
  List<Object?> get props => [id];
}

/// Cómo recibe el cliente su pedido.
enum FulfillmentMode {
  delivery('Domicilio'),
  pickup('Ir a recoger');

  final String label;
  const FulfillmentMode(this.label);
}

/// Configuración que el emprendedor controla desde "Configurar tienda".
class StoreSettings extends Equatable {
  final String storeId;
  final bool isOpen;
  final bool allowsDelivery;
  final bool allowsPickup;
  final double deliveryFee;
  final double minOrder;
  final int prepMinutes;
  final String pickupPlaceId;
  final String pickupNotes;
  final bool acceptsCash;
  final bool acceptsNequi;
  final bool acceptsCard;
  final bool acceptsBreb;
  final String nequiPhone;
  final String brebKey;
  final String phone;

  const StoreSettings({
    required this.storeId,
    this.isOpen = true,
    this.allowsDelivery = true,
    this.allowsPickup = true,
    this.deliveryFee = 2000,
    this.minOrder = 0,
    this.prepMinutes = 15,
    required this.pickupPlaceId,
    this.pickupNotes = '',
    this.acceptsCash = true,
    this.acceptsNequi = false,
    this.acceptsCard = false,
    this.acceptsBreb = false,
    this.nequiPhone = '',
    this.brebKey = '',
    this.phone = '',
  });

  StoreSettings copyWith({
    bool? isOpen,
    bool? allowsDelivery,
    bool? allowsPickup,
    double? deliveryFee,
    double? minOrder,
    int? prepMinutes,
    String? pickupPlaceId,
    String? pickupNotes,
    bool? acceptsCash,
    bool? acceptsNequi,
    bool? acceptsCard,
    bool? acceptsBreb,
    String? nequiPhone,
    String? brebKey,
    String? phone,
  }) => StoreSettings(
    storeId: storeId,
    isOpen: isOpen ?? this.isOpen,
    allowsDelivery: allowsDelivery ?? this.allowsDelivery,
    allowsPickup: allowsPickup ?? this.allowsPickup,
    deliveryFee: deliveryFee ?? this.deliveryFee,
    minOrder: minOrder ?? this.minOrder,
    prepMinutes: prepMinutes ?? this.prepMinutes,
    pickupPlaceId: pickupPlaceId ?? this.pickupPlaceId,
    pickupNotes: pickupNotes ?? this.pickupNotes,
    acceptsCash: acceptsCash ?? this.acceptsCash,
    acceptsNequi: acceptsNequi ?? this.acceptsNequi,
    acceptsCard: acceptsCard ?? this.acceptsCard,
    acceptsBreb: acceptsBreb ?? this.acceptsBreb,
    nequiPhone: nequiPhone ?? this.nequiPhone,
    brebKey: brebKey ?? this.brebKey,
    phone: phone ?? this.phone,
  );

  @override
  List<Object?> get props => [
    storeId,
    isOpen,
    allowsDelivery,
    allowsPickup,
    deliveryFee,
    minOrder,
    prepMinutes,
    pickupPlaceId,
    pickupNotes,
    acceptsCash,
    acceptsNequi,
    acceptsCard,
    acceptsBreb,
    nequiPhone,
    brebKey,
    phone,
  ];
}

enum PromotionKind {
  /// Rebaja automática en productos (se ve en el precio).
  productDiscount('Descuento en productos'),

  /// Código que el cliente escribe al pagar.
  coupon('Cupón');

  final String label;
  const PromotionKind(this.label);
}

enum DiscountType {
  percent('Porcentaje'),
  fixed('Valor fijo');

  final String label;
  const DiscountType(this.label);
}

/// Promoción o cupón creado por un emprendedor.
class PromotionEntity extends Equatable {
  final String id;
  final String storeId;
  final String title;
  final PromotionKind kind;
  final DiscountType type;
  final double value;

  /// Productos a los que aplica (vacío = todo el menú). Solo para descuentos.
  final List<String> productIds;

  /// Código del cupón (solo para cupones).
  final String code;
  final double minPurchase;
  final DateTime? endsAt;
  final bool active;
  final int uses;

  const PromotionEntity({
    required this.id,
    required this.storeId,
    required this.title,
    required this.kind,
    required this.type,
    required this.value,
    this.productIds = const [],
    this.code = '',
    this.minPurchase = 0,
    this.endsAt,
    this.active = true,
    this.uses = 0,
  });

  bool get isRunning =>
      active && (endsAt == null || endsAt!.isAfter(DateTime.now()));

  String get valueLabel => type == DiscountType.percent
      ? '-${value.round()} %'
      : '-${formatCop(value)}';

  /// Precio después de aplicar esta promoción a [price].
  double apply(double price) {
    final p = type == DiscountType.percent
        ? price * (1 - value / 100)
        : price - value;
    final rounded = (p / 100).round() * 100.0;
    return rounded.clamp(0, price).toDouble();
  }

  /// Descuento de un cupón sobre el subtotal (misma regla que el servidor).
  double couponDiscount(double subtotal) {
    final v = type == DiscountType.percent
        ? (subtotal * value / 100 / 100).round() * 100.0
        : value;
    return v.clamp(0, subtotal).toDouble();
  }

  PromotionEntity copyWith({
    String? title,
    PromotionKind? kind,
    DiscountType? type,
    double? value,
    List<String>? productIds,
    String? code,
    double? minPurchase,
    DateTime? endsAt,
    bool clearEndsAt = false,
    bool? active,
    int? uses,
  }) => PromotionEntity(
    id: id,
    storeId: storeId,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    type: type ?? this.type,
    value: value ?? this.value,
    productIds: productIds ?? this.productIds,
    code: code ?? this.code,
    minPurchase: minPurchase ?? this.minPurchase,
    endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
    active: active ?? this.active,
    uses: uses ?? this.uses,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    kind,
    type,
    value,
    productIds,
    code,
    minPurchase,
    endsAt,
    active,
    uses,
  ];
}

/// Tarjeta guardada en la billetera del cliente.
class PaymentCard extends Equatable {
  final String id;
  final String brand;
  final String last4;
  final String holder;
  final String expiry;
  final bool isDefault;

  const PaymentCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.holder,
    required this.expiry,
    this.isDefault = false,
  });

  PaymentCard copyWith({bool? isDefault}) => PaymentCard(
    id: id,
    brand: brand,
    last4: last4,
    holder: holder,
    expiry: expiry,
    isDefault: isDefault ?? this.isDefault,
  );

  @override
  List<Object?> get props => [id, isDefault];
}

enum PaymentKind {
  cash,
  nequi,
  breb,
  card;

  bool get isTransfer => this == nequi || this == breb;
}

/// Estado del pago de un pedido.
enum PaymentStatus {
  pending('Pendiente de pago'),
  reported('Pago reportado'),
  paid('Pagado'),
  failed('Pago no recibido'),
  refunded('Reembolsado'),
  authorized('Autorizado');

  final String label;
  const PaymentStatus(this.label);
}

/// A dónde transferir (llave Bre-B o Nequi del emprendedor).
class PayTo extends Equatable {
  final PaymentKind kind;
  final String key;
  final String holderName;
  final double amount;
  final String referenceHint;

  const PayTo({
    required this.kind,
    required this.key,
    required this.holderName,
    required this.amount,
    required this.referenceHint,
  });

  @override
  List<Object?> get props => [kind, key, amount];
}

/// Medio de pago elegido al finalizar la compra.
class PaymentChoice extends Equatable {
  final PaymentKind kind;
  final PaymentCard? card;

  const PaymentChoice.cash() : kind = PaymentKind.cash, card = null;
  const PaymentChoice.nequi() : kind = PaymentKind.nequi, card = null;
  const PaymentChoice.breb() : kind = PaymentKind.breb, card = null;
  const PaymentChoice.card(PaymentCard this.card) : kind = PaymentKind.card;

  String label(FulfillmentMode mode) => switch (kind) {
    PaymentKind.cash =>
      mode == FulfillmentMode.pickup
          ? 'Efectivo al recoger'
          : 'Efectivo contra entrega',
    PaymentKind.nequi => 'Transferencia Nequi',
    PaymentKind.breb => 'Transferencia Bre-B',
    PaymentKind.card => '${card!.brand} •••• ${card!.last4}',
  };

  @override
  List<Object?> get props => [kind, card?.id];
}

enum OrderStatus {
  pending('Pendiente'),
  preparing('Preparando'),
  ready('Listo para recoger'),
  onTheWay('En camino'),
  delivered('Entregado'),
  cancelled('Cancelado');

  final String label;
  const OrderStatus(this.label);

  bool get isActive => this != delivered && this != cancelled;
}

class OrderLine extends Equatable {
  final String productId;
  final String name;
  final String category;
  final double unitPrice;
  final int quantity;

  const OrderLine({
    required this.productId,
    required this.name,
    required this.category,
    required this.unitPrice,
    required this.quantity,
  });

  double get total => unitPrice * quantity;

  @override
  List<Object?> get props => [productId, quantity, unitPrice];
}

/// Pedido compartido: lo crea el cliente y lo gestiona el emprendedor.
class MarketOrder extends Equatable {
  final String id;
  final String pickupCode;
  final String storeId;
  final String storeName;
  final String customerName;
  final List<OrderLine> lines;
  final double subtotal;
  final double couponDiscount;
  final String couponCode;
  final double deliveryFee;
  final FulfillmentMode mode;
  final String placeId;
  final String notes;
  final String paymentLabel;
  final OrderStatus status;
  final DateTime createdAt;
  final Map<OrderStatus, DateTime> history;
  final int? rating;
  final String review;
  final List<String> reviewTags;
  final PaymentKind paymentKind;
  final PaymentStatus paymentStatus;
  final String paymentReference;
  final PayTo? payTo;
  final String customerPhone;
  final String placeName;
  final double productDiscount;
  final String cancelReason;
  final String sellerReply;

  const MarketOrder({
    required this.id,
    required this.pickupCode,
    required this.storeId,
    required this.storeName,
    required this.customerName,
    required this.lines,
    required this.subtotal,
    this.couponDiscount = 0,
    this.couponCode = '',
    required this.deliveryFee,
    required this.mode,
    required this.placeId,
    this.notes = '',
    required this.paymentLabel,
    required this.status,
    required this.createdAt,
    required this.history,
    this.rating,
    this.review = '',
    this.reviewTags = const [],
    this.paymentKind = PaymentKind.cash,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentReference = '',
    this.payTo,
    this.customerPhone = '',
    this.placeName = '',
    this.productDiscount = 0,
    this.cancelReason = '',
    this.sellerReply = '',
  });

  double get total => subtotal - couponDiscount + deliveryFee;
  int get itemCount => lines.fold(0, (s, l) => s + l.quantity);
  String get category => lines.isEmpty ? '' : lines.first.category;

  /// Estados por los que pasa este pedido según el modo de entrega.
  List<OrderStatus> get flow => mode == FulfillmentMode.pickup
      ? const [
          OrderStatus.pending,
          OrderStatus.preparing,
          OrderStatus.ready,
          OrderStatus.delivered,
        ]
      : const [
          OrderStatus.pending,
          OrderStatus.preparing,
          OrderStatus.onTheWay,
          OrderStatus.delivered,
        ];

  /// Siguiente estado o null si ya terminó.
  OrderStatus? get next {
    if (!status.isActive) return null;
    final i = flow.indexOf(status);
    return i >= 0 && i < flow.length - 1 ? flow[i + 1] : null;
  }

  MarketOrder copyWith({
    OrderStatus? status,
    Map<OrderStatus, DateTime>? history,
    int? rating,
    String? review,
    List<String>? reviewTags,
  }) => MarketOrder(
    id: id,
    pickupCode: pickupCode,
    storeId: storeId,
    storeName: storeName,
    customerName: customerName,
    lines: lines,
    subtotal: subtotal,
    couponDiscount: couponDiscount,
    couponCode: couponCode,
    deliveryFee: deliveryFee,
    mode: mode,
    placeId: placeId,
    notes: notes,
    paymentLabel: paymentLabel,
    status: status ?? this.status,
    createdAt: createdAt,
    history: history ?? this.history,
    rating: rating ?? this.rating,
    review: review ?? this.review,
    reviewTags: reviewTags ?? this.reviewTags,
    paymentKind: paymentKind,
    paymentStatus: paymentStatus,
    paymentReference: paymentReference,
    payTo: payTo,
    customerPhone: customerPhone,
    placeName: placeName,
    productDiscount: productDiscount,
    cancelReason: cancelReason,
    sellerReply: sellerReply,
  );

  @override
  List<Object?> get props => [id, status, history.length, rating, paymentStatus, paymentReference];
}

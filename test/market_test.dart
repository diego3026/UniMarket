import 'package:flutter_test/flutter_test.dart';
import 'package:unimarket/domain/entities/market_entities.dart';
import 'package:unimarket/domain/entities/product_entity.dart';
import 'package:unimarket/presentation/viewmodels/cart/cart_cubit.dart';
import 'package:unimarket/data/api/mappers.dart';

ProductEntity _product(String id, double price, {String store = 's2'}) =>
    ProductEntity(
      id: id,
      name: 'Producto $id',
      description: '',
      price: price,
      category: 'Bebidas',
      imageUrl: '',
      stock: 10,
      createdAt: DateTime(2026),
      storeId: store,
      storeName: 'MaracuMango',
    );

void main() {
  group('Promociones', () {
    test('el porcentaje redondea a cientos', () {
      const p = PromotionEntity(
        id: 'x',
        storeId: 's2',
        title: 't',
        kind: PromotionKind.productDiscount,
        type: DiscountType.percent,
        value: 17,
      );
      expect(p.apply(18000), 14900);
    });

    test('el valor fijo nunca deja el precio negativo', () {
      const p = PromotionEntity(
        id: 'x',
        storeId: 's2',
        title: 't',
        kind: PromotionKind.productDiscount,
        type: DiscountType.fixed,
        value: 5000,
      );
      expect(p.apply(3000), 0);
    });

    test('cupón porcentual redondea a cientos y no supera el subtotal', () {
      const p = PromotionEntity(
        id: 'c',
        storeId: 's2',
        title: 'Cupón',
        kind: PromotionKind.coupon,
        type: DiscountType.percent,
        value: 15,
        code: 'UNI15',
      );
      expect(p.couponDiscount(23450), 3500);
      const fixed = PromotionEntity(
        id: 'f',
        storeId: 's2',
        title: 'Fijo',
        kind: PromotionKind.coupon,
        type: DiscountType.fixed,
        value: 10000,
        code: 'MIL',
      );
      expect(fixed.couponDiscount(4000), 4000);
    });
  });

  group('Mapeo de la API', () {
    test('un pedido con transferencia trae a quién pagar', () {
      final o = orderFrom({
        'id': 'a1',
        'pickupCode': '4821',
        'storeId': 's2',
        'storeName': 'MaracuMango',
        'customerName': 'Ana',
        'lines': [
          {'productId': 'p1', 'name': 'Limón Coco', 'category': 'Bebidas', 'unitPrice': 6000, 'quantity': 2},
        ],
        'subtotal': 12000,
        'productDiscount': 0,
        'couponDiscount': 1000,
        'deliveryFee': 0,
        'total': 11000,
        'mode': 'pickup',
        'paymentKind': 'breb',
        'paymentStatus': 'pending',
        'payTo': {'kind': 'breb', 'key': '@maracumango', 'holderName': 'Laura', 'amount': 11000},
        'status': 'pending',
        'createdAt': '2026-11-20T15:00:00Z',
        'history': {'pending': '2026-11-20T15:00:00Z'},
      });
      expect(o.id, 'a1');
      expect(o.lines.single.quantity, 2);
      expect(o.paymentKind, PaymentKind.breb);
      expect(o.payTo?.key, '@maracumango');
      expect(o.status, OrderStatus.pending);
      expect(o.mode, FulfillmentMode.pickup);
    });

    test('un producto con promoción usa discountPrice', () {
      final p = productFrom({
        'id': 'p1',
        'storeId': 's2',
        'storeName': 'MaracuMango',
        'name': 'Picada',
        'description': '',
        'category': 'Frutas',
        'price': 10000,
        'discountPrice': 8000,
        'imageUrl': '',
        'stock': 3,
        'isAvailable': true,
        'isFeatured': false,
        'rating': 4.5,
        'ratingCount': 2,
        'createdAt': '2026-11-01T00:00:00Z',
      });
      expect(p.price, 10000);
      expect(p.finalPrice, 8000);
    });
  });

  group('Bolsa', () {
    test('suma cantidades y usa el precio con descuento', () {
      final cart = CartCubit()..loadCart();
      final p = _product('1', 10000).withDiscount(8000);
      cart.addToCart(p);
      cart.addToCart(p);
      final state = cart.state as CartLoaded;
      expect(state.totalQuantity, 2);
      expect(state.total, 16000);
    });

    test('quitar una tienda deja las demás', () {
      final cart = CartCubit()..loadCart();
      cart.addToCart(_product('1', 1000, store: 's1'));
      cart.addToCart(_product('2', 1000, store: 's2'));
      cart.removeStore('s1');
      final state = cart.state as CartLoaded;
      expect(state.items.map((i) => i.product.storeId), ['s2']);
    });
  });
}

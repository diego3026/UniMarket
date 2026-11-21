import 'package:flutter_test/flutter_test.dart';
import 'package:unimarket/domain/entities/market_entities.dart';
import 'package:unimarket/domain/entities/product_entity.dart';
import 'package:unimarket/presentation/models/cart_item.dart';
import 'package:unimarket/presentation/viewmodels/cart/cart_cubit.dart';
import 'package:unimarket/presentation/viewmodels/market/market_cubits.dart';

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

    test('cupón: valida tienda, compra mínima y código', () {
      final promos = PromotionsCubit();
      expect(promos.validateCoupon('NOEXISTE', 's2', 50000).error, isNotNull);
      expect(
        promos.validateCoupon('campus10', 's1', 50000).error,
        contains('otro'),
      );
      expect(
        promos.validateCoupon('CAMPUS10', 's2', 10000).error,
        contains('mínima'),
      );
      final ok = promos.validateCoupon('campus10', 's2', 20000);
      expect(ok.error, isNull);
      expect(ok.discount, 2000);
    });

    test('pausar una promoción la saca de las activas', () {
      final promos = PromotionsCubit();
      expect(promos.bestFor('s2', '6', 18000), isNotNull);
      promos.toggle('pr2', false);
      expect(promos.bestFor('s2', '6', 18000), isNull);
    });
  });

  group('Pedidos', () {
    test('un pedido para recoger pasa por "listo" y termina entregado', () {
      final orders = MarketOrdersCubit();
      final o = orders.place(
        storeId: 's2',
        storeName: 'MaracuMango',
        customerName: 'Ashly Peralta',
        items: [CartItem(product: _product('3', 24000), quantity: 2)],
        mode: FulfillmentMode.pickup,
        placeId: 'plaza',
        notes: '',
        deliveryFee: 0,
        coupon: null,
        couponDiscount: 0,
        paymentLabel: 'Nequi',
      );
      expect(o.total, 48000);
      expect(o.status, OrderStatus.pending);
      orders.advance(o.id);
      orders.advance(o.id);
      expect(orders.byId(o.id)!.status, OrderStatus.ready);
      orders.advance(o.id);
      expect(orders.byId(o.id)!.status, OrderStatus.delivered);
      expect(orders.byId(o.id)!.next, isNull);
    });

    test('un domicilio pasa por "en camino"', () {
      final orders = MarketOrdersCubit();
      final o = orders.byId('1045')!; // domicilio pendiente de ejemplo
      orders.advance(o.id);
      orders.advance(o.id);
      expect(orders.byId(o.id)!.status, OrderStatus.onTheWay);
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

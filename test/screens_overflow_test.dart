// Recorre las pantallas de cada rol en un celular angosto con letra grande
// y falla si alguna se desborda ("RIGHT/BOTTOM OVERFLOWED BY ...").
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unimarket/core/injection_container.dart' as di;
import 'package:unimarket/core/theme/app_theme.dart';
import 'package:unimarket/main.dart';

const _consumer = [
  '/home', '/promos', '/orders', '/favorites', '/search', '/notifications',
  '/store/s2', '/store/s5', '/product/6', '/cart',
  '/order/1045', '/order/1044', '/order/1038', '/order/1019', '/order/1038/review',
  '/profile', '/profile/edit', '/addresses', '/payment-methods',
  '/settings', '/settings/app', '/settings/orders', '/settings/notifications', '/settings/privacy',
  '/become-seller', '/help',
];
const _seller = [
  '/seller', '/seller/menu', '/seller/promos', '/seller/stats', '/seller/profile',
  '/seller/products/new', '/seller/schedule', '/seller/settings', '/seller/promo-form',
  '/seller/bank', '/seller/documents', '/seller/management',
];
const _admin = ['/admin', '/admin/users', '/admin/businesses', '/admin/reports', '/admin/products'];

Future<void> _visitAll(WidgetTester tester, String role, List<String> routes) async {
  tester.view.physicalSize = const Size(360 * 3, 760 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  SharedPreferences.setMockInitialValues({
    'has_seen_onboarding': true,
    'auth_email': 'demo',
    'auth_role': role,
  });
  await di.sl.reset();
  AppTheme.useGoogleFonts = false;
  final prefs = await bootstrap();

  final overflows = <String>[];
  final previous = FlutterError.onError;
  var current = '';
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString();
    if (msg.contains('overflowed')) {
      final where = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(details.toString())?.group(0) ?? '?';
      overflows.add('$current → $where → ${msg.split('\n').first}');
    } else {
      previous?.call(details);
    }
  };

  await tester.pumpWidget(UniMarketApp(appPreferences: prefs));
  await tester.pump(const Duration(seconds: 1));
  for (final r in routes) {
    current = r;
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(r);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
  }
  // Agota temporizadores pendientes antes de terminar.
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
  FlutterError.onError = previous;
  expect(overflows, isEmpty, reason: overflows.join('\n'));
}

void main() {
  testWidgets('cliente: sin desbordes', (t) => _visitAll(t, 'consumer', _consumer));
  testWidgets('emprendedor: sin desbordes', (t) => _visitAll(t, 'entrepreneur', _seller));
  testWidgets('admin: sin desbordes', (t) => _visitAll(t, 'admin', _admin));
}

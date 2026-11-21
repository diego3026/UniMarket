// El botón "atrás" del sistema debe llevar a la pantalla anterior
// (pestaña previa o la pantalla de debajo) en lugar de cerrar la app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:unimarket/core/injection_container.dart' as di;
import 'package:unimarket/core/theme/app_theme.dart';
import 'package:unimarket/main.dart';
import 'package:unimarket/presentation/widgets/ui/uni_map.dart';

import 'helpers/fake_session.dart';

Future<GoRouter> _start(WidgetTester tester, String role) async {
  fakeSession(role);
  await di.sl.reset();
  AppTheme.useGoogleFonts = false;
  UniMap.usePlaceholder = true;
  final prefs = await bootstrap();
  await tester.pumpWidget(UniMarketApp(appPreferences: prefs));
  await tester.pump(const Duration(seconds: 1));
  return GoRouter.of(tester.element(find.byType(Scaffold).first));
}

String _loc(GoRouter r) => r.routerDelegate.currentConfiguration.uri.path;

Future<bool> _back(WidgetTester tester) async {
  final handled = await tester.binding.handlePopRoute();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
  return handled;
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  testWidgets('cliente: atrás vuelve a la pestaña y pantalla anteriores', (
    tester,
  ) async {
    final r = await _start(tester, 'consumer');
    expect(_loc(r), '/home');

    r.go('/promos');
    await tester.pump(const Duration(milliseconds: 600));
    r.go('/orders');
    await tester.pump(const Duration(milliseconds: 600));
    r.push('/product/6');
    await tester.pump(const Duration(milliseconds: 600));

    expect(await _back(tester), isTrue);
    expect(_loc(r), '/orders');
    expect(await _back(tester), isTrue);
    expect(_loc(r), '/promos');
    expect(await _back(tester), isTrue);
    expect(_loc(r), '/home');

    // En Inicio sin historial: primero avisa, no sale.
    expect(await _back(tester), isTrue);
    expect(find.text('Presiona atrás otra vez para salir'), findsOneWidget);
    expect(_loc(r), '/home');
    await _finish(tester);
  });

  testWidgets('emprendedor: atrás desde Promos vuelve a Tienda', (
    tester,
  ) async {
    final r = await _start(tester, 'entrepreneur');
    expect(_loc(r), '/seller');
    r.go('/seller/promos');
    await tester.pump(const Duration(milliseconds: 600));
    r.push('/seller/promo-form');
    await tester.pump(const Duration(milliseconds: 600));

    expect(await _back(tester), isTrue);
    expect(_loc(r), '/seller/promos');
    expect(await _back(tester), isTrue);
    expect(_loc(r), '/seller');
    await _finish(tester);
  });
}

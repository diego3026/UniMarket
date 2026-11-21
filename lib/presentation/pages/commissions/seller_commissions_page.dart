import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_routes.dart';
import 'commission_statement.dart';

/// Emprendedor: comisión de UniMarket por mes (GET /seller/commissions).
class SellerCommissionsPage extends StatefulWidget {
  const SellerCommissionsPage({super.key});

  @override
  State<SellerCommissionsPage> createState() => _SellerCommissionsPageState();
}

class _SellerCommissionsPageState extends State<SellerCommissionsPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _data = null;
      _error = null;
    });
    try {
      final r = await sl<ApiClient>().get(
        '/seller/commissions',
        query: {'month': monthKey(_month)},
      );
      if (mounted) setState(() => _data = Map<String, dynamic>.from(r as Map));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comisiones')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            MonthSwitcher(
              month: _month,
              onChanged: (m) {
                setState(() => _month = m);
                _load();
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              )
            else if (_data == null)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              CommissionStatementView(data: _data!),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.push(AppRoutes.terms),
              child: const Text(
                'Cómo se calcula (Términos y condiciones, sección 5)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

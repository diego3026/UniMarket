// Confirmar el correo con el código de 6 dígitos que llega tras registrarse.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/notification_helper.dart';
import '../../viewmodels/auth/auth_cubit.dart';

class EmailConfirmationPage extends StatefulWidget {
  const EmailConfirmationPage({super.key});

  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _continue() {
    final user = context.read<AuthCubit>().currentUser;
    if (user != null) context.go(homeForRole(user.role));
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) {
      setState(() => _error = 'Escribe los 6 dígitos');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await context.read<AuthCubit>().verifyEmail(_code.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) {
      NotificationHelper.showSuccess(context: context, message: '¡Correo confirmado!');
      _continue();
    }
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    final error = await context.read<AuthCubit>().resendVerification();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      NotificationHelper.showSuccess(context: context, message: 'Te enviamos un código nuevo');
    } else {
      NotificationHelper.showError(context: context, message: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthCubit>().currentUser?.email ?? '';
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.pagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(color: AppColors.lightPanel, shape: BoxShape.circle),
                    child: const Icon(Icons.mark_email_unread_rounded, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text('Confirma tu correo', style: t.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Te enviamos un código de 6 dígitos a\n$email',
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _code,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: t.headlineMedium?.copyWith(letterSpacing: 10, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(counterText: '', hintText: '••••••', errorText: _error),
                    onSubmitted: (_) => _verify(),
                    onChanged: (v) {
                      if (v.length == 6) _verify();
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _verify,
                      child: _busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                          : const Text('Confirmar'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _busy ? null : _resend, child: const Text('Reenviar código')),
                  TextButton(
                    onPressed: _continue,
                    style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                    child: const Text('Hacerlo después'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

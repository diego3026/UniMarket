import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../viewmodels/password_recovery/password_recovery_cubit.dart';
import '../../viewmodels/password_recovery/password_recovery_state.dart';

/// Recuperar contraseña en 3 pasos: correo → código → nueva contraseña.
/// (Figma: "Restablecer contraseña" y "Restablecer contraseña 2").
class PasswordRecoveryPage extends StatelessWidget {
  const PasswordRecoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PasswordRecoveryCubit(),
      child: const _RecoveryView(),
    );
  }
}

enum _Step { email, code, password, done }

class _RecoveryView extends StatefulWidget {
  const _RecoveryView();

  @override
  State<_RecoveryView> createState() => _RecoveryViewState();
}

class _RecoveryViewState extends State<_RecoveryView> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  _Step _step = _Step.email;
  String? _error;

  @override
  void dispose() {
    for (final c in [_email, _code, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocConsumer<PasswordRecoveryCubit, PasswordRecoveryState>(
      listener: (context, state) {
        setState(() {
          _error = state is PasswordRecoveryFailure ? state.message : null;
          if (state is PasswordRecoveryCodeSent) _step = _Step.code;
          // Si el servidor rechaza el código, se vuelve a pedir.
          if (state is PasswordRecoveryFailure &&
              _step == _Step.password &&
              state.message.toLowerCase().contains('código')) {
            _step = _Step.code;
            _code.clear();
          }
          if (state is PasswordRecoveryCodeVerified) _step = _Step.password;
          if (state is PasswordRecoverySuccess) _step = _Step.done;
        });
      },
      builder: (context, state) {
        final loading = state is PasswordRecoveryLoading;
        final cubit = context.read<PasswordRecoveryCubit>();
        final (title, subtitle) = switch (_step) {
          _Step.email => (
            '¿Olvidaste tu contraseña?',
            'Escribe el correo de tu cuenta y te enviaremos un código.',
          ),
          _Step.code => (
            'Revisa tu correo',
            'Enviamos un código de 6 dígitos a ${_email.text.trim()}.',
          ),
          _Step.password => (
            'Crea una nueva contraseña',
            'Mínimo 8 caracteres, con letras y números.',
          ),
          _Step.done => (
            '¡Listo!',
            'Tu contraseña se actualizó. Ya puedes iniciar sesión.',
          ),
        };

        Widget field(
          TextEditingController c,
          String label,
          IconData icon, {
          bool obscure = false,
          TextInputType? type,
        }) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextField(
            controller: c,
            obscureText: obscure,
            keyboardType: type,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
            ),
          ),
        );

        return Scaffold(
          appBar: AppBar(),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              8,
              AppTheme.pagePadding,
              24,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.lightPanel,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _step == _Step.done
                        ? Icons.verified_rounded
                        : Icons.lock_reset_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(title, style: t.headlineMedium),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              if (_step == _Step.email)
                field(
                  _email,
                  'Correo institucional',
                  Icons.alternate_email_rounded,
                  type: TextInputType.emailAddress,
                ),
              if (_step == _Step.code)
                field(
                  _code,
                  'Código de verificación',
                  Icons.pin_outlined,
                  type: TextInputType.number,
                ),
              if (_step == _Step.password) ...[
                field(
                  _pass,
                  'Nueva contraseña',
                  Icons.lock_outline_rounded,
                  obscure: true,
                ),
                field(
                  _pass2,
                  'Confirma la contraseña',
                  Icons.lock_outline_rounded,
                  obscure: true,
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              FilledButton(
                onPressed: loading
                    ? null
                    : () {
                        switch (_step) {
                          case _Step.email:
                            cubit.recoverPassword(_email.text.trim());
                          case _Step.code:
                            cubit.verifyCode(_code.text.trim());
                          case _Step.password:
                            cubit.resetPassword(_pass.text, _pass2.text);
                          case _Step.done:
                            context.go(AppRoutes.login);
                        }
                      },
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(switch (_step) {
                        _Step.email => 'Enviar código',
                        _Step.code => 'Verificar código',
                        _Step.password => 'Guardar contraseña',
                        _Step.done => 'Ir a iniciar sesión',
                      }),
              ),
              if (_step == _Step.code)
                TextButton(
                  onPressed: loading
                      ? null
                      : () => cubit.recoverPassword(_email.text.trim()),
                  child: const Text('Reenviar código'),
                ),
            ],
          ),
        );
      },
    );
  }
}

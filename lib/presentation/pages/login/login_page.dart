import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../domain/entities/user_role.dart';
import '../../viewmodels/auth/auth_cubit.dart';

/// Inicio de sesión (Figma: "Login").
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthCubit>();
    await auth.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!auth.isAuthenticated()) {
        _error =
            'Correo o contraseña incorrectos. Revisa los datos e inténtalo de nuevo.';
      }
    });
    // Si inicia sesión, el router lo lleva a la pantalla de su rol.
  }

  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffix,
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelStyle: const TextStyle(color: AppColors.accent),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
        errorStyle: const TextStyle(color: AppColors.accent),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.purpleGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          'lib/assets/images/LOGO_UNIMARKET.png',
                          width: 130,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        '¡Bienvenido!',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Inicia sesión con tu correo institucional',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: _dec(
                          'Correo institucional',
                          Icons.alternate_email_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Escribe tu correo'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        style: const TextStyle(color: Colors.white),
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: _dec(
                          'Contraseña',
                          Icons.lock_outline_rounded,
                          suffix: IconButton(
                            tooltip: _obscure
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Escribe tu contraseña'
                            : null,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () =>
                              context.push(AppRoutes.recoverPassword),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      const SizedBox(height: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                        ),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('Iniciar sesión'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes cuenta?',
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () => context.push(AppRoutes.register),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.accent,
                            ),
                            child: const Text('Regístrate'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _DemoAccess(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Accesos rápidos para probar cada rol mientras no hay backend.
class _DemoAccess extends StatelessWidget {
  const _DemoAccess();

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, IconData icon, UserRole role) =>
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            side: const BorderSide(color: Colors.white38),
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: const StadiumBorder(),
          ),
          onPressed: () => context.read<AuthCubit>().loginAs(role),
          icon: Icon(icon, size: 18),
          label: Text(label),
        );
    return Column(
      children: [
        const Text(
          'Modo demo · entrar como',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            chip('Cliente', Icons.person_rounded, UserRole.consumer),
            chip(
              'Emprendedor',
              Icons.storefront_rounded,
              UserRole.entrepreneur,
            ),
            chip('Admin', Icons.admin_panel_settings_rounded, UserRole.admin),
          ],
        ),
      ],
    );
  }
}

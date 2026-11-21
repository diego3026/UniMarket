import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../viewmodels/onboarding/onboarding_cubit.dart';

/// Bienvenida (Figma: "Slash").
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    (
      'La comodidad que buscas',
      'Descubre el mercado UniMarket, hecho por y para estudiantes de la Universidad del Magdalena.',
    ),
    (
      'Apoya a tus compañeros',
      'Compra comida, accesorios y servicios de emprendimientos del campus.',
    ),
    (
      'Recibe donde estés',
      'Pide desde tu bloque, sigue tu pedido en tiempo real y paga fácil.',
    ),
  ];

  Future<void> _finish() async {
    await context.read<OnboardingCubit>().markOnboardingAsSeen();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/Bienvenida.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.35, 0.75],
                  colors: [Colors.transparent, AppColors.primaryDark],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _finish,
                    child: const Text(
                      'Omitir',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 170,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Text(
                            _slides[i].$1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _slides[i].$2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.accent : Colors.white38,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    onPressed: last
                        ? _finish
                        : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          ),
                    child: Text(last ? 'Empezar' : 'Siguiente'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/ui/app_widgets.dart';

/// Centro de ayuda con preguntas frecuentes.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _faqs = [
    (
      '¿Quién puede comprar en UniMarket?',
      'Cualquier estudiante, docente o administrativo de la Universidad del Magdalena con correo institucional.',
    ),
    (
      '¿Dónde recibo mi pedido?',
      'Dentro del campus: eliges el bloque o punto de encuentro al pagar y el emprendedor te lo entrega allí.',
    ),
    (
      '¿Cómo me convierto en emprendedor/a?',
      'Desde Perfil → "Quiero ser emprendedor/a". Completas los datos de tu negocio y el equipo de UniMarket lo verifica.',
    ),
    (
      '¿Qué hago si mi pedido no llega?',
      'Abre el pedido en "Mis pedidos" y usa "Seguir pedido". Si hay un problema, escríbenos y lo revisamos con el emprendedor.',
    ),
    (
      '¿Cómo cancelo un pedido?',
      'Puedes cancelarlo mientras esté "Pendiente". Una vez el emprendedor lo acepta ya no se puede cancelar desde la app.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: [
          Text('Preguntas frecuentes', style: t.titleLarge),
          const SizedBox(height: 12),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: _faqs
                  .map(
                    (f) => ExpansionTile(
                      shape: const Border(),
                      title: Text(f.$1, style: t.titleSmall),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [Text(f.$2, style: t.bodyMedium)],
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text('¿Necesitas más ayuda?', style: t.titleLarge),
          const SizedBox(height: 12),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                MenuTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Escríbenos',
                  subtitle: 'soporte@unimarket.co',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pronto podrás escribirnos desde la app.'),
                    ),
                  ),
                ),
                MenuTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'WhatsApp',
                  subtitle: 'Lunes a viernes, 8:00 a. m. – 5:00 p. m.',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'El canal de WhatsApp estará disponible pronto.',
                      ),
                    ),
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

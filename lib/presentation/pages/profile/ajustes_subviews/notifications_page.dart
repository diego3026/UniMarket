import 'package:flutter/material.dart';

import 'package:unimarket/constants/app_colors.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool notificacionesEmail = false;
  bool notificacionesPromos = true;
  bool notificacionesPedidos = true;
  bool recordatoriosCarrito = false;
  bool resumenSemanal = true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212)
          : AppColors.background,
      appBar: AppBar(
        leading: BackButton(color: isDarkMode ? Colors.white : Colors.white),
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Color.lerp(
                  Theme.of(context).colorScheme.primary,
                  Colors.white,
                  0.25,
                )!,
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(isDarkMode),
          const SizedBox(height: 16),
          _buildSectionTitle(
            'Canales principales',
            'Elige dónde quieres recibir las alertas más importantes.',
            isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildToggleCard(
            icon: Icons.email_outlined,
            title: 'Notificaciones por email',
            subtitle: 'Recibe alertas en tu correo',
            value: notificacionesEmail,
            onChanged: (val) => setState(() => notificacionesEmail = val),
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildToggleCard(
            icon: Icons.shopping_bag_outlined,
            title: 'Actualizaciones de pedidos',
            subtitle: 'Cambios de estado, despacho y entrega',
            value: notificacionesPedidos,
            onChanged: (val) => setState(() => notificacionesPedidos = val),
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(
            'Promociones y recordatorios',
            'Mantén el control de ofertas, carritos y novedades.',
            isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildToggleCard(
            icon: Icons.local_offer_outlined,
            title: 'Promociones y ofertas',
            subtitle: 'Descuentos, campañas y lanzamientos',
            value: notificacionesPromos,
            onChanged: (val) => setState(() => notificacionesPromos = val),
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildToggleCard(
            icon: Icons.shopping_cart_outlined,
            title: 'Recordatorios de carrito',
            subtitle: 'Te avisamos si dejas productos pendientes',
            value: recordatoriosCarrito,
            onChanged: (val) => setState(() => recordatoriosCarrito = val),
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildToggleCard(
            icon: Icons.event_note_outlined,
            title: 'Resumen semanal',
            subtitle: 'Un resumen con actividad y recomendaciones',
            value: resumenSemanal,
            onChanged: (val) => setState(() => resumenSemanal = val),
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 20),
          _buildInfoCard(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Color.lerp(
              Theme.of(context).colorScheme.primary,
              Colors.white,
              0.25,
            )!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administra tus alertas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Ajusta qué avisos quieres recibir para mantener una experiencia más clara y útil.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? AppColors.textMuted : AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? AppColors.textSecondary : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          secondary: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeThumbColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E1E1E)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: isDarkMode ? 0.12 : 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Puedes volver a esta pantalla cuando quieras para adaptar las notificaciones a tu rutina de compra.',
              style: TextStyle(
                color: isDarkMode ? AppColors.border : AppColors.textSecondary,
                height: 1.35,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

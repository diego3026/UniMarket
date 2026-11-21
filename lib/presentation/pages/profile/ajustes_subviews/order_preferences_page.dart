import 'package:flutter/material.dart';

import 'package:unimarket/constants/app_colors.dart';
import 'package:unimarket/core/injection_container.dart';
import 'package:unimarket/presentation/viewmodels/profile/order_preferences_controller.dart';

class OrderPreferencesPage extends StatefulWidget {
  const OrderPreferencesPage({super.key});

  @override
  State<OrderPreferencesPage> createState() => _OrderPreferencesPageState();
}

class _OrderPreferencesPageState extends State<OrderPreferencesPage> {
  late final OrderPreferencesController prefs;

  @override
  void initState() {
    super.initState();
    prefs = sl<OrderPreferencesController>();
    prefs.addListener(_onPrefsChanged);
  }

  void _onPrefsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    prefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

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
          'Preferencias de Pedidos',
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
          const SizedBox(height: 16),
          _buildSectionTitle(
            'Historial',
            'Controla qué pedidos se muestran y cómo se organizan.',
            isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildToggleCard(
            icon: Icons.history_outlined,
            title: 'Mostrar pedidos antiguos',
            subtitle: 'Ver el historial de pedidos pasados',
            value: prefs.showOldOrders,
            onChanged: (val) async {
              await prefs.setShowOldOrders(val);
              if (!context.mounted) return;
              _showFeedback(
                context,
                val
                    ? 'El historial de pedidos estará visible.'
                    : 'Se ocultaron los pedidos antiguos en la vista.',
              );
            },
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildToggleCard(
            icon: Icons.storefront_outlined,
            title: 'Agrupar por emprendimiento',
            subtitle: 'Organizar pedidos por vendedor',
            value: prefs.groupByStore,
            onChanged: (val) async {
              await prefs.setGroupByStore(val);
              if (!context.mounted) return;
              _showFeedback(
                context,
                val
                    ? 'Los pedidos se agruparán por emprendimiento.'
                    : 'Los pedidos volverán a mostrarse en una sola lista.',
              );
            },
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(
            'Seguimiento',
            'Recibe información útil mientras un pedido está en camino.',
            isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildToggleCard(
            icon: Icons.schedule_outlined,
            title: 'Notificar tiempo estimado',
            subtitle: 'Recibir estimaciones de entrega',
            value: prefs.notifyEstimatedArrival,
            onChanged: (val) async {
              await prefs.setNotifyEstimatedArrival(val);
              if (!context.mounted) return;
              _showFeedback(
                context,
                val
                    ? 'Se mostrarán avisos de tiempo estimado en seguimiento.'
                    : 'Se ocultarán los avisos de tiempo estimado.',
              );
            },
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 20),
          _buildInfoCard(isDarkMode),
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
              'Estas opciones se guardan en el dispositivo y se aplican en la vista de pedidos y seguimiento.',
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

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

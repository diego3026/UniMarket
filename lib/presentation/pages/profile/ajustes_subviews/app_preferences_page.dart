import 'package:unimarket/constants/app_colors.dart';
import 'package:flutter/material.dart';

import 'package:unimarket/core/injection_container.dart';
import 'package:unimarket/presentation/viewmodels/profile/app_preferences_controller.dart';

class AppPreferencesPage extends StatefulWidget {
  const AppPreferencesPage({super.key});

  @override
  State<AppPreferencesPage> createState() => _AppPreferencesPageState();
}

class _AppPreferencesPageState extends State<AppPreferencesPage> {
  late final AppPreferencesController prefs;

  @override
  void initState() {
    super.initState();
    prefs = sl<AppPreferencesController>();
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
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(
          'Preferencias',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1B1B1B) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : AppColors.textPrimary,
        elevation: 0,
      ),
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text(
              'Reproducción automática',
              style: TextStyle(
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Recarga el catálogo automáticamente al volver a Inicio',
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
              ),
            ),
            value: prefs.autoPlay,
            onChanged: (val) => prefs.toggleAutoPlay(val),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(
            color: isDarkMode ? AppColors.textSecondary : AppColors.border,
          ),
          SwitchListTile(
            title: Text(
              'Mantener historial de búsqueda',
              style: TextStyle(
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Guarda tus búsquedas anteriores',
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
              ),
            ),
            value: prefs.keepSearchHistory,
            onChanged: (val) => prefs.toggleKeepSearchHistory(val),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(
            color: isDarkMode ? AppColors.textSecondary : AppColors.border,
          ),
          SwitchListTile(
            title: Text(
              'Recomendaciones personalizadas',
              style: TextStyle(
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Recibe sugerencias basadas en tus gustos',
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
              ),
            ),
            value: prefs.personalizedRecommendations,
            onChanged: (val) => prefs.togglePersonalizedRecommendations(val),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(
            color: isDarkMode ? AppColors.textSecondary : AppColors.border,
          ),
          ListTile(
            title: Text(
              'Idioma',
              style: TextStyle(
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              prefs.languageLabel,
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  title: Text(
                    'Selecciona un idioma',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ['Español', 'English', 'Português'].map((lang) {
                      final value = switch (lang) {
                        'English' => 'en',
                        'Português' => 'pt',
                        _ => 'es',
                      };
                      final selected = prefs.languageCode == value;
                      return ListTile(
                        leading: Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.textMuted,
                        ),
                        title: Text(
                          lang,
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        onTap: () {
                          prefs.setLanguage(value);
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

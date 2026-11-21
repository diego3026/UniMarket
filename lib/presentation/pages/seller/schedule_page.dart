import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/ui/app_widgets.dart';

/// Horario de atención del emprendimiento (Figma Emprendedor: "Horario").
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _Day {
  final String name;
  bool open;
  TimeOfDay from;
  TimeOfDay to;
  _Day(this.name, {this.open = true})
    : from = const TimeOfDay(hour: 8, minute: 0),
      to = const TimeOfDay(hour: 17, minute: 0);
}

class _SchedulePageState extends State<SchedulePage> {
  final _days = [
    _Day('Lunes'),
    _Day('Martes'),
    _Day('Miércoles'),
    _Day('Jueves'),
    _Day('Viernes'),
    _Day('Sábado', open: false),
    _Day('Domingo', open: false),
  ];

  Future<void> _pick(_Day d, bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? d.from : d.to,
    );
    if (picked != null) setState(() => start ? d.from = picked : d.to = picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.pagePadding,
          0,
          AppTheme.pagePadding,
          24,
        ),
        children: [
          Text('Horario de atención', style: t.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Los clientes solo podrán pedir dentro de este horario.',
            style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ..._days.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(d.name, style: t.titleSmall),
                    ),
                    Expanded(
                      child: d.open
                          ? Wrap(
                              spacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _TimeButton(
                                  time: d.from,
                                  onTap: () => _pick(d, true),
                                ),
                                const Text('–'),
                                _TimeButton(
                                  time: d.to,
                                  onTap: () => _pick(d, false),
                                ),
                              ],
                            )
                          : Text(
                              'Cerrado',
                              style: t.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                    ),
                    Switch(
                      value: d.open,
                      onChanged: (v) => setState(() => d.open = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Horario guardado')));
              context.pop();
            },
            child: const Text('Guardar horario'),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeButton({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: AppColors.sellerLight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 36),
      ),
      onPressed: onTap,
      child: Text(time.format(context)),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../core/legal/terms.dart';

/// Términos y condiciones (mismo texto que la página web).
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Términos y condiciones')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Última actualización: $termsUpdated', style: t.bodySmall),
          for (final s in termsSections) ...[
            const SizedBox(height: 20),
            Text(s.title, style: t.titleMedium),
            const SizedBox(height: 6),
            for (final p in s.paragraphs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(p, style: t.bodyMedium?.copyWith(height: 1.45)),
              ),
            for (final b in s.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7, right: 10),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        b,
                        style: t.bodyMedium?.copyWith(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

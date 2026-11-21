import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../viewmodels/market/market_cubits.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/product_image.dart';

/// Calificar un pedido (Figma: "Mis pedidos parte 3").
class ProductReviewPage extends StatefulWidget {
  final String orderId;
  const ProductReviewPage({super.key, required this.orderId});

  @override
  State<ProductReviewPage> createState() => _ProductReviewPageState();
}

class _ProductReviewPageState extends State<ProductReviewPage> {
  bool _sending = false;
  int _stars = 0;
  final _comment = TextEditingController();
  final Set<String> _tags = {};

  static const _labels = [
    '',
    'Muy malo',
    'Malo',
    'Regular',
    'Bueno',
    '¡Excelente!',
  ];
  static const _positive = [
    'Buen sabor',
    'Llegó a tiempo',
    'Buena presentación',
    'Buen precio',
    'Amable',
    'Bien empacado',
  ];
  static const _negative = [
    'Llegó tarde',
    'Llegó frío',
    'Faltó algo',
    'Mala presentación',
    'Precio alto',
  ];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = context.watch<MarketOrdersCubit>().byId(widget.orderId);
    if (o == null) return Scaffold(appBar: AppBar());
    final tags = _stars >= 4 || _stars == 0 ? _positive : _negative;

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
          Row(
            children: [
              ClipOval(
                child: ProductImage(
                  imageUrl: '',
                  category: o.category,
                  width: 60,
                  height: 60,
                  radius: 0,
                  iconSize: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.storeName, style: t.headlineSmall),
                    Text(
                      o.lines.map((l) => '${l.quantity}× ${l.name}').join(', '),
                      style: t.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            '¿Cómo estuvo tu pedido?',
            style: t.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final on = i < _stars;
              return IconButton(
                iconSize: 44,
                tooltip: '${i + 1} estrellas',
                onPressed: () => setState(() {
                  _stars = i + 1;
                  _tags.clear();
                }),
                icon: AnimatedScale(
                  scale: on ? 1.1 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    on ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: on ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
              );
            }),
          ),
          SizedBox(
            height: 24,
            child: Text(
              _labels[_stars],
              textAlign: TextAlign.center,
              style: t.titleMedium?.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedOpacity(
            opacity: _stars == 0 ? 0.4 : 1,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: _stars == 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stars >= 4 || _stars == 0
                        ? '¿Qué te gustó?'
                        : '¿Qué podemos mejorar?',
                    style: t.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in tags)
                        FilterChip(
                          label: Text(tag),
                          selected: _tags.contains(tag),
                          onSelected: (v) => setState(
                            () => v ? _tags.add(tag) : _tags.remove(tag),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cuéntale a ${o.storeName} (opcional)',
                    style: t.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _comment,
                    maxLines: 4,
                    maxLength: 280,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText:
                          'Tu opinión ayuda a otros estudiantes y al emprendedor',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(
          onPressed: _stars == 0 || _sending
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() => _sending = true);
                  final err = await context.read<MarketOrdersCubit>().rate(
                    o.id,
                    _stars,
                    _comment.text.trim(),
                    _tags.toList(),
                  );
                  if (!context.mounted) return;
                  setState(() => _sending = false);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(err ?? '¡Gracias! Tu calificación ya la puede ver ${o.storeName}.'),
                    ),
                  );
                  if (err == null) context.pop();
                },
          child: const Text('Enviar calificación'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/market_entities.dart';
import '../../../domain/entities/product_entity.dart';
import '../../viewmodels/market/market_cubits.dart';
import '../../viewmodels/product/product_cubit.dart';
import '../../widgets/ui/app_widgets.dart';
import 'seller_mock.dart';

/// Promociones y cupones del emprendedor.
/// Los descuentos cambian el precio que ve el cliente en toda la app;
/// los cupones se usan al finalizar la compra.
class SellerPromotionsPage extends StatefulWidget {
  const SellerPromotionsPage({super.key});

  @override
  State<SellerPromotionsPage> createState() => _SellerPromotionsPageState();
}

class _SellerPromotionsPageState extends State<SellerPromotionsPage> {
  String _tab = 'Activas';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final all = context.watch<PromotionsCubit>().forStore(SellerMock.store.id);
    final items = all
        .where((p) => _tab == 'Activas' ? p.isRunning : !p.isRunning)
        .toList();
    final uses = all.fold<int>(0, (s, p) => s + p.uses);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => context.push(AppRoutes.sellerPromoForm),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva promoción'),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            const PageTitle(
              title: 'Promociones',
              subtitle: 'Descuentos y cupones de tu tienda',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.pagePadding,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.sellerGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.campaign_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${all.where((p) => p.isRunning).length} activas · $uses usos',
                            style: t.titleMedium?.copyWith(color: Colors.white),
                          ),
                          const Text(
                            'Los descuentos aparecen en "Promos" y en el precio de tus productos.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ChoiceChipsRow(
              options: const ['Activas', 'Pausadas o vencidas'],
              selected: _tab,
              onSelected: (v) => setState(() => _tab = v),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              EmptyState(
                icon: Icons.local_offer_outlined,
                title: _tab == 'Activas'
                    ? 'No tienes promociones activas'
                    : 'Nada pausado',
                message:
                    'Crea un descuento o un cupón para atraer más clientes.',
                actionLabel: _tab == 'Activas' ? 'Crear promoción' : null,
                onAction: () => context.push(AppRoutes.sellerPromoForm),
              )
            else
              for (final p in items)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    0,
                    AppTheme.pagePadding,
                    12,
                  ),
                  child: _PromoCard(promo: p),
                ),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final PromotionEntity promo;
  const _PromoCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = promo;
    final catalog = context.watch<ProductCubit>().state;
    final names = catalog is ProductLoaded
        ? catalog.products
              .where((x) => p.productIds.contains(x.id))
              .map((x) => x.name)
              .toList()
        : <String>[];
    final isCoupon = p.kind == PromotionKind.coupon;
    final expired = p.endsAt != null && p.endsAt!.isBefore(DateTime.now());

    return SurfaceCard(
      onTap: () => context.push(AppRoutes.sellerPromoForm, extra: p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isCoupon ? AppColors.info : AppColors.seller)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isCoupon
                      ? Icons.confirmation_number_outlined
                      : Icons.sell_outlined,
                  color: isCoupon ? AppColors.info : AppColors.seller,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: t.titleMedium),
                    Text(
                      isCoupon
                          ? 'Cupón ${p.code}${p.minPurchase > 0 ? ' · mínimo ${formatCop(p.minPurchase)}' : ''}'
                          : (names.isEmpty ? 'Todo el menú' : names.join(', ')),
                      style: t.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                p.valueLabel,
                style: t.titleLarge?.copyWith(color: AppColors.seller),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 16,
                color: expired ? AppColors.danger : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${p.endsAt == null ? 'Sin fecha de fin' : '${expired ? 'Venció' : 'Hasta'} el ${DateFormat("d 'de' MMM", 'es_CO').format(p.endsAt!)}'} · ${p.uses} usos',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    color: expired ? AppColors.danger : null,
                  ),
                ),
              ),
              if (isCoupon)
                IconButton(
                  tooltip: 'Copiar código',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: p.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Código ${p.code} copiado')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                ),
              Switch(
                value: p.active,
                onChanged: (v) =>
                    context.read<PromotionsCubit>().toggle(p.id, v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Crear o editar una promoción.
class PromotionFormPage extends StatefulWidget {
  final PromotionEntity? initial;
  const PromotionFormPage({super.key, this.initial});

  @override
  State<PromotionFormPage> createState() => _PromotionFormPageState();
}

class _PromotionFormPageState extends State<PromotionFormPage> {
  final _form = GlobalKey<FormState>();
  late PromotionKind _kind =
      widget.initial?.kind ?? PromotionKind.productDiscount;
  late DiscountType _type = widget.initial?.type ?? DiscountType.percent;
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _value = TextEditingController(
    text: widget.initial == null
        ? ''
        : widget.initial!.value.round().toString(),
  );
  late final _code = TextEditingController(text: widget.initial?.code ?? '');
  late final _min = TextEditingController(
    text: widget.initial == null || widget.initial!.minPurchase == 0
        ? ''
        : widget.initial!.minPurchase.round().toString(),
  );
  late final Set<String> _products = {...?widget.initial?.productIds};
  late DateTime? _endsAt = widget.initial?.endsAt;

  @override
  void dispose() {
    for (final c in [_title, _value, _code, _min]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final cubit = context.read<PromotionsCubit>();
    final base =
        widget.initial ??
        PromotionEntity(
          id: cubit.newId(),
          storeId: SellerMock.store.id,
          title: '',
          kind: _kind,
          type: _type,
          value: 0,
        );
    cubit.save(
      base.copyWith(
        title: _title.text.trim(),
        kind: _kind,
        type: _type,
        value: double.parse(_value.text),
        productIds: _kind == PromotionKind.productDiscount
            ? _products.toList()
            : const [],
        code: _kind == PromotionKind.coupon
            ? _code.text.trim().toUpperCase()
            : '',
        minPurchase: double.tryParse(_min.text) ?? 0,
        endsAt: _endsAt,
        clearEndsAt: _endsAt == null,
        active: true,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Promoción "${_title.text.trim()}" guardada. Tus clientes ya la ven.',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final catalog = context.watch<ProductCubit>().state;
    final products = catalog is ProductLoaded
        ? catalog.products
              .where((p) => p.storeId == SellerMock.store.id)
              .toList()
        : <ProductEntity>[];
    final value = double.tryParse(_value.text) ?? 0;
    final sample = products
        .where((p) => _products.isEmpty || _products.contains(p.id))
        .toList();
    final preview = PromotionEntity(
      id: 'x',
      storeId: '',
      title: '',
      kind: _kind,
      type: _type,
      value: value,
    );

    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(s, style: t.titleSmall),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? 'Nueva promoción' : 'Editar promoción',
        ),
        actions: [
          if (widget.initial != null)
            IconButton(
              tooltip: 'Eliminar promoción',
              onPressed: () {
                context.read<PromotionsCubit>().delete(widget.initial!.id);
                context.pop();
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            0,
            AppTheme.pagePadding,
            32,
          ),
          children: [
            SegmentedButton<PromotionKind>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.seller,
                selectedForegroundColor: Colors.white,
              ),
              segments: const [
                ButtonSegment(
                  value: PromotionKind.productDiscount,
                  icon: Icon(Icons.sell_outlined),
                  label: Text('Descuento'),
                ),
                ButtonSegment(
                  value: PromotionKind.coupon,
                  icon: Icon(Icons.confirmation_number_outlined),
                  label: Text('Cupón'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (v) => setState(() => _kind = v.first),
            ),
            const SizedBox(height: 8),
            Text(
              _kind == PromotionKind.productDiscount
                  ? 'Baja el precio de los productos que elijas. Se ve en el menú y en "Promos".'
                  : 'El cliente escribe el código al finalizar la compra para obtener el descuento.',
              style: t.bodySmall,
            ),
            label('Nombre de la promoción'),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ej. Semana tropical',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Dale un nombre' : null,
            ),
            label('Descuento'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _value,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: _type == DiscountType.percent ? '15' : '2000',
                      prefixText: _type == DiscountType.fixed ? '\$ ' : null,
                      suffixText: _type == DiscountType.percent ? '%' : null,
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Escribe un valor';
                      if (_type == DiscountType.percent && n > 90) {
                        return 'Máximo 90 %';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<DiscountType>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: DiscountType.percent,
                      label: Text('%'),
                    ),
                    ButtonSegment(value: DiscountType.fixed, label: Text('\$')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (v) => setState(() => _type = v.first),
                ),
              ],
            ),
            if (_kind == PromotionKind.productDiscount) ...[
              label('¿A qué productos aplica?'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Todo el menú'),
                    selected: _products.isEmpty,
                    onSelected: (_) => setState(_products.clear),
                  ),
                  for (final p in products)
                    FilterChip(
                      label: Text(p.name),
                      selected: _products.contains(p.id),
                      onSelected: (v) => setState(
                        () => v ? _products.add(p.id) : _products.remove(p.id),
                      ),
                    ),
                ],
              ),
            ] else ...[
              label('Código del cupón'),
              TextFormField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: const InputDecoration(hintText: 'Ej. CAMPUS10'),
                validator: (v) => (v ?? '').trim().length < 4
                    ? 'Mínimo 4 letras o números'
                    : null,
              ),
              label('Compra mínima (opcional)'),
              TextFormField(
                controller: _min,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '15000',
                  prefixText: '\$ ',
                ),
              ),
            ],
            label('Vigencia'),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Tiene fecha de fin'),
                    value: _endsAt != null,
                    onChanged: (v) => setState(
                      () => _endsAt = v
                          ? DateTime.now().add(const Duration(days: 7))
                          : null,
                    ),
                  ),
                  if (_endsAt != null)
                    ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: Text(
                        DateFormat(
                          "EEEE d 'de' MMMM",
                          'es_CO',
                        ).format(_endsAt!),
                      ),
                      trailing: const Text('Cambiar'),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _endsAt!,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (d != null) setState(() => _endsAt = d);
                      },
                    ),
                ],
              ),
            ),
            if (_kind == PromotionKind.productDiscount &&
                value > 0 &&
                sample.isNotEmpty) ...[
              label('Así lo verán tus clientes'),
              SurfaceCard(
                child: Column(
                  children: [
                    for (final p in sample.take(3))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(p.name)),
                            Text(
                              formatCop(p.price),
                              style: t.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatCop(preview.apply(p.price)),
                              style: t.titleSmall?.copyWith(
                                color: AppColors.seller,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Guardar promoción'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/media_uploader.dart';
import '../../../core/theme/app_theme.dart';
import '../../viewmodels/catalog/catalog_cubit.dart';
import '../../viewmodels/market/seller_products_cubit.dart';
import '../../viewmodels/product/product_cubit.dart';

/// Crear o editar un producto (Figma Emprendedor: "Crear producto").
class CreateProductPage extends StatefulWidget {
  final SellerProduct? initial;
  const CreateProductPage({super.key, this.initial});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.product.name);
  late final _price = TextEditingController(text: widget.initial?.product.price.toInt().toString());
  late final _stock = TextEditingController(text: (widget.initial?.product.stock ?? 20).toString());
  late final _description = TextEditingController(text: widget.initial?.product.description);
  late String? _category = widget.initial?.product.category;
  late String _imageUrl = widget.initial?.product.imageUrl ?? '';
  late bool _available = widget.initial?.isAvailable ?? true;
  PlatformFile? _photo;
  bool _saving = false;

  bool get _editing => widget.initial != null;

  @override
  void dispose() {
    for (final c in [_name, _price, _stock, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final f = await MediaUploader.pick();
    if (f != null) setState(() => _photo = f);
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final products = context.read<SellerProductsCubit>();
    final catalog = context.read<ProductCubit>();
    try {
      if (_photo != null) {
        _imageUrl = await MediaUploader(sl<ApiClient>()).upload(_photo!, 'product');
      }
      final err = await products.save(
        id: widget.initial?.product.id,
        data: {
          'name': _name.text.trim(),
          'description': _description.text.trim(),
          'category': _category,
          'price': int.parse(_price.text.replaceAll(RegExp(r'\D'), '')),
          'stock': int.tryParse(_stock.text) ?? 0,
          'imageUrl': _imageUrl,
          'isAvailable': _available,
        },
      );
      if (err != null) {
        _snack(err);
        return;
      }
      catalog.loadProducts();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _editing ? 'Cambios guardados' : '"${_name.text.trim()}" quedó publicado en tu menú',
          ),
        ),
      );
      if (mounted) context.pop();
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('"${widget.initial!.product.name}" dejará de aparecer en tu menú.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar producto'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    final catalog = context.read<ProductCubit>();
    final err = await context.read<SellerProductsCubit>().delete(widget.initial!.product.id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) return _snack(err);
    catalog.loadProducts();
    _snack('Producto eliminado');
    context.pop();
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 18),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );

  @override
  Widget build(BuildContext context) {
    context.watch<CatalogCubit>();
    final t = Theme.of(context).textTheme;
    final cats = {...Catalog.categories, if (_category != null) _category!}.toList();
    final hasImage = _photo != null || _imageUrl.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Eliminar producto',
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 0, AppTheme.pagePadding, 32),
          children: [
            Text(_editing ? 'Editar producto' : 'Crear nuevo producto', style: t.headlineMedium),
            const SizedBox(height: 4),
            Text('Así lo verán los clientes en tu menú.', style: t.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            _label('Foto del producto'),
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: _saving ? null : _pickPhoto,
              child: Container(
                height: 170,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: hasImage ? AppColors.sellerLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: hasImage ? AppColors.seller : AppColors.border, width: hasImage ? 1.6 : 1),
                ),
                child: _photo == null && _imageUrl.isNotEmpty
                    ? Image.network(_imageUrl, fit: BoxFit.cover, width: double.infinity)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _photo != null ? Icons.check_circle_rounded : Icons.add_a_photo_outlined,
                            size: 36,
                            color: AppColors.seller,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _photo != null ? '${_photo!.name} · toca para cambiar' : 'Toca para subir una foto (JPG o PNG, máx. 5 MB)',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
            ),
            _label('Nombre del producto'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Ej. Picada tropical'),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Escribe el nombre del producto' : null,
            ),
            _label('Precio'),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '15000', prefixText: '\$ '),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n <= 0 ? 'Escribe un precio válido en pesos' : null;
              },
            ),
            _label('Unidades disponibles'),
            TextFormField(
              controller: _stock,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '20'),
              validator: (v) => int.tryParse(v ?? '') == null ? 'Escribe cuántas unidades tienes' : null,
            ),
            _label('Categoría'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              hint: const Text('Elige una categoría'),
              items: [for (final c in cats) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Elige una categoría' : null,
            ),
            _label('Descripción'),
            TextFormField(
              controller: _description,
              maxLines: 4,
              maxLength: 240,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: '¿Qué lo hace especial?'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Disponible para la venta'),
              value: _available,
              onChanged: (v) => setState(() => _available = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Guardando…' : (_editing ? 'Guardar cambios' : 'Publicar producto')),
            ),
          ],
        ),
      ),
    );
  }
}

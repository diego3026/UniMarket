import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/mock/catalog_mock_data.dart';

/// Formulario para publicar un producto (Figma Emprendedor: "Crear producto").
class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  String? _category;
  bool _hasPhoto = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${_name.text.trim()}" quedó publicado en tu menú'),
      ),
    );
    context.pop();
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 18),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            0,
            AppTheme.pagePadding,
            32,
          ),
          children: [
            Text('Crear nuevo producto', style: t.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Así lo verán los clientes en tu menú.',
              style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            _label('Foto del producto'),
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: () => setState(() => _hasPhoto = !_hasPhoto),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: _hasPhoto ? AppColors.sellerLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: _hasPhoto ? AppColors.seller : AppColors.border,
                    width: _hasPhoto ? 1.6 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _hasPhoto
                          ? Icons.check_circle_rounded
                          : Icons.add_a_photo_outlined,
                      size: 36,
                      color: AppColors.seller,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasPhoto
                          ? 'Foto agregada · toca para cambiar'
                          : 'Toca para subir una foto',
                    ),
                  ],
                ),
              ),
            ),
            _label('Nombre del producto'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ej. Picada tropical',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Escribe el nombre del producto'
                  : null,
            ),
            _label('Precio'),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '15000',
                prefixText: '\$ ',
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').replaceAll('.', ''));
                if (n == null || n <= 0) {
                  return 'Escribe un precio válido en pesos';
                }
                return null;
              },
            ),
            _label('Categoría'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              hint: const Text('Elige una categoría'),
              items: CatalogMockData.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Elige una categoría' : null,
            ),
            _label('Descripción'),
            TextFormField(
              controller: _description,
              maxLines: 4,
              maxLength: 240,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: '¿Qué lo hace especial?',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: const Text('Publicar producto'),
            ),
          ],
        ),
      ),
    );
  }
}

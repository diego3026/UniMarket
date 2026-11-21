import 'package:unimarket/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:unimarket/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/profile/entrepreneur_viewmodel.dart';

class EntrepreneurPage extends StatefulWidget {
  const EntrepreneurPage({super.key});

  @override
  State<EntrepreneurPage> createState() => _EntrepreneurPageState();
}

class _EntrepreneurPageState extends State<EntrepreneurPage> {
  late final EntrepreneurViewModel vm;
  late final TextEditingController _businessCtrl;
  late final TextEditingController _ownerCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    vm = EntrepreneurViewModel();
    _businessCtrl = TextEditingController(text: vm.businessName);
    _ownerCtrl = TextEditingController(text: vm.ownerName);
    _phoneCtrl = TextEditingController(text: vm.phone);
    _addressCtrl = TextEditingController(text: vm.address);
    _descCtrl = TextEditingController(text: vm.description);
    vm.addListener(_onVm);
  }

  void _onVm() => setState(() {});

  @override
  void dispose() {
    vm.removeListener(_onVm);
    _businessCtrl.dispose();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(
          'Quiero ser emprendedor/a',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: _businessCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre del negocio',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: vm.setBusinessName,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ownerCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre del propietario',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: vm.setOwnerName,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: vm.category,
                    isExpanded: true,
                    items: vm.categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) vm.setCategory(v);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: vm.setPhone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: vm.setAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: 'Descripción breve',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 4,
              onChanged: vm.setDescription,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: vm.acceptedTerms,
                  onChanged: (v) => vm.setAcceptedTerms(v ?? false),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.terms),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Acepto los ',
                        children: [
                          TextSpan(
                            text: 'términos y condiciones',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ', incluida la comisión (0 % los primeros 2 meses, luego 1 % y 2 %).'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: vm.submitting
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);
                        final ok = await vm.submit();
                        if (ok) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Tienda creada. Un administrador la revisará antes de publicarla.',
                              ),
                            ),
                          );
                          nav.pop(true);
                        } else {
                          messenger.showSnackBar(
                            SnackBar(content: Text(vm.error ?? 'No se pudo crear la tienda')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: vm.submitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enviar solicitud'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../auth/auth_cubit.dart';
import '../catalog/catalog_cubit.dart';

class EntrepreneurViewModel extends ChangeNotifier {
  String businessName = '';
  String ownerName = '';
  String category = '';
  String phone = '';
  String address = '';
  String description = '';
  bool acceptedTerms = false;
  bool submitting = false;

  /// Categorías del servidor (GET /categories) o una lista por defecto.
  final List<String> categories = Catalog.categories.isNotEmpty
      ? List.of(Catalog.categories)
      : const ['Comida', 'Bebidas', 'Postres', 'Snacks', 'Accesorios', 'Otros'];

  EntrepreneurViewModel() {
    if (!categories.contains(category)) category = categories.first;
  }

  void setBusinessName(String v) {
    businessName = v;
    notifyListeners();
  }

  void setOwnerName(String v) {
    ownerName = v;
    notifyListeners();
  }

  void setCategory(String v) {
    category = v;
    notifyListeners();
  }

  void setPhone(String v) {
    phone = v;
    notifyListeners();
  }

  void setAddress(String v) {
    address = v;
    notifyListeners();
  }

  void setDescription(String v) {
    description = v;
    notifyListeners();
  }

  void setAcceptedTerms(bool v) {
    acceptedTerms = v;
    notifyListeners();
  }

  String? error;

  /// "Quiero vender": crea la tienda (POST /seller/store). Queda pendiente
  /// hasta que un administrador la apruebe. Devuelve true si se creó.
  Future<bool> submit() async {
    error = null;
    if (businessName.trim().length < 3 || phone.trim().isEmpty || !acceptedTerms) {
      error = 'Completa los campos obligatorios y acepta los términos.';
      notifyListeners();
      return false;
    }
    if (!RegExp(r'^3\d{9}$').hasMatch(phone.replaceAll(RegExp(r'\D'), ''))) {
      error = 'Escribe un celular colombiano de 10 dígitos (ej. 3001234567).';
      notifyListeners();
      return false;
    }
    submitting = true;
    notifyListeners();
    try {
      final store = await sl<ApiClient>().post('/seller/store', data: {
        'name': businessName.trim(),
        'category': category,
        'description': description.trim(),
        'phone': phone.replaceAll(RegExp(r'\D'), ''),
        if (address.trim().isNotEmpty) 'pickupNotes': address.trim(),
        'acceptsCash': true,
        'allowsPickup': true,
      });
      await sl<AuthCubit>().refreshMe();
      sl<CatalogCubit>().setMyStore(Map<String, dynamic>.from(store as Map));
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }
}

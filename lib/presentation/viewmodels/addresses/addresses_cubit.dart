import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import 'addresses_state.dart';

/// Direcciones guardadas en la cuenta (GET/POST/PUT/DELETE /me/addresses).
class AddressesCubit extends Cubit<AddressesState> {
  final ApiClient _api;
  AddressesCubit(this._api) : super(const AddressesInitial());

  List<AddressModel> _addresses = [];

  Future<void> loadAddresses() async {
    if (_addresses.isEmpty) emit(const AddressesLoading());
    try {
      final r = await _api.get('/me/addresses') as List;
      _addresses = [for (final a in r) AddressModel.fromJson(a as Map<String, dynamic>)];
      AddressModel? def;
      for (final a in _addresses) {
        if (a.isDefault) def = a;
      }
      emit(AddressesLoaded(addresses: _addresses, defaultAddress: def ?? (_addresses.isEmpty ? null : _addresses.first)));
    } on ApiException catch (e) {
      emit(AddressError(e.message));
    }
  }

  Map<String, dynamic> _body(String label, String address, String city, String? details, bool isDefault,
          {double? lat, double? lng}) =>
      {
        'label': label.trim(),
        'address': address.trim(),
        'city': city.trim().isEmpty ? 'Santa Marta' : city.trim(),
        'details': (details ?? '').trim(),
        'isDefault': isDefault,
        if (lat != null && lng != null) 'latitude': lat,
        if (lat != null && lng != null) 'longitude': lng,
      };

  Future<void> addAddress({
    required String label,
    required String address,
    required String city,
    String? country,
    String? postalCode,
    double? latitude,
    double? longitude,
  }) async {
    emit(const AddressesLoading());
    try {
      final r = await _api.post(
        '/me/addresses',
        data: _body(label, address, city, postalCode, _addresses.isEmpty, lat: latitude, lng: longitude),
      );
      emit(AddressAdded(AddressModel.fromJson(r as Map<String, dynamic>)));
      await loadAddresses();
    } on ApiException catch (e) {
      emit(AddressError(e.message));
    }
  }

  Future<void> updateAddress({
    required String id,
    required String label,
    required String address,
    required String city,
    String? country,
    String? postalCode,
  }) async {
    final current = _addresses.where((a) => a.id == id).firstOrNull;
    emit(const AddressesLoading());
    try {
      final r = await _api.put(
        '/me/addresses/$id',
        data: _body(label, address, city, postalCode, current?.isDefault ?? false,
            lat: current?.latitude, lng: current?.longitude),
      );
      emit(AddressUpdated(AddressModel.fromJson(r as Map<String, dynamic>)));
      await loadAddresses();
    } on ApiException catch (e) {
      emit(AddressError(e.message));
    }
  }

  Future<void> deleteAddress(String id) async {
    emit(const AddressesLoading());
    try {
      await _api.delete('/me/addresses/$id');
      emit(AddressDeleted(id));
      await loadAddresses();
    } on ApiException catch (e) {
      emit(AddressError(e.message));
    }
  }

  Future<void> setDefaultAddress(String id) async {
    final a = _addresses.where((x) => x.id == id).firstOrNull;
    if (a == null) return;
    emit(const AddressesLoading());
    try {
      await _api.put(
        '/me/addresses/$id',
        data: _body(a.label, a.address, a.city, a.postalCode, true, lat: a.latitude, lng: a.longitude),
      );
      await loadAddresses();
    } on ApiException catch (e) {
      emit(AddressError(e.message));
    }
  }
}

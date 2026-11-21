import 'package:equatable/equatable.dart';

/// Estados para el manejo de direcciones
abstract class AddressesState extends Equatable {
  const AddressesState();

  @override
  List<Object?> get props => [];
}

class AddressesInitial extends AddressesState {
  const AddressesInitial();
}

class AddressesLoading extends AddressesState {
  const AddressesLoading();
}

class AddressesLoaded extends AddressesState {
  final List<AddressModel> addresses;
  final AddressModel? defaultAddress;

  const AddressesLoaded({required this.addresses, this.defaultAddress});

  @override
  List<Object?> get props => [addresses, defaultAddress];
}

class AddressAdded extends AddressesState {
  final AddressModel address;

  const AddressAdded(this.address);

  @override
  List<Object?> get props => [address];
}

class AddressUpdated extends AddressesState {
  final AddressModel address;

  const AddressUpdated(this.address);

  @override
  List<Object?> get props => [address];
}

class AddressDeleted extends AddressesState {
  final String addressId;

  const AddressDeleted(this.addressId);

  @override
  List<Object?> get props => [addressId];
}

class AddressError extends AddressesState {
  final String message;

  const AddressError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Modelo de dirección
class AddressModel extends Equatable {
  final String id;
  final String label;
  final String address;
  final String city;
  final String? country;
  final String? postalCode;
  final bool isDefault;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  const AddressModel({
    required this.id,
    required this.label,
    required this.address,
    required this.city,
    this.country,
    this.postalCode,
    required this.isDefault,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory AddressModel.fromJson(Map<String, dynamic> j) => AddressModel(
    id: j['id'].toString(),
    label: (j['label'] ?? '').toString(),
    address: (j['address'] ?? '').toString(),
    city: (j['city'] ?? '').toString(),
    country: 'Colombia',
    postalCode: (j['details'] ?? '').toString(),
    isDefault: j['isDefault'] == true,
    createdAt: DateTime.now(),
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
  );

  AddressModel copyWith({
    String? id,
    String? label,
    String? address,
    String? city,
    String? country,
    String? postalCode,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    label,
    address,
    city,
    country,
    postalCode,
    isDefault,
    createdAt,
  ];
}

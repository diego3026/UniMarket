import 'package:equatable/equatable.dart';

abstract class BankDataState extends Equatable {
  const BankDataState();
  @override
  List<Object?> get props => [];
}

class BankDataInitial extends BankDataState {
  const BankDataInitial();
}

class BankDataLoading extends BankDataState {
  const BankDataLoading();
}

/// [bankData] es null cuando el emprendedor aún no registra su cuenta.
class BankDataLoaded extends BankDataState {
  final BankDataModel? bankData;
  final int totalSales;
  final int deliveredOrders;
  const BankDataLoaded(this.bankData, {this.totalSales = 0, this.deliveredOrders = 0});
  @override
  List<Object?> get props => [bankData, totalSales, deliveredOrders];
}

class BankDataSaving extends BankDataState {
  const BankDataSaving();
}

class BankDataUpdated extends BankDataState {
  final BankDataModel bankData;
  const BankDataUpdated(this.bankData);
  @override
  List<Object?> get props => [bankData];
}

class BankDataError extends BankDataState {
  final String message;
  const BankDataError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Cuenta donde el emprendedor recibe sus pagos (PUT /seller/payout-account).
class BankDataModel extends Equatable {
  final String bankName;
  final String accountType; // ahorros | corriente | nequi | daviplata
  final String accountNumberMasked;
  final String holderName;
  final bool isVerified;
  final DateTime? updatedAt;

  const BankDataModel({
    required this.bankName,
    required this.accountType,
    required this.accountNumberMasked,
    required this.holderName,
    required this.isVerified,
    this.updatedAt,
  });

  factory BankDataModel.fromJson(Map<String, dynamic> j) => BankDataModel(
    bankName: (j['bankName'] ?? '').toString(),
    accountType: (j['accountType'] ?? 'ahorros').toString(),
    accountNumberMasked: (j['accountNumberMasked'] ?? '').toString(),
    holderName: (j['holderName'] ?? '').toString(),
    isVerified: j['isVerified'] == true,
    updatedAt: DateTime.tryParse((j['updatedAt'] ?? '').toString()),
  );

  @override
  List<Object?> get props => [bankName, accountType, accountNumberMasked, holderName, isVerified, updatedAt];
}

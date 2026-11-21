import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import 'bank_data_state.dart';

/// Cuenta de pagos del emprendedor + resumen de ventas.
class BankDataCubit extends Cubit<BankDataState> {
  final ApiClient _api;
  BankDataCubit(this._api) : super(const BankDataInitial());

  Future<void> loadBankData() async {
    emit(const BankDataLoading());
    BankDataModel? account;
    var sales = 0, delivered = 0;
    try {
      account = BankDataModel.fromJson(await _api.get('/seller/payout-account') as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.status != 404) {
        emit(BankDataError(e.message));
        return;
      }
    }
    try {
      final e = await _api.get('/seller/earnings') as Map<String, dynamic>;
      sales = (e['totalSales'] as num?)?.toInt() ?? 0;
      delivered = (e['deliveredOrders'] as num?)?.toInt() ?? 0;
    } on ApiException {
      // el resumen es opcional en esta pantalla
    }
    emit(BankDataLoaded(account, totalSales: sales, deliveredOrders: delivered));
  }

  Future<void> updateBankData({
    required String bankName,
    required String accountType,
    required String accountNumber,
    required String holderName,
    required String holderDocument,
  }) async {
    emit(const BankDataSaving());
    try {
      final r = await _api.put('/seller/payout-account', data: {
        'bankName': bankName.trim(),
        'accountType': accountType,
        'accountNumber': accountNumber.replaceAll(RegExp(r'\D'), ''),
        'holderName': holderName.trim(),
        'holderDocument': holderDocument.replaceAll(RegExp(r'\D'), ''),
      });
      emit(BankDataUpdated(BankDataModel.fromJson(r as Map<String, dynamic>)));
      await loadBankData();
    } on ApiException catch (e) {
      emit(BankDataError(e.message));
      await loadBankData();
    }
  }
}

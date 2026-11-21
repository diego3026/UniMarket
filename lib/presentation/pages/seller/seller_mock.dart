// Datos del emprendedor demo hasta conectar el backend (FastAPI).
import '../../../data/datasources/mock/catalog_mock_data.dart';
import '../../../domain/entities/store_entity.dart';

class SellerMock {
  SellerMock._();

  /// El usuario demo "emp" administra MaracuMango.
  static StoreEntity get store => CatalogMockData.storeById('s2')!;

  static const monthlyEarnings = <(String, double)>[
    ('Jun', 410000),
    ('Jul', 780000),
    ('Ago', 320000),
    ('Sep', 690000),
    ('Oct', 845000),
    ('Nov', 955500),
  ];
}

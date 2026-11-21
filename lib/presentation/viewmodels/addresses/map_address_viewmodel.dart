import 'package:flutter/foundation.dart';

class MapAddressViewModel extends ChangeNotifier {
  // Puntos de entrega del campus de la Universidad del Magdalena.
  final List<String> streets = [
    'Bloque 1',
    'Bloque 2',
    'Bloque 3',
    'Bloque 4',
    'Bloque 5',
    'Bloque 6',
    'Bloque 7',
    'Bloque 8',
    'Biblioteca Germán Bula Meyer',
    'Plazoleta central',
    'Cafetería central',
    'Portería principal',
    'Polideportivo',
    'Hangar',
    'Edificio Docente',
    'Aulas de Postgrado',
    'Laboratorios',
    'Auditorio',
  ];

  List<String> filtered = [];
  String selected = '';

  MapAddressViewModel() {
    filtered = List.from(streets);
  }

  void filter(String query) {
    if (query.trim().isEmpty) {
      filtered = List.from(streets);
    } else {
      final q = query.toLowerCase();
      filtered = streets.where((s) => s.toLowerCase().contains(q)).toList();
    }
    notifyListeners();
  }

  void select(String street) {
    selected = street;
    notifyListeners();
  }
}

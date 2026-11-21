// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';

final NumberFormat _thousands = NumberFormat('#,##0', 'es_CO');

/// Formatea un valor en pesos colombianos: 24000 -> "$ 24.000".
String formatCop(num value) => '\$ ${_thousands.format(value)}';

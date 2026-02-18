// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';

class Formatters {
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  static String formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$').format(amount);
  }
}
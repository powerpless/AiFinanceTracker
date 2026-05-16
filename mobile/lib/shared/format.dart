import 'package:intl/intl.dart';

String formatMoney(double value, {String symbol = '₸', bool precise = false}) {
  return NumberFormat.currency(
    locale: 'ru_RU',
    symbol: symbol,
    decimalDigits: precise ? 2 : 0,
  ).format(value);
}

String formatPercent(double value) {
  return '${value.toStringAsFixed(1)}%';
}

String localizeCurrency(String text, String symbol) {
  return text.replaceAll('{currency}', symbol).replaceAll('₽', symbol);
}

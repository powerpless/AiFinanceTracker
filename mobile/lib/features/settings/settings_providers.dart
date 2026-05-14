import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum Currency {
  rub('RUB', '₽', 'Рубли'),
  usd('USD', '\$', 'Доллары США'),
  eur('EUR', '€', 'Евро'),
  kzt('KZT', '₸', 'Тенге');

  final String code;
  final String symbol;
  final String name;

  const Currency(this.code, this.symbol, this.name);

  static Currency fromCode(String? code) {
    for (final c in Currency.values) {
      if (c.code == code) return c;
    }
    return Currency.kzt;
  }
}

class _PreferencesStorage {
  static const _currencyKey = 'preferred_currency';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> readCurrency() => _storage.read(key: _currencyKey);

  Future<void> writeCurrency(String code) =>
      _storage.write(key: _currencyKey, value: code);
}

final _preferencesStorageProvider =
    Provider<_PreferencesStorage>((ref) => _PreferencesStorage());

final currencyProvider =
    NotifierProvider<CurrencyController, Currency>(CurrencyController.new);

class CurrencyController extends Notifier<Currency> {
  @override
  Currency build() {
    _loadFromStorage();
    return Currency.kzt;
  }

  Future<void> _loadFromStorage() async {
    final storage = ref.read(_preferencesStorageProvider);
    final code = await storage.readCurrency();
    final loaded = Currency.fromCode(code);
    if (loaded != state) {
      state = loaded;
    }
  }

  Future<void> setCurrency(Currency currency) async {
    state = currency;
    await ref.read(_preferencesStorageProvider).writeCurrency(currency.code);
  }
}

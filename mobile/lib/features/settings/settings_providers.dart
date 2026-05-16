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

const double defaultMonthlyBudget = 85000;

class _PreferencesStorage {
  static const _currencyKey = 'preferred_currency';
  static const _budgetKey = 'monthly_budget';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> readCurrency() => _storage.read(key: _currencyKey);

  Future<void> writeCurrency(String code) =>
      _storage.write(key: _currencyKey, value: code);

  Future<String?> readBudget() => _storage.read(key: _budgetKey);

  Future<void> writeBudget(double value) =>
      _storage.write(key: _budgetKey, value: value.toString());

  Future<bool?> readBool(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    return raw == 'true';
  }

  Future<void> writeBool(String key, bool value) =>
      _storage.write(key: key, value: value ? 'true' : 'false');
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

final monthlyBudgetProvider =
    NotifierProvider<MonthlyBudgetController, double>(
  MonthlyBudgetController.new,
);

class MonthlyBudgetController extends Notifier<double> {
  @override
  double build() {
    _loadFromStorage();
    return defaultMonthlyBudget;
  }

  Future<void> _loadFromStorage() async {
    final storage = ref.read(_preferencesStorageProvider);
    final raw = await storage.readBudget();
    final parsed = raw == null ? null : double.tryParse(raw);
    if (parsed != null && parsed != state) {
      state = parsed;
    }
  }

  Future<void> setBudget(double value) async {
    final clamped = value < 0 ? 0.0 : value;
    state = clamped;
    await ref.read(_preferencesStorageProvider).writeBudget(clamped);
  }
}

class BoolFlagController extends Notifier<bool> {
  BoolFlagController(this._key, this._defaultValue);

  final String _key;
  final bool _defaultValue;

  @override
  bool build() {
    _loadFromStorage();
    return _defaultValue;
  }

  Future<void> _loadFromStorage() async {
    final raw = await ref.read(_preferencesStorageProvider).readBool(_key);
    if (raw != null && raw != state) {
      state = raw;
    }
  }

  Future<void> set(bool value) async {
    state = value;
    await ref.read(_preferencesStorageProvider).writeBool(_key, value);
  }
}

final aiSavingsTipsEnabledProvider =
    NotifierProvider<BoolFlagController, bool>(
  () => BoolFlagController('ai_tips_enabled', true),
);

final aiTrendForecastEnabledProvider =
    NotifierProvider<BoolFlagController, bool>(
  () => BoolFlagController('ai_forecast_enabled', true),
);

final aiAnomalyEnabledProvider =
    NotifierProvider<BoolFlagController, bool>(
  () => BoolFlagController('ai_anomaly_enabled', true),
);

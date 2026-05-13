double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

class CategorySummary {
  final String categoryId;
  final String categoryName;
  final String categoryType;
  final double totalAmount;
  final int transactionCount;
  final double percentage;

  CategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) =>
      CategorySummary(
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String? ?? '',
        categoryType: json['categoryType'] as String? ?? '',
        totalAmount: _toDouble(json['totalAmount']),
        transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
        percentage: _toDouble(json['percentage']),
      );
}

class DashboardSummary {
  final double currentBalance;
  final double monthIncome;
  final double monthExpense;
  final double monthBalance;
  final List<CategorySummary> topExpenseCategories;
  final List<CategorySummary> topIncomeCategories;
  final int transactionCount;

  DashboardSummary({
    required this.currentBalance,
    required this.monthIncome,
    required this.monthExpense,
    required this.monthBalance,
    required this.topExpenseCategories,
    required this.topIncomeCategories,
    required this.transactionCount,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    List<CategorySummary> parseList(dynamic v) {
      if (v is! List) return const [];
      return v
          .whereType<Map<String, dynamic>>()
          .map(CategorySummary.fromJson)
          .toList();
    }

    return DashboardSummary(
      currentBalance: _toDouble(json['currentBalance']),
      monthIncome: _toDouble(json['monthIncome']),
      monthExpense: _toDouble(json['monthExpense']),
      monthBalance: _toDouble(json['monthBalance']),
      topExpenseCategories: parseList(json['topExpenseCategories']),
      topIncomeCategories: parseList(json['topIncomeCategories']),
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

enum CategoryType { income, expense, unknown }

CategoryType _parseCategoryType(String? v) {
  if (v == 'INCOME') return CategoryType.income;
  if (v == 'EXPENSE') return CategoryType.expense;
  return CategoryType.unknown;
}

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final bool systemCategory;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.systemCategory,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        type: _parseCategoryType(json['type'] as String?),
        systemCategory: (json['systemCategory'] as bool?) ?? false,
      );
}

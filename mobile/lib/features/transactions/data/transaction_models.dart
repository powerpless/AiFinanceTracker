import '../../categories/data/category_models.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

class TransactionItem {
  final String id;
  final Category? category;
  final double amount;
  final DateTime operationDate;
  final String? description;

  TransactionItem({
    required this.id,
    required this.category,
    required this.amount,
    required this.operationDate,
    required this.description,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      category: json['category'] is Map<String, dynamic>
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      amount: _toDouble(json['amount']),
      operationDate: DateTime.parse(json['operationDate'] as String).toLocal(),
      description: json['description'] as String?,
    );
  }
}

class TransactionCreateRequest {
  final String categoryId;
  final double amount;
  final DateTime operationDate;
  final String? description;

  TransactionCreateRequest({
    required this.categoryId,
    required this.amount,
    required this.operationDate,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'amount': amount,
        'operationDate': operationDate.toUtc().toIso8601String(),
        if (description != null && description!.isNotEmpty)
          'description': description,
      };
}

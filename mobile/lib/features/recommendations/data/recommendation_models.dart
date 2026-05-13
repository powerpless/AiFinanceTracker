enum RecommendationType {
  trendForecast,
  anomaly,
  savingsTip,
  unknown,
}

RecommendationType _parseType(String? v) {
  switch (v) {
    case 'TREND_FORECAST':
      return RecommendationType.trendForecast;
    case 'ANOMALY':
      return RecommendationType.anomaly;
    case 'SAVINGS_TIP':
      return RecommendationType.savingsTip;
    default:
      return RecommendationType.unknown;
  }
}

double? _toDoubleNullable(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class Recommendation {
  final String id;
  final RecommendationType type;
  final String status;
  final String title;
  final String message;
  final double? savingsEstimate;
  final String? relatedCategoryId;
  final String? metadata;
  final DateTime generatedDate;
  final DateTime? validUntil;

  Recommendation({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.message,
    required this.savingsEstimate,
    required this.relatedCategoryId,
    required this.metadata,
    required this.generatedDate,
    required this.validUntil,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        id: json['id'] as String,
        type: _parseType(json['type'] as String?),
        status: json['status'] as String? ?? 'ACTIVE',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        savingsEstimate: _toDoubleNullable(json['savingsEstimate']),
        relatedCategoryId: json['relatedCategoryId'] as String?,
        metadata: json['metadata'] as String?,
        generatedDate:
            DateTime.parse(json['generatedDate'] as String).toLocal(),
        validUntil: json['validUntil'] != null
            ? DateTime.parse(json['validUntil'] as String).toLocal()
            : null,
      );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../settings/settings_providers.dart';
import 'data/recommendation_api.dart';
import 'data/recommendation_models.dart';

final recommendationApiProvider =
    Provider<RecommendationApi>((ref) => RecommendationApi(ref.watch(dioProvider)));

final recommendationsProvider =
    FutureProvider.autoDispose<List<Recommendation>>((ref) async {
  return ref.watch(recommendationApiProvider).getActive();
});

/// Recommendations filtered by user-controlled AI toggles in Settings.
/// Keeps [recommendationsProvider] as the canonical fetch/refresh source.
final visibleRecommendationsProvider =
    Provider.autoDispose<AsyncValue<List<Recommendation>>>((ref) {
  final async = ref.watch(recommendationsProvider);
  final tipsOn = ref.watch(aiSavingsTipsEnabledProvider);
  final forecastOn = ref.watch(aiTrendForecastEnabledProvider);
  final anomalyOn = ref.watch(aiAnomalyEnabledProvider);
  return async.whenData((items) {
    return items.where((r) {
      switch (r.type) {
        case RecommendationType.savingsTip:
          return tipsOn;
        case RecommendationType.trendForecast:
          return forecastOn;
        case RecommendationType.anomaly:
          return anomalyOn;
        case RecommendationType.unknown:
          return true;
      }
    }).toList();
  });
});

final mlHealthProvider = FutureProvider.autoDispose<bool>((ref) async {
  return ref.watch(recommendationApiProvider).isMlServiceHealthy();
});

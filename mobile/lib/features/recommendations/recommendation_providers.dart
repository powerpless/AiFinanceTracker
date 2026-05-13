import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'data/recommendation_api.dart';
import 'data/recommendation_models.dart';

final recommendationApiProvider =
    Provider<RecommendationApi>((ref) => RecommendationApi(ref.watch(dioProvider)));

final recommendationsProvider =
    FutureProvider.autoDispose<List<Recommendation>>((ref) async {
  return ref.watch(recommendationApiProvider).getActive();
});

final mlHealthProvider = FutureProvider.autoDispose<bool>((ref) async {
  return ref.watch(recommendationApiProvider).isMlServiceHealthy();
});

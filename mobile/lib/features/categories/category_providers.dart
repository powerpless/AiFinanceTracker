import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'data/category_api.dart';
import 'data/category_models.dart';

final categoryApiProvider =
    Provider<CategoryApi>((ref) => CategoryApi(ref.watch(dioProvider)));

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(categoryApiProvider).getAll();
});

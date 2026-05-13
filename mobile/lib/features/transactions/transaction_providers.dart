import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'data/transaction_api.dart';
import 'data/transaction_models.dart';

final transactionApiProvider =
    Provider<TransactionApi>((ref) => TransactionApi(ref.watch(dioProvider)));

final transactionsProvider =
    FutureProvider.autoDispose<List<TransactionItem>>((ref) async {
  final items = await ref.watch(transactionApiProvider).getAll();
  items.sort((a, b) => b.operationDate.compareTo(a.operationDate));
  return items;
});

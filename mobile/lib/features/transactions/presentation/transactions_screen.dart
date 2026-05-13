import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/format.dart';
import '../../categories/data/category_models.dart';
import '../../dashboard/dashboard_providers.dart';
import '../../settings/settings_providers.dart';
import '../data/transaction_models.dart';
import '../transaction_providers.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transactionsProvider);
    final symbol = ref.watch(currencyProvider).symbol;

    return Scaffold(
      appBar: AppBar(title: const Text('Все транзакции')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsProvider);
          await ref.read(transactionsProvider.future);
        },
        child: async.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Транзакций пока нет. Нажмите «Добавить» чтобы создать первую.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final t = items[index];
                return _TransactionTile(
                  item: t,
                  symbol: symbol,
                  onDelete: () async {
                    final ok = await _confirmDelete(context);
                    if (!ok) return;
                    try {
                      await ref
                          .read(transactionApiProvider)
                          .delete(t.id);
                      ref.invalidate(transactionsProvider);
                      ref.invalidate(dashboardSummaryProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка удаления: $e')),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Ошибка загрузки: $e'),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить транзакцию?'),
        content: const Text('Действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionItem item;
  final String symbol;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.item,
    required this.symbol,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = item.category?.type == CategoryType.income;
    final color = isIncome ? Colors.green : Colors.redAccent;
    final sign = isIncome ? '+' : '−';
    final dateLabel = DateFormat('d MMM yyyy', 'ru').format(item.operationDate);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
        ),
      ),
      title: Text(item.category?.name ?? 'Без категории'),
      subtitle: Text(
        '$dateLabel${(item.description ?? '').isNotEmpty ? ' • ${item.description}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$sign ${formatMoney(item.amount, symbol: symbol)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            tooltip: 'Удалить',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

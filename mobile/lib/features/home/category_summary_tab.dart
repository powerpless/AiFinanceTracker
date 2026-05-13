import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../shared/format.dart';
import '../categories/category_providers.dart';
import '../categories/data/category_models.dart';
import '../settings/settings_providers.dart';
import '../transactions/data/transaction_models.dart';
import '../transactions/transaction_providers.dart';

class CategorySummaryTab extends ConsumerWidget {
  final CategoryType type;

  const CategorySummaryTab({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final symbol = ref.watch(currencyProvider).symbol;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(categoriesProvider);
        ref.invalidate(transactionsProvider);
        await Future.wait([
          ref.read(categoriesProvider.future),
          ref.read(transactionsProvider.future),
        ]);
      },
      child: categoriesAsync.when(
        loading: () => const _Loader(),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (categories) => transactionsAsync.when(
          loading: () => const _Loader(),
          error: (e, _) => _ErrorView(message: e.toString()),
          data: (transactions) =>
              _buildContent(context, categories, transactions, symbol),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Category> allCategories,
    List<TransactionItem> allTransactions,
    String symbol,
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final monthTxs = allTransactions.where((t) {
      final inMonth = !t.operationDate.isBefore(monthStart) &&
          t.operationDate.isBefore(monthEnd);
      final ofType = t.category?.type == type;
      return inMonth && ofType;
    }).toList();

    final sumByCategory = <String, double>{};
    for (final t in monthTxs) {
      final id = t.category?.id;
      if (id == null) continue;
      sumByCategory[id] = (sumByCategory[id] ?? 0) + t.amount;
    }

    final categoriesOfType = allCategories.where((c) => c.type == type).toList()
      ..sort((a, b) {
        final sa = sumByCategory[a.id] ?? 0;
        final sb = sumByCategory[b.id] ?? 0;
        if (sa == sb) return a.name.compareTo(b.name);
        return sb.compareTo(sa);
      });

    final total = sumByCategory.values.fold<double>(0, (a, b) => a + b);
    final accent =
        type == CategoryType.expense ? Colors.redAccent : Colors.green;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _MonthHeader(month: monthStart, total: total, symbol: symbol),
        const Divider(height: 1),
        if (categoriesOfType.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Категорий нет.',
              textAlign: TextAlign.center,
            ),
          )
        else
          ...categoriesOfType.map((c) => _CategoryRow(
                category: c,
                amount: sumByCategory[c.id] ?? 0,
                symbol: symbol,
                accent: accent,
              )),
        const SizedBox(height: 16),
        _HistorySection(transactions: monthTxs, symbol: symbol, accent: accent),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final double total;
  final String symbol;

  const _MonthHeader({
    required this.month,
    required this.total,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = DateFormat('LLLL yyyy', 'ru').format(month);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _capitalize(label),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            'Итого: ${formatMoney(total, symbol: symbol)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _CategoryRow extends StatelessWidget {
  final Category category;
  final double amount;
  final String symbol;
  final Color accent;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.symbol,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final hasAmount = amount > 0;
    return InkWell(
      onTap: () => _openForm(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: TextStyle(
                  color: hasAmount ? null : Colors.grey.shade600,
                ),
              ),
            ),
            Text(
              formatMoney(amount, symbol: symbol),
              style: TextStyle(
                fontWeight: hasAmount ? FontWeight.w600 : FontWeight.normal,
                color: hasAmount ? null : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: 'Добавить в категорию',
              icon: const Icon(Icons.add, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: () => _openForm(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context) {
    context.push('/transactions/new?categoryId=${category.id}');
  }
}

class _HistorySection extends StatelessWidget {
  final List<TransactionItem> transactions;
  final String symbol;
  final Color accent;

  const _HistorySection({
    required this.transactions,
    required this.symbol,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...transactions]
      ..sort((a, b) => b.operationDate.compareTo(a.operationDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'История',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'В этом месяце нет операций.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ..._groupByDay(sorted).entries.expand((entry) {
            return [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDayHeader(entry.key),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      formatMoney(
                        entry.value
                            .fold<double>(0, (sum, t) => sum + t.amount),
                        symbol: symbol,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              ...entry.value.map((t) => _HistoryRow(
                    transaction: t,
                    symbol: symbol,
                    accent: accent,
                  )),
              const Divider(height: 1),
            ];
          }),
      ],
    );
  }

  Map<DateTime, List<TransactionItem>> _groupByDay(
    List<TransactionItem> items,
  ) {
    final map = <DateTime, List<TransactionItem>>{};
    for (final t in items) {
      final d = DateTime(
        t.operationDate.year,
        t.operationDate.month,
        t.operationDate.day,
      );
      map.putIfAbsent(d, () => []).add(t);
    }
    return map;
  }

  String _formatDayHeader(DateTime date) {
    return DateFormat('d MMMM', 'ru').format(date);
  }
}

class _HistoryRow extends StatelessWidget {
  final TransactionItem transaction;
  final String symbol;
  final Color accent;

  const _HistoryRow({
    required this.transaction,
    required this.symbol,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.category?.name ?? 'Без категории'),
                if ((transaction.description ?? '').isNotEmpty)
                  Text(
                    transaction.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            formatMoney(transaction.amount, symbol: symbol),
            style: TextStyle(color: accent, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Ошибка: $message', textAlign: TextAlign.center),
    );
  }
}

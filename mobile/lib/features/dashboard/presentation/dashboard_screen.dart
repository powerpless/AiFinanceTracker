import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/format.dart';
import '../../settings/settings_providers.dart';
import '../dashboard_providers.dart';
import '../data/dashboard_models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final currency = ref.watch(currencyProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardSummaryProvider);
        await ref.read(dashboardSummaryProvider.future);
      },
      child: summaryAsync.when(
        data: (summary) =>
            _DashboardContent(summary: summary, symbol: currency.symbol),
        loading: () => const _CenteredLoader(),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
        ),
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Не удалось загрузить дашборд',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Повторить'),
          ),
        ),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardSummary summary;
  final String symbol;

  const _DashboardContent({required this.summary, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _BalanceCard(balance: summary.currentBalance, symbol: symbol),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Доход за месяц',
                value: summary.monthIncome,
                symbol: symbol,
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Расход за месяц',
                value: summary.monthExpense,
                symbol: symbol,
                icon: Icons.trending_down,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MonthBalanceCard(
          balance: summary.monthBalance,
          transactionCount: summary.transactionCount,
          symbol: symbol,
        ),
        const SizedBox(height: 24),
        _CategoryList(
          title: 'Топ расходов за месяц',
          items: summary.topExpenseCategories,
          accent: Colors.redAccent,
          symbol: symbol,
          emptyHint: 'В этом месяце расходов не было.',
        ),
        const SizedBox(height: 16),
        _CategoryList(
          title: 'Топ доходов за месяц',
          items: summary.topIncomeCategories,
          accent: Colors.green,
          symbol: symbol,
          emptyHint: 'В этом месяце доходов не было.',
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final String symbol;

  const _BalanceCard({required this.balance, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Текущий баланс',
              style: TextStyle(color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
            Text(
              formatMoney(balance, symbol: symbol),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final double value;
  final String symbol;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.symbol,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              formatMoney(value, symbol: symbol),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthBalanceCard extends StatelessWidget {
  final double balance;
  final int transactionCount;
  final String symbol;

  const _MonthBalanceCard({
    required this.balance,
    required this.transactionCount,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isPositive ? Icons.savings : Icons.warning_amber,
              color: isPositive ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Сальдо за месяц'),
                  const SizedBox(height: 2),
                  Text(
                    '$transactionCount транзакций всего',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              formatMoney(balance, symbol: symbol),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isPositive ? Colors.green : Colors.redAccent,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final String title;
  final List<CategorySummary> items;
  final Color accent;
  final String symbol;
  final String emptyHint;

  const _CategoryList({
    required this.title,
    required this.items,
    required this.accent,
    required this.symbol,
    required this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                emptyHint,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...items.map(
                (c) => _CategoryRow(item: c, accent: accent, symbol: symbol),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategorySummary item;
  final Color accent;
  final String symbol;

  const _CategoryRow({
    required this.item,
    required this.accent,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (item.percentage.clamp(0, 100)) / 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.categoryName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatMoney(item.totalAmount, symbol: symbol),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Text(
                formatPercent(item.percentage),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.toDouble(),
              minHeight: 6,
              backgroundColor: accent.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

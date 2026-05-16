import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/format.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../widgets/charts/donut_chart.dart';
import '../../../widgets/charts/sparkline_chart.dart';
import '../../../widgets/glow_card.dart';
import '../../categories/data/category_models.dart';
import '../../settings/settings_providers.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/transaction_providers.dart';
import '../data/dashboard_models.dart';
import '../dashboard_providers.dart';

enum _Period { day, week, month, year }

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  _Period _period = _Period.month;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final symbol = ref.watch(currencyProvider).symbol;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(transactionsProvider);
        await Future.wait([
          ref.read(dashboardSummaryProvider.future),
          ref.read(transactionsProvider.future),
        ]);
      },
      color: AppColors.accent,
      backgroundColor: AppColors.bgRaised,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            SliverToBoxAdapter(
              child: _PeriodTabs(
                value: _period,
                onChanged: (v) => setState(() => _period = v),
              ),
            ),
            SliverToBoxAdapter(
              child: summaryAsync.when(
                loading: _loading,
                error: (e, _) => _error(e.toString()),
                data: (summary) => _buildBody(
                  summary,
                  transactionsAsync,
                  symbol,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: kBottomNavReservedSpace),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );

  Widget _error(String message) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Не удалось загрузить: $message',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.coral),
          ),
        ),
      );

  Widget _buildBody(
    DashboardSummary summary,
    AsyncValue<List<TransactionItem>> transactionsAsync,
    String symbol,
  ) {
    final transactions = transactionsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => const <TransactionItem>[],
    );

    final range = _periodRange();
    final periodTxs = transactions
        .where((t) =>
            !t.operationDate.isBefore(range.start) &&
            t.operationDate.isBefore(range.end))
        .toList();

    double periodIncome = 0;
    double periodExpense = 0;
    for (final t in periodTxs) {
      final type = t.category?.type;
      if (type == CategoryType.income) {
        periodIncome += t.amount;
      } else if (type == CategoryType.expense) {
        periodExpense += t.amount;
      }
    }
    final periodSaldo = periodIncome - periodExpense;

    final topExpense = _topCategoriesFor(periodTxs, CategoryType.expense);
    final topIncome = _topCategoriesFor(periodTxs, CategoryType.income);
    final periodLabel = _periodLabel(_period);
    final periodLabelUpper = periodLabel.toUpperCase();

    final trend = _buildBalanceTrend(
      currentBalance: summary.currentBalance,
      transactions: transactions,
    );
    final cashflow = _buildDailyExpense(transactions);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _BalanceHero(
              balance: summary.currentBalance,
              delta: _balanceDeltaPercent(trend),
              trend: trend,
              symbol: symbol,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _StatPair(
              income: periodIncome,
              expense: periodExpense,
              symbol: symbol,
              periodLabel: periodLabel,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _SaldoCard(
              saldo: periodSaldo,
              income: periodIncome,
              symbol: symbol,
              periodLabelUpper: periodLabelUpper,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _TopExpensesCard(
              items: topExpense,
              symbol: symbol,
              periodLabelUpper: periodLabelUpper,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _TopIncomesCard(
              items: topIncome,
              symbol: symbol,
              periodLabelUpper: periodLabelUpper,
            ),
          ),
          if (cashflow.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: _CashflowCard(daily: cashflow),
            ),
          ],
        ],
      ),
    );
  }

  ({DateTime start, DateTime end}) _periodRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    switch (_period) {
      case _Period.day:
        return (start: today, end: tomorrow);
      case _Period.week:
        return (
          start: today.subtract(const Duration(days: 6)),
          end: tomorrow,
        );
      case _Period.month:
        return (
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 1),
        );
      case _Period.year:
        return (
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year + 1, 1, 1),
        );
    }
  }

  String _periodLabel(_Period p) {
    switch (p) {
      case _Period.day:
        return 'за день';
      case _Period.week:
        return 'за неделю';
      case _Period.month:
        return 'за месяц';
      case _Period.year:
        return 'за год';
    }
  }

  List<CategorySummary> _topCategoriesFor(
    List<TransactionItem> txs,
    CategoryType type,
  ) {
    final sums = <String, _CategoryAcc>{};
    double total = 0;
    for (final t in txs) {
      final c = t.category;
      if (c == null || c.type != type) continue;
      total += t.amount;
      final acc = sums.putIfAbsent(c.id, () => _CategoryAcc(c.name));
      acc.sum += t.amount;
      acc.count += 1;
    }
    final typeWire = type == CategoryType.income ? 'INCOME' : 'EXPENSE';
    final result = sums.entries
        .map((e) => CategorySummary(
              categoryId: e.key,
              categoryName: e.value.name,
              categoryType: typeWire,
              totalAmount: e.value.sum,
              transactionCount: e.value.count,
              percentage: total > 0 ? (e.value.sum / total) * 100 : 0,
            ))
        .toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return result.take(5).toList();
  }

  List<double> _buildBalanceTrend({
    required double currentBalance,
    required List<TransactionItem> transactions,
  }) {
    const days = 30;
    final today = DateTime.now();
    final startDay = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: days - 1));

    final netByDay = List<double>.filled(days, 0);
    for (final t in transactions) {
      final d = DateTime(
        t.operationDate.year,
        t.operationDate.month,
        t.operationDate.day,
      );
      final idx = d.difference(startDay).inDays;
      if (idx < 0 || idx >= days) continue;
      final isIncome = t.category?.type == CategoryType.income;
      netByDay[idx] += isIncome ? t.amount : -t.amount;
    }

    // Walk backwards from today's balance to derive each prior end-of-day balance.
    final balances = List<double>.filled(days, 0);
    balances[days - 1] = currentBalance;
    for (var i = days - 2; i >= 0; i--) {
      balances[i] = balances[i + 1] - netByDay[i + 1];
    }
    return balances;
  }

  double? _balanceDeltaPercent(List<double> trend) {
    if (trend.length < 2) return null;
    final start = trend.first;
    final end = trend.last;
    if (start.abs() < 1e-6) return null;
    return ((end - start) / start.abs()) * 100;
  }

  List<double> _buildDailyExpense(List<TransactionItem> transactions) {
    const days = 30;
    if (transactions.isEmpty) return const [];
    final today = DateTime.now();
    final startDay = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: days - 1));

    final out = List<double>.filled(days, 0);
    for (final t in transactions) {
      if (t.category?.type != CategoryType.expense) continue;
      final d = DateTime(
        t.operationDate.year,
        t.operationDate.month,
        t.operationDate.day,
      );
      final idx = d.difference(startDay).inDays;
      if (idx < 0 || idx >= days) continue;
      out[idx] += t.amount;
    }
    final hasAny = out.any((v) => v > 0);
    return hasAny ? out : const [];
  }
}

// ──────────────────────────── HEADER ────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 8, AppSpacing.screen, 0),
      child: Row(
        children: const [
          Text(
            'Дашборд',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── PERIOD TABS ──────────────────────────

class _PeriodTabs extends StatelessWidget {
  final _Period value;
  final ValueChanged<_Period> onChanged;

  const _PeriodTabs({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = {
      _Period.day: 'День',
      _Period.week: 'Неделя',
      _Period.month: 'Месяц',
      _Period.year: 'Год',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        10,
        AppSpacing.screen,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.bgSunken,
          borderRadius: AppRadius.rLg,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          children: _Period.values.map((p) {
            final active = value == p;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: p == _Period.values.last ? 0 : 4,
                ),
                child: Material(
                  color: active ? AppColors.bgRaised : Colors.transparent,
                  borderRadius: AppRadius.rSm,
                  child: InkWell(
                    onTap: () => onChanged(p),
                    borderRadius: AppRadius.rSm,
                    child: Container(
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.rSm,
                        border: Border.all(
                          color: active
                              ? AppColors.accentHair
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        labels[p]!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: active ? AppColors.text : AppColors.textDim,
                          fontWeight:
                              active ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ───────────────────────── BALANCE HERO ─────────────────────────

class _BalanceHero extends StatelessWidget {
  final double balance;
  final double? delta;
  final List<double> trend;
  final String symbol;

  const _BalanceHero({
    required this.balance,
    required this.delta,
    required this.trend,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      variant: GlowCardVariant.hero,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.accentSoft, Color(0x00000000)],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ТЕКУЩИЙ БАЛАНС',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatMoney(balance, symbol: ''),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        symbol,
                        style: const TextStyle(
                          color: AppColors.textMid,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (delta != null)
                    _DeltaChip(value: delta!)
                  else
                    const Text(
                      'нет данных за период',
                      style: TextStyle(color: AppColors.textFaint, fontSize: 11),
                    ),
                  const SizedBox(width: 6),
                  const Text(
                    'за 30 дней',
                    style: TextStyle(color: AppColors.textMid, fontSize: 11.5),
                  ),
                ],
              ),
              if (trend.length >= 2) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  child: SparklineChart(
                    points: trend,
                    lineColor: AppColors.accent,
                    fillColor: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Text(
                      '30 дней назад',
                      style:
                          TextStyle(color: AppColors.textFaint, fontSize: 10),
                    ),
                    Spacer(),
                    Text(
                      'сегодня',
                      style:
                          TextStyle(color: AppColors.textFaint, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final double value;
  const _DeltaChip({required this.value});

  @override
  Widget build(BuildContext context) {
    final up = value >= 0;
    final color = up ? AppColors.mint : AppColors.coral;
    final bg = up ? AppColors.mintSoft : AppColors.coralSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${value.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── STAT PAIR ─────────────────────────

class _StatPair extends StatelessWidget {
  final double income;
  final double expense;
  final String symbol;
  final String periodLabel;

  const _StatPair({
    required this.income,
    required this.expense,
    required this.symbol,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Доход $periodLabel',
            amount: income,
            symbol: symbol,
            icon: Icons.south_west,
            color: AppColors.mint,
            soft: AppColors.mintSoft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Расход $periodLabel',
            amount: expense,
            symbol: symbol,
            icon: Icons.north_east,
            color: AppColors.coral,
            soft: AppColors.coralSoft,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final String symbol;
  final IconData icon;
  final Color color;
  final Color soft;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.symbol,
    required this.icon,
    required this.color,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      variant: GlowCardVariant.flat,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10.5,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formatMoney(amount, symbol: ''),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  symbol,
                  style: const TextStyle(
                    color: AppColors.textMid,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── SALDO CARD ─────────────────────────

class _SaldoCard extends StatelessWidget {
  final double saldo;
  final double income;
  final String symbol;
  final String periodLabelUpper;

  const _SaldoCard({
    required this.saldo,
    required this.income,
    required this.symbol,
    required this.periodLabelUpper,
  });

  @override
  Widget build(BuildContext context) {
    final positive = saldo >= 0;
    final savingsRate = (income > 0)
        ? ((saldo / income) * 100).clamp(-100, 200).round()
        : null;
    final color = positive ? AppColors.mint : AppColors.coral;

    return GlowCard(
      variant: GlowCardVariant.card,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      background: AppColors.bgRaised,
      border: Border.all(color: AppColors.mintHair),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.mintHair),
                ),
                alignment: Alignment.center,
                child: Icon(
                  positive
                      ? Icons.savings_outlined
                      : Icons.warning_amber_outlined,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'САЛЬДО $periodLabelUpper',
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 10.5,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${positive ? '+' : '−'}${formatMoney(saldo.abs(), symbol: symbol)}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (savingsRate != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$savingsRate%',
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      'сэкономлено',
                      style: TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (savingsRate != null && positive) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 4,
                child: Stack(
                  children: [
                    const ColoredBox(color: AppColors.bgSunken),
                    FractionallySizedBox(
                      widthFactor: (savingsRate / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.mint, AppColors.mintHair],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(99)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mintHair,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────── TOP EXPENSES CARD ────────────────────

class _TopExpensesCard extends StatelessWidget {
  final List<CategorySummary> items;
  final String symbol;
  final String periodLabelUpper;

  const _TopExpensesCard({
    required this.items,
    required this.symbol,
    required this.periodLabelUpper,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptySection(
        title: 'ТОП РАСХОДОВ $periodLabelUpper',
        icon: Icons.pie_chart_outline,
        body: 'За этот период расходов не было.',
      );
    }

    final palette = AppColors.chartPalette;
    final segments = <DonutSegment>[];
    for (var i = 0; i < items.length; i++) {
      segments.add(DonutSegment(
        value: items[i].totalAmount,
        color: palette[i % palette.length],
      ));
    }
    final total = items.fold<double>(0, (s, c) => s + c.totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'ТОП РАСХОДОВ $periodLabelUpper',
          icon: Icons.pie_chart_outline,
        ),
        const SizedBox(height: 8),
        GlowCard(
          variant: GlowCardVariant.hero,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              DonutChart(
                segments: segments,
                size: 144,
                thickness: 16,
                centerLabel: 'ВСЕГО',
                centerValue: _compact(total, symbol),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(items.length, (i) {
                    final c = items[i];
                    final pct = total > 0
                        ? ((c.totalAmount / total) * 100).round()
                        : 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _LegendRow(
                        color: palette[i % palette.length],
                        name: c.categoryName,
                        pct: pct,
                        amount: c.totalAmount,
                        symbol: symbol,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _compact(double n, String symbol) {
    final abs = n.abs();
    if (abs >= 1e6) {
      return '${(n / 1e6).toStringAsFixed(1).replaceAll('.', ',')} млн $symbol';
    }
    if (abs >= 1e3) {
      return '${(n / 1e3).toStringAsFixed(1).replaceAll('.', ',')} тыс $symbol';
    }
    return formatMoney(n, symbol: symbol);
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String name;
  final int pct;
  final double amount;
  final String symbol;

  const _LegendRow({
    required this.color,
    required this.name,
    required this.pct,
    required this.amount,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color, blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                formatMoney(amount, symbol: symbol),
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── TOP INCOMES CARD ───────────────────

class _TopIncomesCard extends StatelessWidget {
  final List<CategorySummary> items;
  final String symbol;
  final String periodLabelUpper;

  const _TopIncomesCard({
    required this.items,
    required this.symbol,
    required this.periodLabelUpper,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptySection(
        title: 'ТОП ДОХОДОВ $periodLabelUpper',
        icon: Icons.trending_up,
        body: 'За этот период доходов не было.',
      );
    }
    final total = items.fold<double>(0, (s, c) => s + c.totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'ТОП ДОХОДОВ $periodLabelUpper',
          icon: Icons.trending_up,
        ),
        const SizedBox(height: 8),
        GlowCard(
          variant: GlowCardVariant.card,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Column(
            children: List.generate(items.length, (i) {
              final c = items[i];
              final pct = total > 0
                  ? ((c.totalAmount / total) * 100).round()
                  : 0;
              return Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 8, bottom: 8),
                child: _IncomeRow(
                  name: c.categoryName,
                  amount: c.totalAmount,
                  pct: pct,
                  symbol: symbol,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _IncomeRow extends StatelessWidget {
  final String name;
  final double amount;
  final int pct;
  final String symbol;

  const _IncomeRow({
    required this.name,
    required this.amount,
    required this.pct,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.bgSunken,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.hairline),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.work_outline,
                size: 15,
                color: AppColors.mint,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13.5,
                ),
              ),
            ),
            Text(
              formatMoney(amount, symbol: symbol),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    children: [
                      const ColoredBox(color: AppColors.bgSunken),
                      FractionallySizedBox(
                        widthFactor: (pct / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.mint, AppColors.mintHair],
                            ),
                            borderRadius:
                                BorderRadius.all(Radius.circular(99)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$pct%',
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────── CASHFLOW CARD ──────────────────────

class _CashflowCard extends StatelessWidget {
  final List<double> daily;

  const _CashflowCard({required this.daily});

  @override
  Widget build(BuildContext context) {
    final maxV = daily.reduce((a, b) => a > b ? a : b);
    final today = DateTime.now();
    final start = today.subtract(Duration(days: daily.length - 1));
    final mid = start.add(Duration(days: daily.length ~/ 2));

    String fmtDay(DateTime d) =>
        '${d.day} ${DateFormat('MMM', 'ru').format(d).toLowerCase().replaceAll('.', '')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
            title: 'ДЕНЕЖНЫЙ ПОТОК · 30 ДНЕЙ', icon: Icons.bar_chart),
        const SizedBox(height: 8),
        GlowCard(
          variant: GlowCardVariant.card,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 76,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(daily.length, (i) {
                    final v = daily[i];
                    final isLast = i == daily.length - 1;
                    final h = maxV > 0
                        ? (v / maxV).clamp(0.0, 1.0) * 60.0
                        : 0.0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: SizedBox(
                          height: 76,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: v == 0 ? 2 : h.clamp(2.0, 60.0),
                              decoration: BoxDecoration(
                                gradient: v == 0
                                    ? null
                                    : const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppColors.coral,
                                          AppColors.coralHair,
                                        ],
                                      ),
                                color: v == 0 ? AppColors.hairline : null,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: isLast && v > 0
                                    ? const [
                                        BoxShadow(
                                          color: AppColors.coralHair,
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    fmtDay(start),
                    style: const TextStyle(
                      color: AppColors.textFaint,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    fmtDay(mid),
                    style: const TextStyle(
                      color: AppColors.textFaint,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    fmtDay(today),
                    style: const TextStyle(
                      color: AppColors.textFaint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────── SHARED PIECES ────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textDim),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMid,
              fontSize: 12,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryAcc {
  final String name;
  double sum = 0;
  int count = 0;
  _CategoryAcc(this.name);
}

class _EmptySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String body;

  const _EmptySection({
    required this.title,
    required this.icon,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, icon: icon),
        const SizedBox(height: 8),
        GlowCard(
          variant: GlowCardVariant.card,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              body,
              style: const TextStyle(color: AppColors.textDim, fontSize: 12.5),
            ),
          ),
        ),
      ],
    );
  }
}

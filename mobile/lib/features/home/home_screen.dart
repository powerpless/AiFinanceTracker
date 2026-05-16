import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../shared/format.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/glow_card.dart';
import '../auth/auth_providers.dart';
import '../categories/category_providers.dart';
import '../categories/data/category_models.dart';
import '../recommendations/data/recommendation_models.dart';
import '../recommendations/recommendation_providers.dart';
import '../settings/settings_providers.dart';
import '../transactions/data/transaction_models.dart';
import '../transactions/transaction_providers.dart';
import 'utils/category_icons.dart';

enum _Tab { expense, income }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _Tab _tab = _Tab.expense;
  int _monthOffset = 0;

  DateTime get _selectedMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset, 1);
  }

  DateTime get _prevMonth {
    final m = _selectedMonth;
    return DateTime(m.year, m.month - 1, 1);
  }

  DateTime get _nextMonth {
    final m = _selectedMonth;
    return DateTime(m.year, m.month + 1, 1);
  }

  CategoryType get _typeForTab =>
      _tab == _Tab.expense ? CategoryType.expense : CategoryType.income;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final recommendationsAsync = ref.watch(visibleRecommendationsProvider);
    final symbol = ref.watch(currencyProvider).symbol;
    final auth = ref.watch(authControllerProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(categoriesProvider);
        ref.invalidate(transactionsProvider);
        ref.invalidate(recommendationsProvider);
        await Future.wait([
          ref.read(categoriesProvider.future),
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
              sliver: SliverToBoxAdapter(
                child: _Header(username: auth.username),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildBody(
                categoriesAsync,
                transactionsAsync,
                recommendationsAsync,
                symbol,
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

  Widget _buildBody(
    AsyncValue<List<Category>> categoriesAsync,
    AsyncValue<List<TransactionItem>> transactionsAsync,
    AsyncValue<List<Recommendation>> recommendationsAsync,
    String symbol,
  ) {
    return categoriesAsync.when(
      loading: _loadingState,
      error: (e, _) => _errorState(e.toString()),
      data: (categories) => transactionsAsync.when(
        loading: _loadingState,
        error: (e, _) => _errorState(e.toString()),
        data: (transactions) =>
            _content(categories, transactions, recommendationsAsync, symbol),
      ),
    );
  }

  Widget _loadingState() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );

  Widget _errorState(String message) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Не удалось загрузить: $message',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.coral),
          ),
        ),
      );

  Widget _content(
    List<Category> categories,
    List<TransactionItem> transactions,
    AsyncValue<List<Recommendation>> recommendationsAsync,
    String symbol,
  ) {
    final monthStart = _selectedMonth;
    final monthEnd = _nextMonth;
    final prevStart = _prevMonth;
    final prevEnd = monthStart;

    bool inRange(TransactionItem t, DateTime s, DateTime e) =>
        !t.operationDate.isBefore(s) && t.operationDate.isBefore(e);

    final currentTypeTxs = transactions
        .where((t) => t.category?.type == _typeForTab)
        .toList();

    final monthTxs =
        currentTypeTxs.where((t) => inRange(t, monthStart, monthEnd)).toList();
    final prevTxs =
        currentTypeTxs.where((t) => inRange(t, prevStart, prevEnd)).toList();

    final totalThis = monthTxs.fold<double>(0, (s, t) => s + t.amount);
    final totalPrev = prevTxs.fold<double>(0, (s, t) => s + t.amount);

    final sumByCat = <String, double>{};
    for (final t in monthTxs) {
      final id = t.category?.id;
      if (id != null) sumByCat[id] = (sumByCat[id] ?? 0) + t.amount;
    }
    final prevSumByCat = <String, double>{};
    for (final t in prevTxs) {
      final id = t.category?.id;
      if (id != null) prevSumByCat[id] = (prevSumByCat[id] ?? 0) + t.amount;
    }

    final visibleCategories =
        categories.where((c) => c.type == _typeForTab).toList()
          ..sort((a, b) {
            final sa = sumByCat[a.id] ?? 0;
            final sb = sumByCat[b.id] ?? 0;
            if (sa == sb) return a.name.compareTo(b.name);
            return sb.compareTo(sa);
          });

    final delta = _percentChange(totalThis, totalPrev);

    final monthLabel = _capitalize(
      DateFormat('LLLL yyyy', 'ru').format(monthStart),
    );
    final prevMonthLabel = _monthDative(prevStart.month);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _HeroCard(
              tab: _tab,
              total: totalThis,
              symbol: symbol,
              monthLabel: monthLabel,
              delta: delta,
              prevMonthLabel: prevMonthLabel,
              txCount: monthTxs.length,
              budget: ref.watch(monthlyBudgetProvider),
              onPrev: () => setState(() => _monthOffset -= 1),
              onNext: () => setState(() => _monthOffset += 1),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _TabSwitch(
              value: _tab,
              onChanged: (v) => setState(() => _tab = v),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _CategoryListCard(
              categories: visibleCategories,
              sumByCat: sumByCat,
              prevSumByCat: prevSumByCat,
              total: totalThis,
              symbol: symbol,
              tab: _tab,
            ),
          ),
          const SizedBox(height: 16),
          recommendationsAsync.maybeWhen(
            data: (list) => list.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                    child: _AiInsightCard(
                      recommendation: list.first,
                      index: 1,
                      total: list.length,
                      symbol: symbol,
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: _HistorySection(
              transactions: monthTxs,
              symbol: symbol,
              tab: _tab,
            ),
          ),
        ],
      ),
    );
  }

  double? _percentChange(double current, double previous) {
    if (previous == 0 && current == 0) return null;
    if (previous == 0) return current > 0 ? 100 : null;
    return ((current - previous) / previous) * 100;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static const _monthsDative = [
    'январю',
    'февралю',
    'марту',
    'апрелю',
    'маю',
    'июню',
    'июлю',
    'августу',
    'сентябрю',
    'октябрю',
    'ноябрю',
    'декабрю',
  ];

  String _monthDative(int month) => _monthsDative[(month - 1) % 12];
}

// ───────────────────────── HEADER ──────────────────────────

class _Header extends ConsumerWidget {
  final String? username;
  const _Header({required this.username});

  String _initials(String? username) {
    if (username == null || username.isEmpty) return '·';
    final parts = username.trim().split(RegExp(r'[\s@._-]+'));
    final letters = parts.where((p) => p.isNotEmpty).take(2).map(
          (p) => p[0].toUpperCase(),
        );
    return letters.join();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return 'Доброй ночи';
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = _initials(username);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: AppRadius.rMd,
              border: Border.all(color: AppColors.accentHair),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  (username == null || username!.isEmpty) ? 'Гость' : username!,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _IconChip(
            icon: Icons.notifications_outlined,
            onTap: () {},
          ),
          const SizedBox(width: 6),
          _IconChip(
            icon: Icons.logout,
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconChip({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rMd,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rMd,
            border: Border.all(color: AppColors.hairline),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.textMid),
        ),
      ),
    );
  }
}

// ───────────────────────── HERO ────────────────────────────

class _HeroCard extends StatelessWidget {
  final _Tab tab;
  final double total;
  final String symbol;
  final String monthLabel;
  final double? delta;
  final String prevMonthLabel;
  final int txCount;
  final double budget;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _HeroCard({
    required this.tab,
    required this.total,
    required this.symbol,
    required this.monthLabel,
    required this.delta,
    required this.prevMonthLabel,
    required this.txCount,
    required this.budget,
    required this.onPrev,
    required this.onNext,
  });

  bool get _isExpense => tab == _Tab.expense;

  Color get _deltaColor {
    if (delta == null) return AppColors.textMid;
    final goingDown = delta! < 0;
    // For expenses, going down is good (mint). For income, going up is good.
    final good = _isExpense ? goingDown : !goingDown;
    return good ? AppColors.mint : AppColors.coral;
  }

  String get _label =>
      _isExpense ? 'Расход за месяц' : 'Доход за месяц';

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      variant: GlowCardVariant.hero,
      padding: AppSpacing.heroPadding,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _label.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _MonthChip(
                    label: monthLabel,
                    onPrev: onPrev,
                    onNext: onNext,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _BigAmount(value: total, symbol: symbol),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (delta != null) ...[
                    _DeltaPill(
                      delta: delta!,
                      color: _deltaColor,
                      prevMonthLabel: prevMonthLabel,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '·',
                      style: TextStyle(color: AppColors.textFaint),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _operationsLabel(txCount),
                    style: const TextStyle(
                      color: AppColors.textMid,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (_isExpense) ...[
                const SizedBox(height: 18),
                _BudgetBar(
                  spent: total,
                  budget: budget,
                  monthLabel: monthLabel,
                  symbol: symbol,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _operationsLabel(int count) {
    if (count == 0) return 'нет операций';
    final last = count % 10;
    final lastTwo = count % 100;
    String word;
    if (lastTwo >= 11 && lastTwo <= 14) {
      word = 'операций';
    } else if (last == 1) {
      word = 'операция';
    } else if (last >= 2 && last <= 4) {
      word = 'операции';
    } else {
      word = 'операций';
    }
    return '$count $word';
  }
}

class _MonthChip extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthChip({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgSunken,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ArrowBtn(icon: Icons.chevron_left, onTap: onPrev),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 90),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          _ArrowBtn(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rXs,
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(icon, size: 16, color: AppColors.textMid),
        ),
      ),
    );
  }
}

class _BigAmount extends StatelessWidget {
  final double value;
  final String symbol;

  const _BigAmount({required this.value, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final whole = formatMoney(value, symbol: '').trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            whole,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.text,
                ),
            overflow: TextOverflow.fade,
            softWrap: false,
          ),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            symbol,
            style: const TextStyle(
              color: AppColors.textMid,
              fontSize: 22,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeltaPill extends StatelessWidget {
  final double delta;
  final Color color;
  final String prevMonthLabel;

  const _DeltaPill({
    required this.delta,
    required this.color,
    required this.prevMonthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final goingUp = delta >= 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          goingUp ? Icons.arrow_upward : Icons.arrow_downward,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '${delta.abs().toStringAsFixed(0)}% к $prevMonthLabel',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
}

class _BudgetBar extends StatelessWidget {
  final double spent;
  final double budget;
  final String monthLabel;
  final String symbol;

  const _BudgetBar({
    required this.spent,
    required this.budget,
    required this.monthLabel,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final pct = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                const ColoredBox(color: AppColors.bgSunken),
                FractionallySizedBox(
                  widthFactor: pct.toDouble(),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent, AppColors.accentBright],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(99)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGlow,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Бюджет на ${monthLabel.split(' ').first.toLowerCase()}',
              style: const TextStyle(color: AppColors.textDim, fontSize: 11),
            ),
            const Spacer(),
            Text(
              '${formatMoney(spent, symbol: '')} / ${formatMoney(budget, symbol: symbol)}',
              style: const TextStyle(color: AppColors.textMid, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────── TAB SWITCH ────────────────────────

class _TabSwitch extends StatelessWidget {
  final _Tab value;
  final ValueChanged<_Tab> onChanged;

  const _TabSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgSunken,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabBtn(
              label: 'Расходы',
              active: value == _Tab.expense,
              onTap: () => onChanged(_Tab.expense),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabBtn(
              label: 'Доходы',
              active: value == _Tab.income,
              onTap: () => onChanged(_Tab.income),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.bgRaised : Colors.transparent,
      borderRadius: AppRadius.rSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rSm,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rSm,
            border: Border.all(
              color: active ? AppColors.accentHair : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w500 : FontWeight.w400,
              color: active ? AppColors.text : AppColors.textDim,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── CATEGORY LIST CARD ────────────────────

class _CategoryListCard extends StatelessWidget {
  final List<Category> categories;
  final Map<String, double> sumByCat;
  final Map<String, double> prevSumByCat;
  final double total;
  final String symbol;
  final _Tab tab;

  const _CategoryListCard({
    required this.categories,
    required this.sumByCat,
    required this.prevSumByCat,
    required this.total,
    required this.symbol,
    required this.tab,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: const [
              Text(
                'КАТЕГОРИИ',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 12,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        GlowCard(
          variant: GlowCardVariant.card,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: AppRadius.rCard,
            child: categories.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Категорий пока нет.',
                        style: TextStyle(color: AppColors.textDim),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(categories.length, (i) {
                      final c = categories[i];
                      final amount = sumByCat[c.id] ?? 0;
                      final prev = prevSumByCat[c.id] ?? 0;
                      final share = total > 0 ? amount / total : 0.0;
                      final delta = _percentChange(amount, prev);
                      return Column(
                        children: [
                          _CategoryRow(
                            category: c,
                            amount: amount,
                            sharePct: share,
                            delta: delta,
                            symbol: symbol,
                            tab: tab,
                          ),
                          if (i < categories.length - 1)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.hairlineSoft,
                            ),
                        ],
                      );
                    }),
                  ),
          ),
        ),
      ],
    );
  }

  double? _percentChange(double current, double previous) {
    if (previous == 0 && current == 0) return null;
    if (previous == 0) return null;
    return ((current - previous) / previous) * 100;
  }
}

class _CategoryRow extends StatelessWidget {
  final Category category;
  final double amount;
  final double sharePct;
  final double? delta;
  final String symbol;
  final _Tab tab;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.sharePct,
    required this.delta,
    required this.symbol,
    required this.tab,
  });

  @override
  Widget build(BuildContext context) {
    final empty = amount == 0;
    final pct = (sharePct * 100).round();
    final deltaGood = delta != null &&
        (tab == _Tab.expense ? delta! < 0 : delta! >= 0);
    final deltaColor = delta == null
        ? AppColors.textFaint
        : (deltaGood ? AppColors.mint : AppColors.coral);

    return Opacity(
      opacity: empty ? 0.55 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.bgSunken,
                borderRadius: AppRadius.rMd,
                border: Border.all(color: AppColors.hairline),
              ),
              alignment: Alignment.center,
              child: Icon(
                iconForCategory(category.name),
                size: 20,
                color: empty ? AppColors.textDim : AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                empty ? AppColors.textMid : AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatMoney(amount, symbol: symbol),
                        style: TextStyle(
                          color:
                              empty ? AppColors.textDim : AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: SizedBox(
                            height: 3,
                            child: Stack(
                              children: [
                                const ColoredBox(color: AppColors.bgSunken),
                                FractionallySizedBox(
                                  widthFactor: sharePct.clamp(0.0, 1.0),
                                  child: Container(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (empty)
                        const Text(
                          '—',
                          style: TextStyle(
                            color: AppColors.textFaint,
                            fontSize: 11,
                          ),
                        )
                      else
                        Row(
                          children: [
                            Text(
                              '$pct%',
                              style: const TextStyle(
                                color: AppColors.textDim,
                                fontSize: 11,
                              ),
                            ),
                            if (delta != null) ...[
                              const SizedBox(width: 6),
                              Icon(
                                delta! >= 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 11,
                                color: deltaColor,
                              ),
                              Text(
                                '${delta!.abs().toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: deltaColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(
                  '/transactions/new?categoryId=${category.id}',
                ),
                borderRadius: AppRadius.rSm,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.rSm,
                    border: Border.all(color: AppColors.hairline),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add,
                    size: 14,
                    color: AppColors.textMid,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── AI INSIGHT ────────────────────────

class _AiInsightCard extends StatelessWidget {
  final Recommendation recommendation;
  final int index;
  final int total;
  final String symbol;

  const _AiInsightCard({
    required this.recommendation,
    required this.index,
    required this.total,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final savings = recommendation.savingsEstimate;
    return GlowCard(
      variant: GlowCardVariant.hero,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: AppRadius.rSm,
                  border: Border.all(color: AppColors.accentHair),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome,
                  size: 15,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI · СОВЕТ ПО ЭКОНОМИИ',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '$index / $total',
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            recommendation.title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          if (recommendation.message.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              localizeCurrency(recommendation.message, symbol),
              style: const TextStyle(
                color: AppColors.textMid,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
          if (savings != null && savings > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mintSoft,
                borderRadius: AppRadius.rSm,
                border: Border.all(color: AppColors.mintHair),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.savings_outlined,
                    size: 14,
                    color: AppColors.mint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Возможная экономия: ${formatMoney(savings, symbol: symbol)}',
                    style: const TextStyle(
                      color: AppColors.mint,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => context.go('/recommendations'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMid,
                  side: const BorderSide(color: AppColors.hairline),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.rSm,
                  ),
                ),
                child: const Text(
                  'Все советы',
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── HISTORY ─────────────────────────

class _HistorySection extends StatelessWidget {
  final List<TransactionItem> transactions;
  final String symbol;
  final _Tab tab;

  const _HistorySection({
    required this.transactions,
    required this.symbol,
    required this.tab,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...transactions]
      ..sort((a, b) => b.operationDate.compareTo(a.operationDate));

    final groups = <DateTime, List<TransactionItem>>{};
    for (final t in sorted) {
      final d = DateTime(
        t.operationDate.year,
        t.operationDate.month,
        t.operationDate.day,
      );
      groups.putIfAbsent(d, () => []).add(t);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            'ИСТОРИЯ',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 12,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (days.isEmpty)
          GlowCard(
            variant: GlowCardVariant.card,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            child: const Center(
              child: Text(
                'Пока нет операций в этом месяце.',
                style: TextStyle(color: AppColors.textDim, fontSize: 13),
              ),
            ),
          )
        else
          ...List.generate(days.length, (i) {
            final day = days[i];
            final items = groups[day]!;
            final daySum = items.fold<double>(0, (s, t) => s + t.amount);
            return Padding(
              padding: EdgeInsets.only(bottom: i == days.length - 1 ? 0 : 10),
              child: _DayGroupCard(
                day: day,
                items: items,
                daySum: daySum,
                symbol: symbol,
                tab: tab,
              ),
            );
          }),
      ],
    );
  }
}

class _DayGroupCard extends StatelessWidget {
  final DateTime day;
  final List<TransactionItem> items;
  final double daySum;
  final String symbol;
  final _Tab tab;

  const _DayGroupCard({
    required this.day,
    required this.items,
    required this.daySum,
    required this.symbol,
    required this.tab,
  });

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (d == today) return 'Сегодня';
    if (d == yesterday) return 'Вчера';
    return DateFormat('d MMMM', 'ru').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      variant: GlowCardVariant.card,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.rCard,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dayLabel(day),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    formatMoney(daySum, symbol: symbol),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.hairlineSoft,
            ),
            ...List.generate(items.length, (i) {
              final t = items[i];
              return Column(
                children: [
                  _TxRow(item: t, symbol: symbol, tab: tab),
                  if (i < items.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.hairlineSoft,
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final TransactionItem item;
  final String symbol;
  final _Tab tab;

  const _TxRow({
    required this.item,
    required this.symbol,
    required this.tab,
  });

  @override
  Widget build(BuildContext context) {
    final categoryName = item.category?.name ?? '—';
    final description = item.description;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgSunken,
              borderRadius: AppRadius.rMd,
              border: Border.all(color: AppColors.hairline),
            ),
            alignment: Alignment.center,
            child: Icon(
              iconForCategory(categoryName),
              size: 18,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatMoney(item.amount, symbol: symbol),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

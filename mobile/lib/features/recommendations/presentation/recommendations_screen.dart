import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/format.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../widgets/glow_card.dart';
import '../../settings/settings_providers.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/transaction_providers.dart';
import '../data/recommendation_models.dart';
import '../recommendation_providers.dart';

enum _Filter { all, tip, forecast, anomaly }

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState
    extends ConsumerState<RecommendationsScreen> {
  _Filter _filter = _Filter.all;
  bool _regenerating = false;

  Future<void> _refresh() async {
    if (_regenerating) return;
    setState(() => _regenerating = true);
    try {
      await ref.read(recommendationApiProvider).refresh();
      ref.invalidate(recommendationsProvider);
      ref.invalidate(mlHealthProvider);
    } on DioException catch (e) {
      final msg = e.error is ApiException
          ? (e.error as ApiException).message
          : 'Не удалось обновить рекомендации';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  Future<void> _dismiss(String id) async {
    try {
      await ref.read(recommendationApiProvider).dismiss(id);
      ref.invalidate(recommendationsProvider);
    } on DioException catch (e) {
      final msg = e.error is ApiException
          ? (e.error as ApiException).message
          : 'Не удалось скрыть рекомендацию';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recsAsync = ref.watch(visibleRecommendationsProvider);
    final health = ref.watch(mlHealthProvider);
    final symbol = ref.watch(currencyProvider).symbol;
    final transactions = ref.watch(transactionsProvider).maybeWhen(
          data: (list) => list,
          orElse: () => const <TransactionItem>[],
        );

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.bgRaised,
          onRefresh: () async {
            ref.invalidate(recommendationsProvider);
            ref.invalidate(mlHealthProvider);
            await ref.read(recommendationsProvider.future);
          },
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    health: health,
                    refreshing: _regenerating,
                    onRefresh: _refresh,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildContent(recsAsync, symbol, transactions),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: kBottomNavReservedSpace),
                ),
              ],
            ),
          ),
        ),
        if (_regenerating) const _RecalcOverlay(),
      ],
    );
  }

  Widget _buildContent(
    AsyncValue<List<Recommendation>> async,
    String symbol,
    List<TransactionItem> transactions,
  ) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.coral,
            ),
            const SizedBox(height: 12),
            Text(
              'Ошибка: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.coral),
            ),
          ],
        ),
      ),
      data: (items) {
        final counts = {
          _Filter.all: items.length,
          _Filter.tip:
              items.where((r) => r.type == RecommendationType.savingsTip).length,
          _Filter.forecast: items
              .where((r) => r.type == RecommendationType.trendForecast)
              .length,
          _Filter.anomaly:
              items.where((r) => r.type == RecommendationType.anomaly).length,
        };

        final filtered = items.where((r) {
          switch (_filter) {
            case _Filter.all:
              return true;
            case _Filter.tip:
              return r.type == RecommendationType.savingsTip;
            case _Filter.forecast:
              return r.type == RecommendationType.trendForecast;
            case _Filter.anomaly:
              return r.type == RecommendationType.anomaly;
          }
        }).toList();

        final totalSavings = items
            .where((r) => r.type == RecommendationType.savingsTip)
            .fold<double>(0, (s, r) => s + (r.savingsEstimate ?? 0));
        final tipCount = counts[_Filter.tip] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: _SavingsHero(
                  totalSavings: totalSavings,
                  tipCount: tipCount,
                  symbol: symbol,
                ),
              ),
              const SizedBox(height: 10),
              _FilterChips(
                value: _filter,
                onChanged: (v) => setState(() => _filter = v),
                counts: counts,
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                _EmptyState(filter: _filter)
              else
                Column(
                  key: ValueKey(_filter),
                  children: List.generate(filtered.length, (i) {
                    final r = filtered[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        0,
                        AppSpacing.screen,
                        10,
                      ),
                      child: _FadeSlideIn(
                        delayMs: i * 55,
                        child: _RecCard(
                          recommendation: r,
                          symbol: symbol,
                          transactions: transactions,
                          onDismiss: () => _dismiss(r.id),
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────── HEADER ────────────────────────────

class _Header extends StatelessWidget {
  final AsyncValue<bool> health;
  final bool refreshing;
  final VoidCallback onRefresh;

  const _Header({
    required this.health,
    required this.refreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final healthy = health.maybeWhen(data: (up) => up, orElse: () => null);
    final connColor = healthy == null
        ? AppColors.textDim
        : (healthy ? AppColors.mint : AppColors.coral);
    final connLabel = healthy == null
        ? 'проверка…'
        : (healthy ? 'на связи' : 'недоступен');

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 8, AppSpacing.screen, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI · ML-СЕРВИС',
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10.5,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    const Text(
                      'Рекомендации',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PulsingDot(color: connColor),
                    const SizedBox(width: 4),
                    Text(
                      connLabel,
                      style: TextStyle(
                        color: connColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _RefreshBtn(spinning: refreshing, onTap: onRefresh),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = (1 - (_ctrl.value - 0.5).abs() * 2).clamp(0.4, 1.0);
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6 * t),
                blurRadius: 6 * t,
                spreadRadius: 0.5,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RefreshBtn extends StatelessWidget {
  final bool spinning;
  final VoidCallback onTap;

  const _RefreshBtn({required this.spinning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentSoft,
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: spinning ? null : onTap,
        borderRadius: AppRadius.rMd,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rMd,
            border: Border.all(color: AppColors.accentHair),
          ),
          alignment: Alignment.center,
          child: spinning
              ? const _SpinningIcon(icon: Icons.refresh, color: AppColors.accent)
              : const Icon(
                  Icons.refresh,
                  size: 16,
                  color: AppColors.accent,
                ),
        ),
      ),
    );
  }
}

class _SpinningIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _SpinningIcon({
    required this.icon,
    required this.color,
    this.size = 16,
  });

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}

// ──────────────────────── SAVINGS HERO ──────────────────────────

class _SavingsHero extends StatelessWidget {
  final double totalSavings;
  final int tipCount;
  final String symbol;

  const _SavingsHero({
    required this.totalSavings,
    required this.tipCount,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      variant: GlowCardVariant.hero,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -50,
            right: -50,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ВОЗМОЖНАЯ ЭКОНОМИЯ',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            formatMoney(totalSavings, symbol: ''),
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.8,
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
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tipCount == 0
                          ? 'нет активных советов'
                          : 'по ${_tipsLabel(tipCount)} · за 3 месяца',
                      style: const TextStyle(
                        color: AppColors.textMid,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentHair),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome,
                  size: 22,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _tipsLabel(int count) {
    final last = count % 10;
    final lastTwo = count % 100;
    String word;
    if (lastTwo >= 11 && lastTwo <= 14) {
      word = 'советам';
    } else if (last == 1) {
      word = 'совету';
    } else if (last >= 2 && last <= 4) {
      word = 'советам';
    } else {
      word = 'советам';
    }
    return '$count $word';
  }
}

// ──────────────────────── FILTER CHIPS ──────────────────────────

class _FilterChips extends StatelessWidget {
  final _Filter value;
  final ValueChanged<_Filter> onChanged;
  final Map<_Filter, int> counts;

  const _FilterChips({
    required this.value,
    required this.onChanged,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final entries = <(_Filter, String, IconData)>[
      (_Filter.all, 'Все', Icons.list),
      (_Filter.tip, 'Советы', Icons.lightbulb_outline),
      (_Filter.forecast, 'Прогнозы', Icons.trending_up),
      (_Filter.anomaly, 'Аномалии', Icons.warning_amber_outlined),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Row(
        children: [
          for (final (filter, label, icon) in entries) ...[
            _FilterChip(
              label: label,
              icon: icon,
              count: counts[filter] ?? 0,
              active: filter == value,
              onTap: () => onChanged(filter),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.accentSoft : AppColors.bgRaised,
      borderRadius: AppRadius.rPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rPill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rPill,
            border: Border.all(
              color: active ? AppColors.accent : AppColors.hairline,
            ),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: AppColors.accentGlow,
                      blurRadius: 18,
                      spreadRadius: -10,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: active ? AppColors.accent : AppColors.textMid,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.text : AppColors.textMid,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    color: active ? AppColors.accent : AppColors.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── STAGGERED FADE ─────────────────────────

class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _FadeSlideIn({required this.child, this.delayMs = 0});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

// ───────────────────────── REC CARD ─────────────────────────────

class _RecTypeTheme {
  final Color color;
  final Color soft;
  final Color hair;
  final IconData icon;
  final String label;

  const _RecTypeTheme({
    required this.color,
    required this.soft,
    required this.hair,
    required this.icon,
    required this.label,
  });
}

_RecTypeTheme _themeFor(RecommendationType t) {
  switch (t) {
    case RecommendationType.savingsTip:
      return const _RecTypeTheme(
        color: AppColors.mint,
        soft: AppColors.mintSoft,
        hair: AppColors.mintHair,
        icon: Icons.lightbulb_outline,
        label: 'Совет по экономии',
      );
    case RecommendationType.trendForecast:
      return const _RecTypeTheme(
        color: AppColors.accent,
        soft: AppColors.accentSoft,
        hair: AppColors.accentHair,
        icon: Icons.trending_up,
        label: 'Прогноз тренда',
      );
    case RecommendationType.anomaly:
      return const _RecTypeTheme(
        color: AppColors.coral,
        soft: AppColors.coralSoft,
        hair: AppColors.coralHair,
        icon: Icons.warning_amber_outlined,
        label: 'Аномалия',
      );
    case RecommendationType.unknown:
      return const _RecTypeTheme(
        color: AppColors.textMid,
        soft: AppColors.hairline,
        hair: AppColors.hairline,
        icon: Icons.info_outline,
        label: 'Рекомендация',
      );
  }
}

class _RecCard extends StatelessWidget {
  final Recommendation recommendation;
  final String symbol;
  final List<TransactionItem> transactions;
  final VoidCallback onDismiss;

  const _RecCard({
    required this.recommendation,
    required this.symbol,
    required this.transactions,
    required this.onDismiss,
  });

  Map<String, dynamic>? _parseMeta() {
    final m = recommendation.metadata;
    if (m == null || m.isEmpty) return null;
    try {
      final decoded = jsonDecode(m);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  List<double> _forecastTrend() {
    final catId = recommendation.relatedCategoryId;
    if (catId == null) return const [];
    final now = DateTime.now();
    final months = <DateTime>[
      for (var i = 3; i >= 0; i--) DateTime(now.year, now.month - i, 1),
    ];
    final sums = List<double>.filled(months.length, 0);
    for (final t in transactions) {
      if (t.category?.id != catId) continue;
      for (var i = 0; i < months.length; i++) {
        final end = (i + 1 < months.length)
            ? months[i + 1]
            : DateTime(now.year, now.month + 1, 1);
        if (!t.operationDate.isBefore(months[i]) &&
            t.operationDate.isBefore(end)) {
          sums[i] += t.amount;
          break;
        }
      }
    }
    final nonZero = sums.where((v) => v > 0).length;
    if (nonZero < 2) return const [];
    return sums;
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themeFor(recommendation.type);
    final meta = _parseMeta();
    final savings = recommendation.savingsEstimate;
    final isForecast = recommendation.type == RecommendationType.trendForecast;
    final isAnomaly = recommendation.type == RecommendationType.anomaly;
    final isTip = recommendation.type == RecommendationType.savingsTip;
    final trend = isForecast ? _forecastTrend() : const <double>[];

    return GlowCard(
      variant: GlowCardVariant.card,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      border: Border.all(color: theme.hair),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.soft,
                    borderRadius: AppRadius.rMd,
                    border: Border.all(color: theme.hair),
                  ),
                  alignment: Alignment.center,
                  child: Icon(theme.icon, size: 18, color: theme.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LabelLine(theme: theme, generated: recommendation.generatedDate),
                      const SizedBox(height: 4),
                      Text(
                        recommendation.title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      if (recommendation.message.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          localizeCurrency(recommendation.message, symbol),
                          style: const TextStyle(
                            color: AppColors.textMid,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (isTip && savings != null && savings > 0) ...[
                        const SizedBox(height: 10),
                        _SavingsPill(amount: savings, symbol: symbol, theme: theme),
                      ],
                      if (isForecast && trend.length >= 2) ...[
                        const SizedBox(height: 10),
                        _TrendMini(
                          history: trend,
                          forecast: meta?['forecast'] is num
                              ? (meta!['forecast'] as num).toDouble()
                              : trend.last,
                          color: theme.color,
                          symbol: symbol,
                        ),
                      ],
                      if (isAnomaly && meta != null) _AnomalyStrip(
                        meta: meta,
                        symbol: symbol,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDismiss,
                borderRadius: AppRadius.rXs,
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.textFaint,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelLine extends StatelessWidget {
  final _RecTypeTheme theme;
  final DateTime generated;

  const _LabelLine({required this.theme, required this.generated});

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('d MMM · HH:mm', 'ru').format(generated);
    return Row(
      children: [
        Flexible(
          child: Text(
            theme.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.color,
              fontSize: 10.5,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.access_time, size: 10, color: AppColors.textFaint),
        const SizedBox(width: 3),
        Text(
          when,
          style: const TextStyle(
            color: AppColors.textFaint,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _SavingsPill extends StatelessWidget {
  final double amount;
  final String symbol;
  final _RecTypeTheme theme;

  const _SavingsPill({
    required this.amount,
    required this.symbol,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.soft,
        borderRadius: AppRadius.rSm,
        border: Border.all(color: theme.hair),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.savings_outlined, size: 14, color: theme.color),
          const SizedBox(width: 6),
          Text(
            '${formatMoney(amount, symbol: symbol)} · за 3 месяца',
            style: TextStyle(
              color: theme.color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendMini extends StatelessWidget {
  final List<double> history;
  final double forecast;
  final Color color;
  final String symbol;

  const _TrendMini({
    required this.history,
    required this.forecast,
    required this.color,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgSunken,
        borderRadius: AppRadius.rSm,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 88,
            height: 28,
            child: CustomPaint(
              painter: _MiniTrendPainter(
                history: history,
                forecast: forecast,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Прогноз',
                style: TextStyle(color: AppColors.textDim, fontSize: 10),
              ),
              Text(
                formatMoney(forecast, symbol: symbol),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTrendPainter extends CustomPainter {
  final List<double> history;
  final double forecast;
  final Color color;

  _MiniTrendPainter({
    required this.history,
    required this.forecast,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final all = [...history, forecast];
    final maxV = all.reduce((a, b) => a > b ? a : b);
    final minV = all.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);
    final w = size.width;
    final h = size.height;
    final step = w / (all.length - 1);

    Offset pt(int i) {
      final y = h - ((all[i] - minV) / range) * (h - 4) - 2;
      return Offset(i * step, y);
    }

    final pastPaint = Paint()
      ..color = AppColors.textMid
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pastPath = Path()..moveTo(0, pt(0).dy);
    for (var i = 1; i < history.length; i++) {
      pastPath.lineTo(pt(i).dx, pt(i).dy);
    }
    canvas.drawPath(pastPath, pastPaint);

    final futurePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final from = pt(history.length - 1);
    final to = pt(all.length - 1);
    _drawDashedLine(canvas, from, to, futurePaint, 3, 3);

    canvas.drawCircle(to, 2.5, Paint()..color = color);
  }

  void _drawDashedLine(Canvas c, Offset a, Offset b, Paint p, double dash, double gap) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length <= 0) return;
    final ux = dx / length;
    final uy = dy / length;
    var travelled = 0.0;
    while (travelled < length) {
      final segEnd = math.min(travelled + dash, length);
      c.drawLine(
        Offset(a.dx + ux * travelled, a.dy + uy * travelled),
        Offset(a.dx + ux * segEnd, a.dy + uy * segEnd),
        p,
      );
      travelled = segEnd + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter old) =>
      old.history != history || old.forecast != forecast || old.color != color;
}

class _AnomalyStrip extends StatelessWidget {
  final Map<String, dynamic> meta;
  final String symbol;
  final _RecTypeTheme theme;

  const _AnomalyStrip({
    required this.meta,
    required this.symbol,
    required this.theme,
  });

  double? _num(String key) {
    final v = meta[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final amount = _num('amount') ?? _num('value');
    final avg = _num('average') ?? _num('avg');
    final multiple = _num('multiple') ?? _num('ratio');

    if (amount == null && avg == null && multiple == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgSunken,
          borderRadius: AppRadius.rSm,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          children: [
            if (amount != null)
              Expanded(
                child: _MetricCell(
                  label: 'сумма',
                  value: formatMoney(amount, symbol: symbol),
                  color: theme.color,
                  bold: true,
                ),
              ),
            if (avg != null)
              Expanded(
                child: _MetricCell(
                  label: 'в среднем',
                  value: formatMoney(avg, symbol: symbol),
                  color: AppColors.text,
                ),
              ),
            if (multiple != null)
              Expanded(
                child: _MetricCell(
                  label: 'превышение',
                  value: '×${multiple.toStringAsFixed(1).replaceAll('.', ',')}',
                  color: theme.color,
                  bold: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _MetricCell({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textDim, fontSize: 10.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── EMPTY STATE ──────────────────────────

class _EmptyState extends StatelessWidget {
  final _Filter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final body = filter == _Filter.all
        ? 'ML-сервис пока не нашёл рекомендаций. Создайте больше транзакций или потяните экран вниз, чтобы пересчитать.'
        : 'В этой категории сейчас нет рекомендаций.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 16, AppSpacing.screen, 0),
      child: GlowCard(
        variant: GlowCardVariant.card,
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accentHair),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_circle_outline,
                size: 22,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Здесь пока пусто',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMid,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────── RECALC OVERLAY ──────────────────────────

class _RecalcOverlay extends StatelessWidget {
  const _RecalcOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.bg.withValues(alpha: 0.55),
        child: Center(
          child: GlowCard(
            variant: GlowCardVariant.hero,
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accentHair),
                  ),
                  alignment: Alignment.center,
                  child: const _SpinningIcon(
                    icon: Icons.auto_awesome,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ML анализирует данные…',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Пересчитываем советы, прогнозы и аномалии',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMid,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

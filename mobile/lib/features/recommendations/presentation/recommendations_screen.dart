import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/format.dart';
import '../../settings/settings_providers.dart';
import '../data/recommendation_models.dart';
import '../recommendation_providers.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState
    extends ConsumerState<RecommendationsScreen> {
  bool _regenerating = false;

  Future<void> _regenerate() async {
    setState(() => _regenerating = true);
    try {
      await ref.read(recommendationApiProvider).refresh();
      ref.invalidate(recommendationsProvider);
    } on DioException catch (e) {
      final apiErr = e.error;
      final msg = apiErr is ApiException
          ? apiErr.message
          : 'Не удалось обновить рекомендации';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  Future<void> _dismiss(Recommendation r) async {
    try {
      await ref.read(recommendationApiProvider).dismiss(r.id);
      ref.invalidate(recommendationsProvider);
    } on DioException catch (e) {
      final apiErr = e.error;
      final msg = apiErr is ApiException
          ? apiErr.message
          : 'Не удалось скрыть рекомендацию';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recommendationsProvider);
    final health = ref.watch(mlHealthProvider);
    final symbol = ref.watch(currencyProvider).symbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Рекомендации'),
        actions: [
          IconButton(
            tooltip: 'Пересчитать',
            icon: _regenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            onPressed: _regenerating ? null : _regenerate,
          ),
        ],
      ),
      body: Column(
        children: [
          _HealthBanner(health: health),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(recommendationsProvider);
                ref.invalidate(mlHealthProvider);
                await ref.read(recommendationsProvider.future);
              },
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 60),
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка: $e',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                data: (items) => items.isEmpty
                    ? _EmptyState(onRegenerate: _regenerate)
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (context, index) => _RecommendationCard(
                          recommendation: items[index],
                          symbol: symbol,
                          onDismiss: () => _dismiss(items[index]),
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

class _HealthBanner extends StatelessWidget {
  final AsyncValue<bool> health;

  const _HealthBanner({required this.health});

  @override
  Widget build(BuildContext context) {
    return health.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.orange.withValues(alpha: 0.12),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, size: 18, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text('ML-сервис недоступен. Рекомендации могут устареть.'),
            ),
          ],
        ),
      ),
      data: (up) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: (up ? Colors.green : Colors.redAccent).withValues(alpha: 0.12),
        child: Row(
          children: [
            Icon(
              up ? Icons.check_circle : Icons.error_outline,
              size: 18,
              color: up ? Colors.green : Colors.redAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                up
                    ? 'ML-сервис на связи. Можно пересчитывать рекомендации.'
                    : 'ML-сервис недоступен. Запусти docker compose up -d ml-service.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRegenerate;

  const _EmptyState({required this.onRegenerate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.auto_awesome,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Пока нет рекомендаций',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Создай несколько транзакций (хотя бы за 2-3 месяца), затем нажми «Пересчитать» — ML-сервис проанализирует тренды, найдёт аномалии и предложит способы сэкономить.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            onPressed: onRegenerate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Пересчитать сейчас'),
          ),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final String symbol;
  final VoidCallback onDismiss;

  const _RecommendationCard({
    required this.recommendation,
    required this.symbol,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(recommendation.type);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: style.color.withValues(alpha: 0.15),
                  child: Icon(style.icon, color: style.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        style.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: style.color,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        recommendation.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Скрыть',
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(recommendation.message),
            if (recommendation.savingsEstimate != null &&
                recommendation.savingsEstimate! > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Возможная экономия: ${formatMoney(recommendation.savingsEstimate!, symbol: symbol)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Сгенерировано: ${DateFormat('d MMMM yyyy, HH:mm', 'ru').format(recommendation.generatedDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  _CardStyle _styleFor(RecommendationType type) {
    switch (type) {
      case RecommendationType.trendForecast:
        return const _CardStyle(
          icon: Icons.trending_up,
          color: Colors.orange,
          label: 'ПРОГНОЗ ТРЕНДА',
        );
      case RecommendationType.anomaly:
        return const _CardStyle(
          icon: Icons.warning_amber,
          color: Colors.redAccent,
          label: 'АНОМАЛИЯ',
        );
      case RecommendationType.savingsTip:
        return const _CardStyle(
          icon: Icons.lightbulb_outline,
          color: Colors.blue,
          label: 'СОВЕТ ПО ЭКОНОМИИ',
        );
      case RecommendationType.unknown:
        return const _CardStyle(
          icon: Icons.info_outline,
          color: Colors.grey,
          label: 'РЕКОМЕНДАЦИЯ',
        );
    }
  }
}

class _CardStyle {
  final IconData icon;
  final Color color;
  final String label;

  const _CardStyle({
    required this.icon,
    required this.color,
    required this.label,
  });
}

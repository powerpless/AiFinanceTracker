import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';
import '../categories/data/category_models.dart';
import 'category_summary_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  CategoryType get _currentType => _tabController.index == 0
      ? CategoryType.expense
      : CategoryType.income;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансы'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Расходы'),
            Tab(text: 'Доходы'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Дашборд',
            icon: const Icon(Icons.pie_chart_outline),
            onPressed: () => context.push('/dashboard'),
          ),
          IconButton(
            tooltip: 'Рекомендации',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => context.push('/recommendations'),
          ),
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            tooltip: 'Выйти',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CategorySummaryTab(type: CategoryType.expense),
          CategorySummaryTab(type: CategoryType.income),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
          '/transactions/new?type=${_currentType == CategoryType.expense ? 'EXPENSE' : 'INCOME'}',
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

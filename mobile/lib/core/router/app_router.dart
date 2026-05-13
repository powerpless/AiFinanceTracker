import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/categories/data/category_models.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/home/home_screen.dart';
import '../../features/recommendations/presentation/recommendations_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/transactions/presentation/transaction_form_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      final loggingIn = loc == '/login' || loc == '/register';

      if (auth.status == AuthStatus.unknown) return null;
      if (auth.status == AuthStatus.unauthenticated && !loggingIn) {
        return '/login';
      }
      if (auth.status == AuthStatus.authenticated && loggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['categoryId'];
          final typeParam = state.uri.queryParameters['type'];
          CategoryType? initialType;
          if (typeParam == 'INCOME') initialType = CategoryType.income;
          if (typeParam == 'EXPENSE') initialType = CategoryType.expense;
          return TransactionFormScreen(
            initialCategoryId: categoryId,
            initialType: initialType,
          );
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/recommendations',
        builder: (context, state) => const RecommendationsScreen(),
      ),
    ],
  );
});

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthState>(
      authControllerProvider,
      (prev, next) => notifyListeners(),
    );
  }
}

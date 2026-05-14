import 'package:flutter/material.dart';

/// Maps a category name (Russian) to a Material icon that visually echoes the
/// Phosphor icon chosen in the design source. Returns a generic fallback for
/// any unmapped category.
IconData iconForCategory(String name) {
  final n = name.toLowerCase();

  // Expense categories
  if (n.contains('развлеч')) return Icons.celebration_outlined;
  if (n.contains('продукт') || n.contains('еда')) {
    return Icons.shopping_basket_outlined;
  }
  if (n.contains('транспорт')) return Icons.directions_bus_outlined;
  if (n.contains('жиль') || n.contains('аренда') || n.contains('квартир')) {
    return Icons.home_outlined;
  }
  if (n.contains('здоров') || n.contains('медиц')) {
    return Icons.favorite_outline;
  }
  if (n.contains('коммунал') || n.contains('жкх')) {
    return Icons.bolt_outlined;
  }
  if (n.contains('одежд')) return Icons.checkroom_outlined;
  if (n.contains('кафе') || n.contains('рестор')) {
    return Icons.restaurant_outlined;
  }
  if (n.contains('такси')) return Icons.local_taxi_outlined;
  if (n.contains('подпис') || n.contains('сервис')) {
    return Icons.subscriptions_outlined;
  }
  if (n.contains('связь') || n.contains('интернет')) {
    return Icons.wifi;
  }
  if (n.contains('образован') || n.contains('обучен')) {
    return Icons.menu_book_outlined;
  }
  if (n.contains('путеш')) return Icons.flight_takeoff_outlined;
  if (n.contains('подар')) return Icons.card_giftcard_outlined;
  if (n.contains('спорт')) return Icons.fitness_center_outlined;

  // Income categories
  if (n.contains('зарплат') || n.contains('заработ')) {
    return Icons.work_outline;
  }
  if (n.contains('бизнес')) return Icons.storefront_outlined;
  if (n.contains('процент') || n.contains('вклад') || n.contains('депозит')) {
    return Icons.percent;
  }
  if (n.contains('стипенд')) return Icons.school_outlined;
  if (n.contains('инвест')) return Icons.trending_up;
  if (n.contains('фриланс') || n.contains('подработ')) {
    return Icons.laptop_outlined;
  }
  if (n.contains('возврат') || n.contains('кэшбэк')) {
    return Icons.replay_outlined;
  }

  // Fallbacks for "прочие"/"иные"
  if (n.contains('прочи') || n.contains('иные') || n.contains('другое')) {
    return Icons.more_horiz_outlined;
  }

  return Icons.local_offer_outlined;
}

import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Vertical space the floating bottom nav reserves at the bottom of any
/// screen that scrolls beneath it. Includes the home-indicator inset.
const double kBottomNavReservedSpace = 130;

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onFabTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemTap,
    required this.onFabTap,
  });

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Главная'),
    _NavItem(
      icon: Icons.pie_chart_outline,
      activeIcon: Icons.pie_chart,
      label: 'Дашборд',
    ),
    _NavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'AI',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Настройки',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: SizedBox(
        height: kBottomNavReservedSpace,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Fade-to-bg gradient behind the bar so scrolled content fades out.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.bg.withValues(alpha: 0),
                        AppColors.bg,
                      ],
                      stops: const [0.0, 0.4],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 34),
              child: SizedBox(
                height: 64,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    _GlassBar(
                      currentIndex: currentIndex,
                      onItemTap: onItemTap,
                      items: _items,
                    ),
                    Positioned(
                      top: -28,
                      child: _Fab(onTap: onFabTap),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _GlassBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemTap;
  final List<_NavItem> items;

  const _GlassBar({
    required this.currentIndex,
    required this.onItemTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.rSheet,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bgRaised.withValues(alpha: 0.92),
            borderRadius: AppRadius.rSheet,
            border: Border.all(color: AppColors.hairline),
            boxShadow: AppShadows.bottomBar,
          ),
          child: Row(
            children: [
              _NavSlot(
                item: items[0],
                active: currentIndex == 0,
                onTap: () => onItemTap(0),
              ),
              _NavSlot(
                item: items[1],
                active: currentIndex == 1,
                onTap: () => onItemTap(1),
              ),
              const SizedBox(width: 88), // reserved for the FAB
              _NavSlot(
                item: items[2],
                active: currentIndex == 2,
                onTap: () => onItemTap(2),
              ),
              _NavSlot(
                item: items[3],
                active: currentIndex == 3,
                onTap: () => onItemTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavSlot({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rSheet,
        child: SizedBox(
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    active ? item.activeIcon : item.icon,
                    size: 20,
                    color: active ? AppColors.text : AppColors.textDim,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.2,
                      color: active ? AppColors.text : AppColors.textDim,
                    ),
                  ),
                ],
              ),
              if (active)
                Positioned(
                  top: 8,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGlow,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.accentBright, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accent),
            boxShadow: [
              ...AppShadows.fab,
              BoxShadow(
                color: AppColors.bg.withValues(alpha: 0.6),
                spreadRadius: 6,
                blurRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            size: 22,
            color: AppColors.onAccent,
          ),
        ),
      ),
    );
  }
}

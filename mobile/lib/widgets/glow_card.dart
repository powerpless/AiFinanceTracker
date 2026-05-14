import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum GlowCardVariant { hero, card, flat }

/// Card surface with the redesign's standard lilac hairline + soft glow.
///
/// - [GlowCardVariant.hero] adds the strong accent-glow shadow and an
///   accent-tinted border for hero/summary surfaces.
/// - [GlowCardVariant.card] is the default — subtle shadow, plain hairline.
/// - [GlowCardVariant.flat] drops the shadow entirely (for nested rows).
class GlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final GlowCardVariant variant;
  final Color? background;
  final BorderRadius borderRadius;
  final Border? border;
  final VoidCallback? onTap;

  const GlowCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin,
    this.variant = GlowCardVariant.card,
    this.background,
    this.borderRadius = AppRadius.rCard,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shadows = switch (variant) {
      GlowCardVariant.hero => AppShadows.hero,
      GlowCardVariant.card => AppShadows.card,
      GlowCardVariant.flat => const <BoxShadow>[],
    };
    final defaultBorder = variant == GlowCardVariant.hero
        ? Border.all(color: AppColors.accentHair)
        : Border.all(color: AppColors.hairline);

    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? AppColors.bgRaised,
        borderRadius: borderRadius,
        border: border ?? defaultBorder,
        boxShadow: shadows,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: box,
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Design tokens for the FinTracker dark redesign.
///
/// Source palette is OKLCH (see `diploma-redesign/project/*.jsx`); sRGB hex
/// values below are pre-computed from the canonical OKLCH expressions and
/// stored as `Color` constants so the rest of the app never sees raw hex.

class AppColors {
  AppColors._();

  // Surfaces (oklch hue 295, chroma 0.004)
  static const Color bg = Color(0xFF070709);
  static const Color bgRaised = Color(0xFF0C0C0E);
  static const Color bgSunken = Color(0xFF050506);

  // Lilac accent (oklch 0.74 0.08 295)
  static const Color accent = Color(0xFFAEA1D9);
  static const Color accentSoft = Color(0x2EAEA1D9);
  static const Color accentSofter = Color(0x1AAEA1D9);
  static const Color accentHair = Color(0x47AEA1D9);
  static const Color accentGlow = Color(0x52AEA1D9);
  static const Color accentBright = Color(0xFFC1B4EC);
  static const Color onAccent = Color(0xFF121116);

  // Mint — income / positive deltas (oklch 0.82 0.10 165)
  static const Color mint = Color(0xFF82D9B4);
  static const Color mintSoft = Color(0x2982D9B4);
  static const Color mintHair = Color(0x4782D9B4);

  // Coral — expense / anomaly (oklch 0.78 0.10 25)
  static const Color coral = Color(0xFFF19E97);
  static const Color coralSoft = Color(0x29F19E97);
  static const Color coralHair = Color(0x47F19E97);

  // Text scale
  static const Color text = Color(0xFFF8F8FC);
  static const Color textMid = Color(0xFFABA9B2);
  static const Color textDim = Color(0xFF6F6D75);
  static const Color textFaint = Color(0xFF424246);

  // Hairlines (white at low alpha)
  static const Color hairline = Color(0x0FFFFFFF);
  static const Color hairlineSoft = Color(0x0AFFFFFF);

  // Chart palette (oklch 0.74 0.10) — hue rotated ±35/±70 around accent.
  static const Color chart1 = Color(0xFFAF9EE4); // 295°
  static const Color chart2 = Color(0xFFCF94C9); // 330°
  static const Color chart3 = Color(0xFF86ACEA); // 260°
  static const Color chart4 = Color(0xFFE190A2); // 5°
  static const Color chart5 = Color(0xFF61B7DE); // 230°

  static const List<Color> chartPalette = [chart1, chart2, chart3, chart4, chart5];
}

class AppRadius {
  AppRadius._();

  static const double xs = 8;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 14;
  static const double card = 18;
  static const double hero = 22;
  static const double sheet = 24;
  static const double pill = 999;

  static const BorderRadius rXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rCard = BorderRadius.all(Radius.circular(card));
  static const BorderRadius rHero = BorderRadius.all(Radius.circular(hero));
  static const BorderRadius rSheet = BorderRadius.all(Radius.circular(sheet));
  static const BorderRadius rPill = BorderRadius.all(Radius.circular(pill));
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double base = 12;
  static const double lg = 14;
  static const double screen = 18;
  static const double xl = 24;

  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: screen);
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );
  static const EdgeInsets heroPadding = EdgeInsets.fromLTRB(20, 18, 20, 20);
}

class AppShadows {
  AppShadows._();

  /// Soft lilac glow under hero cards.
  static const List<BoxShadow> hero = [
    BoxShadow(
      color: AppColors.accentGlow,
      blurRadius: 40,
      spreadRadius: -16,
      offset: Offset(0, 12),
    ),
  ];

  /// Regular card lift.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.accentGlow,
      blurRadius: 30,
      spreadRadius: -22,
      offset: Offset(0, 8),
    ),
  ];

  /// FAB / primary glow.
  static const List<BoxShadow> fab = [
    BoxShadow(
      color: AppColors.accentGlow,
      blurRadius: 30,
      spreadRadius: -10,
      offset: Offset(0, 14),
    ),
  ];

  /// Bottom-bar floating effect.
  static const List<BoxShadow> bottomBar = [
    BoxShadow(
      color: Color(0x99000000),
      blurRadius: 30,
      spreadRadius: -18,
      offset: Offset(0, -8),
    ),
  ];
}

/// Builds the FinTracker dark theme.
///
/// All surfaces use `AppColors`; text uses tabular figures so currency
/// amounts align across rows. Geist is the design's preferred family but is
/// not bundled — falling back to system sans-serif keeps the theme self-
/// contained.
ThemeData buildDarkTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    primaryContainer: AppColors.accentSoft,
    onPrimaryContainer: AppColors.text,
    secondary: AppColors.mint,
    onSecondary: AppColors.onAccent,
    secondaryContainer: AppColors.mintSoft,
    onSecondaryContainer: AppColors.text,
    tertiary: AppColors.coral,
    onTertiary: AppColors.onAccent,
    tertiaryContainer: AppColors.coralSoft,
    onTertiaryContainer: AppColors.text,
    error: AppColors.coral,
    onError: AppColors.onAccent,
    errorContainer: AppColors.coralSoft,
    onErrorContainer: AppColors.coral,
    surface: AppColors.bg,
    onSurface: AppColors.text,
    surfaceContainerLowest: AppColors.bgSunken,
    surfaceContainerLow: AppColors.bg,
    surfaceContainer: AppColors.bgRaised,
    surfaceContainerHigh: AppColors.bgRaised,
    surfaceContainerHighest: AppColors.bgRaised,
    onSurfaceVariant: AppColors.textMid,
    outline: AppColors.hairline,
    outlineVariant: AppColors.hairlineSoft,
    shadow: Color(0xCC000000),
    scrim: Color(0xCC000000),
    inverseSurface: AppColors.text,
    onInverseSurface: AppColors.bg,
    inversePrimary: AppColors.accent,
  );

  const tabular = <FontFeature>[FontFeature.tabularFigures()];

  final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

  final textTheme = base.textTheme
      .apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
        fontFamily: null,
      )
      .copyWith(
        displayLarge: const TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w500,
          letterSpacing: -1.2,
          height: 1.0,
          color: AppColors.text,
          fontFeatures: tabular,
        ),
        displayMedium: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w500,
          letterSpacing: -1.0,
          height: 1.0,
          color: AppColors.text,
          fontFeatures: tabular,
        ),
        displaySmall: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.8,
          height: 1.05,
          color: AppColors.text,
          fontFeatures: tabular,
        ),
        headlineMedium: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.4,
          color: AppColors.text,
          fontFeatures: tabular,
        ),
        headlineSmall: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
        titleMedium: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
        titleSmall: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
        bodyLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.text,
        ),
        bodyMedium: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textMid,
        ),
        bodySmall: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w400,
          color: AppColors.textDim,
        ),
        labelLarge: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
        labelMedium: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          color: AppColors.textDim,
        ),
        labelSmall: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: AppColors.textDim,
        ),
      );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    dividerColor: AppColors.hairline,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.bgRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.rCard,
        side: BorderSide(color: AppColors.hairline),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.hairlineSoft,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(color: AppColors.textMid, size: 20),
    primaryIconTheme: const IconThemeData(color: AppColors.text, size: 20),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        disabledBackgroundColor: AppColors.bgSunken,
        disabledForegroundColor: AppColors.textFaint,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(0, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.hairline),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.onAccent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgSunken,
      hintStyle: const TextStyle(color: AppColors.textFaint),
      labelStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
      floatingLabelStyle: const TextStyle(color: AppColors.accent),
      prefixIconColor: AppColors.textMid,
      suffixIconColor: AppColors.textMid,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: const OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: BorderSide(color: AppColors.hairline),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: BorderSide(color: AppColors.coral),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: BorderSide(color: AppColors.coral, width: 1.5),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.text,
      unselectedLabelColor: AppColors.textDim,
      indicatorColor: AppColors.accent,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      unselectedLabelStyle: const TextStyle(fontSize: 13),
      overlayColor: WidgetStateProperty.all(AppColors.accentSofter),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgRaised,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textDim,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.bgRaised,
      selectedColor: AppColors.accentSoft,
      side: BorderSide(color: AppColors.hairline),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rPill),
      labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
      secondaryLabelStyle: TextStyle(color: AppColors.text, fontSize: 12),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.textMid,
      textColor: AppColors.text,
      tileColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.bgRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rSheet),
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
      ),
      contentTextStyle: TextStyle(fontSize: 13.5, color: AppColors.textMid),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bgRaised,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.bgRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.bgRaised,
      contentTextStyle: TextStyle(color: AppColors.text, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearTrackColor: AppColors.bgSunken,
      circularTrackColor: AppColors.bgSunken,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return AppColors.textDim;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accent;
        return AppColors.bgSunken;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accent;
        return AppColors.hairline;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accent;
        return AppColors.textDim;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accent;
        return AppColors.bgSunken;
      }),
      checkColor: WidgetStateProperty.all(AppColors.onAccent),
      side: const BorderSide(color: AppColors.hairline),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.rXs),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.bgRaised;
          return AppColors.bgSunken;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.text;
          return AppColors.textDim;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const BorderSide(color: AppColors.accentHair);
          }
          return BorderSide.none;
        }),
        shape: WidgetStateProperty.all(
          const RoundedRectangleBorder(borderRadius: AppRadius.rSm),
        ),
      ),
    ),
    splashFactory: InkRipple.splashFactory,
    splashColor: AppColors.accentSofter,
    highlightColor: AppColors.accentSofter,
  );
}

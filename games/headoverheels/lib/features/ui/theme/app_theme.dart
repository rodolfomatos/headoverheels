// Design system for Head over Heels - Material 3 theme.

import 'package:flutter/material.dart';

/// App color scheme based on design requirements.
class AppColors {
  // Dark theme (primary)
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF171717);
  static const Color darkBorder = Color(0xFF262626);
  static const Color darkText = Color(0xFFFAFAFA);
  static const Color darkMuted = Color(0xFF737373);
  static const Color darkAccent = Color(0xFF22C55E);
  static const Color darkDestructive = Color(0xFFEF4444);

  // Light theme
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightBorder = Color(0xFFE5E5E5);
  static const Color lightText = Color(0xFF171717);
  static const Color lightMuted = Color(0xFF737373);
  static const Color lightAccent = Color(0xFF22C55E);
  static const Color lightDestructive = Color(0xFFEF4444);

  // Game-specific colors
  static const Color headColor = Color(0xFF3B82F6); // Blue for Head
  static const Color heelsColor = Color(0xFFF97316); // Orange for Heels
  static const Color combinedColor = Color(0xFF8B5CF6); // Purple for combined
  static const Color crownColor = Color(0xFFFFD700); // Gold
  static const Color doughnutColor = Color(0xFFFF8800); // Orange
  static const Color poisonColor = Color(0xFF888888); // Gray
  static const Color springColor = Color(0xFFFFFF00); // Yellow
  static const Color conveyorColor = Color(0xFF6B7280); // Gray
  static const Color switchOnColor = Color(0xFF22C55E); // Green
  static const Color switchOffColor = Color(0xFFEF4444); // Red
}

/// Typography scale.
class AppTypography {
  static const String fontFamily = 'Inter';

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle small = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: 'SF Mono, Fira Code, monospace',
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static TextStyle button = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

/// Spacing scale (4px base unit).
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Border radius scale.
class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double full = 9999;
}

/// Animation durations.
class AppDuration {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
}

/// Theme data factory.
class AppTheme {
  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.darkAccent,
      secondary: AppColors.darkAccent.withValues(alpha: 0.8),
      surface: AppColors.darkSurface,
      error: AppColors.darkDestructive,
      onPrimary: AppColors.darkBackground,
      onSecondary: AppColors.darkBackground,
      onSurface: AppColors.darkText,
      onError: AppColors.darkBackground,
      outline: AppColors.darkBorder,
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(color: AppColors.darkText),
        displayMedium: AppTypography.h1.copyWith(color: AppColors.darkText),
        displaySmall: AppTypography.h2.copyWith(color: AppColors.darkText),
        headlineLarge: AppTypography.h1.copyWith(color: AppColors.darkText),
        headlineMedium: AppTypography.h2.copyWith(color: AppColors.darkText),
        headlineSmall: AppTypography.h2.copyWith(color: AppColors.darkText),
        titleLarge: AppTypography.h2.copyWith(color: AppColors.darkText),
        titleMedium: AppTypography.body.copyWith(color: AppColors.darkText),
        titleSmall: AppTypography.small.copyWith(color: AppColors.darkMuted),
        bodyLarge: AppTypography.body.copyWith(color: AppColors.darkText),
        bodyMedium: AppTypography.body.copyWith(color: AppColors.darkText),
        bodySmall: AppTypography.small.copyWith(color: AppColors.darkMuted),
        labelLarge: AppTypography.button.copyWith(
          color: AppColors.darkBackground,
        ),
        labelMedium: AppTypography.small.copyWith(color: AppColors.darkMuted),
        labelSmall: AppTypography.small.copyWith(color: AppColors.darkMuted),
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkBorder,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h2.copyWith(color: AppColors.darkText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkAccent,
          foregroundColor: AppColors.darkBackground,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.button,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkAccent,
          side: BorderSide(color: AppColors.darkAccent, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkAccent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: AppTypography.body,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.darkAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.darkDestructive),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.darkMuted),
        labelStyle: AppTypography.body.copyWith(color: AppColors.darkText),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.darkAccent,
        inactiveTrackColor: AppColors.darkBorder,
        thumbColor: AppColors.darkAccent,
        overlayColor: AppColors.darkAccent.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkAccent;
          }
          return AppColors.darkMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkAccent.withValues(alpha: 0.5);
          }
          return AppColors.darkBorder;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkAccent;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.darkBackground),
        side: BorderSide(color: AppColors.darkBorder, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkAccent;
          }
          return AppColors.darkMuted;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.h2.copyWith(color: AppColors.darkText),
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.darkText,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        modalBackgroundColor: AppColors.darkSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.darkAccent.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(AppTypography.small),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.darkAccent, size: 24);
          }
          return IconThemeData(color: AppColors.darkMuted, size: 24);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.darkAccent,
        unselectedLabelColor: AppColors.darkMuted,
        indicatorColor: AppColors.darkAccent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.body,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedColor: AppColors.darkAccent.withValues(alpha: 0.2),
        labelStyle: AppTypography.body,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: BorderSide(color: AppColors.darkBorder),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.darkBorder),
        ),
        textStyle: AppTypography.small.copyWith(color: AppColors.darkText),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.darkText,
        ),
        actionTextColor: AppColors.darkAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.lightAccent,
      secondary: AppColors.lightAccent.withValues(alpha: 0.8),
      surface: AppColors.lightSurface,
      error: AppColors.lightDestructive,
      onPrimary: AppColors.lightBackground,
      onSecondary: AppColors.lightBackground,
      onSurface: AppColors.lightText,
      onError: AppColors.lightBackground,
      outline: AppColors.lightBorder,
      shadow: Colors.black26,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(
          color: AppColors.lightText,
        ),
        displayMedium: AppTypography.h1.copyWith(color: AppColors.lightText),
        displaySmall: AppTypography.h2.copyWith(color: AppColors.lightText),
        headlineLarge: AppTypography.h1.copyWith(color: AppColors.lightText),
        headlineMedium: AppTypography.h2.copyWith(color: AppColors.lightText),
        headlineSmall: AppTypography.h2.copyWith(color: AppColors.lightText),
        titleLarge: AppTypography.h2.copyWith(color: AppColors.lightText),
        titleMedium: AppTypography.body.copyWith(color: AppColors.lightText),
        titleSmall: AppTypography.small.copyWith(color: AppColors.lightMuted),
        bodyLarge: AppTypography.body.copyWith(color: AppColors.lightText),
        bodyMedium: AppTypography.body.copyWith(color: AppColors.lightText),
        bodySmall: AppTypography.small.copyWith(color: AppColors.lightMuted),
        labelLarge: AppTypography.button.copyWith(
          color: AppColors.lightBackground,
        ),
        labelMedium: AppTypography.small.copyWith(color: AppColors.lightMuted),
        labelSmall: AppTypography.small.copyWith(color: AppColors.lightMuted),
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightBorder,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h2.copyWith(color: AppColors.lightText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightAccent,
          foregroundColor: AppColors.lightBackground,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.button,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightAccent,
          side: BorderSide(color: AppColors.lightAccent, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightAccent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: AppTypography.body,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.lightAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.lightDestructive),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.lightMuted),
        labelStyle: AppTypography.body.copyWith(color: AppColors.lightText),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.lightAccent,
        inactiveTrackColor: AppColors.lightBorder,
        thumbColor: AppColors.lightAccent,
        overlayColor: AppColors.lightAccent.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightAccent;
          }
          return AppColors.lightMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightAccent.withValues(alpha: 0.5);
          }
          return AppColors.lightBorder;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightAccent;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.lightBackground),
        side: BorderSide(color: AppColors.lightBorder, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightAccent;
          }
          return AppColors.lightMuted;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.h2.copyWith(color: AppColors.lightText),
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.lightText,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        modalBackgroundColor: AppColors.lightSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.lightAccent.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(AppTypography.small),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.lightAccent, size: 24);
          }
          return IconThemeData(color: AppColors.lightMuted, size: 24);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.lightAccent,
        unselectedLabelColor: AppColors.lightMuted,
        indicatorColor: AppColors.lightAccent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.body,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedColor: AppColors.lightAccent.withValues(alpha: 0.2),
        labelStyle: AppTypography.body,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: BorderSide(color: AppColors.lightBorder),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.lightBorder),
        ),
        textStyle: AppTypography.small.copyWith(color: AppColors.lightText),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightSurface,
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.lightText,
        ),
        actionTextColor: AppColors.lightAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

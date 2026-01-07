import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_palette.dart';

class AppTheme {
  // Current palette - defaults to Obsidian Glass, updated by the provider
  static ThemePalette _currentPalette = ThemePalette.obsidianGlass;

  /// Set the current palette (called when theme changes)
  static void setCurrentPalette(ThemePalette palette) {
    _currentPalette = palette;
  }

  /// Get the current palette
  static ThemePalette get currentPalette => _currentPalette;

  // ============================================================
  // Dynamic color getters - these return colors from the current palette
  // ============================================================

  static Color get background => _currentPalette.background;
  static Color get surface => _currentPalette.surface;
  static Color get surfaceLight => _currentPalette.surfaceLight;
  static Color get surfaceLighter => _currentPalette.surfaceLighter;
  static Color get primary => _currentPalette.primary;
  static Color get primaryDark => _currentPalette.primaryDark;
  static Color get secondary => _currentPalette.secondary;
  static Color get accent => _currentPalette.accent;
  static Color get textPrimary => _currentPalette.textPrimary;
  static Color get textSecondary => _currentPalette.textSecondary;
  static Color get textMuted => _currentPalette.textMuted;
  static Color get success => _currentPalette.success;
  static Color get warning => _currentPalette.warning;
  static Color get error => _currentPalette.error;
  static Color get divider => _currentPalette.divider;
  static Color get cardBorder => _currentPalette.cardBorder;

  // ============================================================
  // Dynamic shape getters
  // ============================================================

  static double get cardRadius => _currentPalette.cardRadius;
  static double get buttonRadius => _currentPalette.buttonRadius;
  static double get dialogRadius => _currentPalette.dialogRadius;

  // ============================================================
  // Dynamic effect getters
  // ============================================================

  static bool get useGlassmorphism => _currentPalette.useGlassmorphism;
  static double get glassBlur => _currentPalette.glassBlur;
  static double get glassOpacity => _currentPalette.glassOpacity;
  static List<BoxShadow> get cardShadow => _currentPalette.cardShadow;
  static EdgeInsets get cardPadding => _currentPalette.cardPadding;
  static double get borderWidth => _currentPalette.borderWidth;
  static bool get showCardBorders => _currentPalette.showCardBorders;

  /// Build a ThemeData from the current palette
  static ThemeData get darkTheme => buildTheme(_currentPalette);

  /// Get the appropriate TextStyle with Google Fonts
  static TextStyle _getFont(ThemePalette palette, {bool isHeading = false}) {
    final fontFamily = isHeading 
        ? (palette.headingFontFamily ?? palette.fontFamily)
        : palette.fontFamily;
    
    try {
      return GoogleFonts.getFont(fontFamily);
    } catch (e) {
      // Fallback to system font if Google Font not available
      return const TextStyle();
    }
  }

  /// Build a ThemeData from a specific palette
  static ThemeData buildTheme(ThemePalette palette) {
    final isDark = palette.brightness == Brightness.dark;
    
    // Get base text styles from Google Fonts
    final baseTextStyle = _getFont(palette);
    final headingTextStyle = _getFont(palette, isHeading: true);

    // Calculate scaled font sizes
    final scale = palette.fontSizeMultiplier;

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme(
        brightness: palette.brightness,
        primary: palette.primary,
        secondary: palette.secondary,
        surface: palette.surface,
        error: palette.error,
        onPrimary: isDark ? palette.background : Colors.white,
        onSecondary: palette.textPrimary,
        onSurface: palette.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headingTextStyle.copyWith(
          fontSize: 20 * scale,
          fontWeight: palette.headingWeight,
          color: palette.textPrimary,
          letterSpacing: palette.letterSpacingHeading,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: palette.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.cardRadius),
          side: palette.showCardBorders 
              ? BorderSide(color: palette.cardBorder, width: palette.borderWidth)
              : BorderSide.none,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20 * palette.spacingMultiplier, 
          vertical: 4 * palette.spacingMultiplier,
        ),
        iconColor: palette.textSecondary,
        textColor: palette.textPrimary,
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return palette.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary.withValues(alpha: 0.3);
          }
          return palette.surfaceLighter;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.primary,
        inactiveTrackColor: palette.surfaceLighter,
        thumbColor: palette.primary,
        overlayColor: palette.primary.withValues(alpha: 0.16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: isDark ? palette.background : Colors.white,
          elevation: palette.cardElevation,
          padding: EdgeInsets.symmetric(
            horizontal: 24 * palette.spacingMultiplier, 
            vertical: 16 * palette.spacingMultiplier,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(palette.buttonRadius),
          ),
          textStyle: baseTextStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16 * scale,
            letterSpacing: palette.letterSpacingBody,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          padding: EdgeInsets.symmetric(
            horizontal: 24 * palette.spacingMultiplier, 
            vertical: 16 * palette.spacingMultiplier,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(palette.buttonRadius),
          ),
          side: BorderSide(color: palette.primary, width: palette.borderWidth),
          textStyle: baseTextStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16 * scale,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          padding: EdgeInsets.symmetric(
            horizontal: 16 * palette.spacingMultiplier, 
            vertical: 12 * palette.spacingMultiplier,
          ),
          textStyle: baseTextStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14 * scale,
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: palette.textSecondary,
        size: 24,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceLight,
        contentTextStyle: baseTextStyle.copyWith(color: palette.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.cardRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.dialogRadius),
        ),
        titleTextStyle: headingTextStyle.copyWith(
          color: palette.textPrimary,
          fontSize: 20 * scale,
          fontWeight: palette.headingWeight,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(palette.dialogRadius),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceLight,
        selectedColor: palette.primary,
        labelStyle: baseTextStyle.copyWith(
          fontSize: 14 * scale,
          color: palette.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.chipRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(palette.inputRadius),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(palette.inputRadius),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(palette.inputRadius),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * palette.spacingMultiplier,
          vertical: 14 * palette.spacingMultiplier,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: headingTextStyle.copyWith(
          fontSize: 32 * scale,
          fontWeight: FontWeight.w800,
          color: palette.textPrimary,
          letterSpacing: palette.letterSpacingHeading,
        ),
        displayMedium: headingTextStyle.copyWith(
          fontSize: 28 * scale,
          fontWeight: palette.headingWeight,
          color: palette.textPrimary,
          letterSpacing: palette.letterSpacingHeading,
        ),
        headlineLarge: headingTextStyle.copyWith(
          fontSize: 24 * scale,
          fontWeight: palette.headingWeight,
          color: palette.textPrimary,
          letterSpacing: palette.letterSpacingHeading,
        ),
        headlineMedium: headingTextStyle.copyWith(
          fontSize: 20 * scale,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
          letterSpacing: palette.letterSpacingHeading,
        ),
        titleLarge: baseTextStyle.copyWith(
          fontSize: 18 * scale,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
          letterSpacing: palette.letterSpacingBody,
        ),
        titleMedium: baseTextStyle.copyWith(
          fontSize: 16 * scale,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
          letterSpacing: palette.letterSpacingBody,
        ),
        bodyLarge: baseTextStyle.copyWith(
          fontSize: 16 * scale,
          fontWeight: palette.bodyWeight,
          color: palette.textPrimary,
          letterSpacing: palette.letterSpacingBody,
        ),
        bodyMedium: baseTextStyle.copyWith(
          fontSize: 14 * scale,
          fontWeight: palette.bodyWeight,
          color: palette.textSecondary,
          letterSpacing: palette.letterSpacingBody,
        ),
        bodySmall: baseTextStyle.copyWith(
          fontSize: 12 * scale,
          fontWeight: palette.bodyWeight,
          color: palette.textMuted,
          letterSpacing: palette.letterSpacingBody,
        ),
        labelLarge: baseTextStyle.copyWith(
          fontSize: 14 * scale,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
          letterSpacing: palette.letterSpacingBody,
        ),
        labelMedium: baseTextStyle.copyWith(
          fontSize: 12 * scale,
          fontWeight: FontWeight.w500,
          color: palette.textSecondary,
          letterSpacing: palette.letterSpacingBody,
        ),
        labelSmall: baseTextStyle.copyWith(
          fontSize: 10 * scale,
          fontWeight: FontWeight.w500,
          color: palette.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Defines a complete color palette for the app's UI theme.
/// Each palette provides a cohesive set of colors for backgrounds,
/// surfaces, accents, text, and semantic colors.
class ThemePalette {
  final String name;
  final IconData icon;
  final Brightness brightness;

  // Background colors
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color surfaceLighter;

  // Primary/Accent colors
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;

  // Text colors
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Semantic colors
  final Color success;
  final Color warning;
  final Color error;

  // UI element colors
  final Color divider;
  final Color cardBorder;

  const ThemePalette({
    required this.name,
    required this.icon,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.surfaceLighter,
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.error,
    required this.divider,
    required this.cardBorder,
  });

  /// All available theme palettes
  static const List<ThemePalette> palettes = [
    deepSpace,
    sunsetCoral,
    arcticFrost,
    forestDusk,
    lavenderDreams,
    midnightOcean,
    goldenHour,
    neonCyberpunk,
    terracottaEarth,
    mintFresh,
  ];

  // ============================================================
  // PALETTE 1: Deep Space (Current/Default)
  // Dark navy with cyan/teal accents - the original theme
  // ============================================================
  static const deepSpace = ThemePalette(
    name: 'Deep Space',
    icon: Icons.rocket_launch_rounded,
    brightness: Brightness.dark,
    background: Color(0xFF0A0E14),
    surface: Color(0xFF151A22),
    surfaceLight: Color(0xFF1E2530),
    surfaceLighter: Color(0xFF2A3340),
    primary: Color(0xFF00E5CC),
    primaryDark: Color(0xFF00B8A3),
    secondary: Color(0xFF6366F1),
    accent: Color(0xFFFF6B6B),
    textPrimary: Color(0xFFF0F4F8),
    textSecondary: Color(0xFF8892A4),
    textMuted: Color(0xFF5A6478),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    divider: Color(0xFF2A3340),
    cardBorder: Color(0xFF2A3340),
  );

  // ============================================================
  // PALETTE 2: Sunset Coral
  // Warm charcoal with coral and amber - sunset vibes
  // ============================================================
  static const sunsetCoral = ThemePalette(
    name: 'Sunset Coral',
    icon: Icons.wb_twilight_rounded,
    brightness: Brightness.dark,
    background: Color(0xFF1A1512),
    surface: Color(0xFF2A2320),
    surfaceLight: Color(0xFF3A3230),
    surfaceLighter: Color(0xFF4A4240),
    primary: Color(0xFFFF6B6B),
    primaryDark: Color(0xFFE85555),
    secondary: Color(0xFFFFB347),
    accent: Color(0xFFFFA07A),
    textPrimary: Color(0xFFFFF5F0),
    textSecondary: Color(0xFFBBA89A),
    textMuted: Color(0xFF8A7A6A),
    success: Color(0xFF7CB342),
    warning: Color(0xFFFFCA28),
    error: Color(0xFFFF5252),
    divider: Color(0xFF4A4240),
    cardBorder: Color(0xFF4A4240),
  );

  // ============================================================
  // PALETTE 3: Arctic Frost
  // Cool slate with ice blue - clean, modern light theme
  // ============================================================
  static const arcticFrost = ThemePalette(
    name: 'Arctic Frost',
    icon: Icons.ac_unit_rounded,
    brightness: Brightness.light,
    background: Color(0xFFF0F4F8),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFE8EEF4),
    surfaceLighter: Color(0xFFD0DAE4),
    primary: Color(0xFF0EA5E9),
    primaryDark: Color(0xFF0284C7),
    secondary: Color(0xFFF472B6),
    accent: Color(0xFF7DD3FC),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    divider: Color(0xFFE2E8F0),
    cardBorder: Color(0xFFCBD5E1),
  );

  // ============================================================
  // PALETTE 4: Forest Dusk
  // Deep green-black with emerald and gold - natural, earthy
  // ============================================================
  static const forestDusk = ThemePalette(
    name: 'Forest Dusk',
    icon: Icons.forest_rounded,
    brightness: Brightness.dark,
    background: Color(0xFF0D1512),
    surface: Color(0xFF162420),
    surfaceLight: Color(0xFF1F322D),
    surfaceLighter: Color(0xFF2A403A),
    primary: Color(0xFF10B981),
    primaryDark: Color(0xFF059669),
    secondary: Color(0xFFD4A853),
    accent: Color(0xFF84CC16),
    textPrimary: Color(0xFFECFDF5),
    textSecondary: Color(0xFF86EFAC),
    textMuted: Color(0xFF4ADE80),
    success: Color(0xFF22C55E),
    warning: Color(0xFFEAB308),
    error: Color(0xFFF87171),
    divider: Color(0xFF2A403A),
    cardBorder: Color(0xFF2A403A),
  );

  // ============================================================
  // PALETTE 5: Lavender Dreams
  // Purple-black with lavender and rose - soft, dreamy
  // ============================================================
  static const lavenderDreams = ThemePalette(
    name: 'Lavender Dreams',
    icon: Icons.auto_awesome_rounded,
    brightness: Brightness.dark,
    background: Color(0xFF120F18),
    surface: Color(0xFF1E1928),
    surfaceLight: Color(0xFF2A2438),
    surfaceLighter: Color(0xFF3A3248),
    primary: Color(0xFFA78BFA),
    primaryDark: Color(0xFF8B5CF6),
    secondary: Color(0xFFFDA4AF),
    accent: Color(0xFFE879F9),
    textPrimary: Color(0xFFF5F3FF),
    textSecondary: Color(0xFFC4B5FD),
    textMuted: Color(0xFF8B7DC8),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFFB7185),
    divider: Color(0xFF3A3248),
    cardBorder: Color(0xFF3A3248),
  );

  // ============================================================
  // PALETTE 6: Midnight Ocean
  // Deep blue with electric blue and teal - deep sea feel
  // ============================================================
  static const midnightOcean = ThemePalette(
    name: 'Midnight Ocean',
    icon: Icons.water_rounded,
    brightness: Brightness.dark,
    background: Color(0xFF0A1628),
    surface: Color(0xFF132035),
    surfaceLight: Color(0xFF1C2D4A),
    surfaceLighter: Color(0xFF263A5E),
    primary: Color(0xFF3B82F6),
    primaryDark: Color(0xFF2563EB),
    secondary: Color(0xFF14B8A6),
    accent: Color(0xFF60A5FA),
    textPrimary: Color(0xFFF0F9FF),
    textSecondary: Color(0xFF7DD3FC),
    textMuted: Color(0xFF38BDF8),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    divider: Color(0xFF263A5E),
    cardBorder: Color(0xFF263A5E),
  );

  // ============================================================
  // PALETTE 7: Golden Hour
  // Warm brown-black with amber and cream - rich, luxurious
  // ============================================================
  static const goldenHour = ThemePalette(
    name: 'Golden Hour',
    icon: Icons.wb_sunny_rounded,
    brightness: Brightness.dark,
    background: Color(0xFF151210),
    surface: Color(0xFF231E1A),
    surfaceLight: Color(0xFF322A24),
    surfaceLighter: Color(0xFF42382E),
    primary: Color(0xFFF59E0B),
    primaryDark: Color(0xFFD97706),
    secondary: Color(0xFFFDE68A),
    accent: Color(0xFFCA8A04),
    textPrimary: Color(0xFFFFFBEB),
    textSecondary: Color(0xFFD4A574),
    textMuted: Color(0xFFA68B5B),
    success: Color(0xFF84CC16),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFEF4444),
    divider: Color(0xFF42382E),
    cardBorder: Color(0xFF42382E),
  );

  // ============================================================
  // PALETTE 8: Neon Cyberpunk
  // Pure black with hot pink and electric lime - bold, futuristic
  // ============================================================
  static const neonCyberpunk = ThemePalette(
    name: 'Neon Cyberpunk',
    icon: Icons.electric_bolt_rounded,
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    surface: Color(0xFF0D0D0D),
    surfaceLight: Color(0xFF1A1A1A),
    surfaceLighter: Color(0xFF262626),
    primary: Color(0xFFEC4899),
    primaryDark: Color(0xFFDB2777),
    secondary: Color(0xFFA3E635),
    accent: Color(0xFF06B6D4),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFF9A8D4),
    textMuted: Color(0xFFBE185D),
    success: Color(0xFF84CC16),
    warning: Color(0xFFFACC15),
    error: Color(0xFFFF3366),
    divider: Color(0xFF333333),
    cardBorder: Color(0xFF404040),
  );

  // ============================================================
  // PALETTE 9: Terracotta Earth
  // Clay brown with rust and sage - organic, grounded
  // ============================================================
  static const terracottaEarth = ThemePalette(
    name: 'Terracotta Earth',
    icon: Icons.landscape_rounded,
    brightness: Brightness.dark,
    background: Color(0xFF1C1614),
    surface: Color(0xFF2A2220),
    surfaceLight: Color(0xFF3A302C),
    surfaceLighter: Color(0xFF4A403A),
    primary: Color(0xFFEA580C),
    primaryDark: Color(0xFFC2410C),
    secondary: Color(0xFF84A98C),
    accent: Color(0xFFD97706),
    textPrimary: Color(0xFFFFF7ED),
    textSecondary: Color(0xFFC4A484),
    textMuted: Color(0xFF9A7A5A),
    success: Color(0xFF65A30D),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFDC2626),
    divider: Color(0xFF4A403A),
    cardBorder: Color(0xFF4A403A),
  );

  // ============================================================
  // PALETTE 10: Mint Fresh
  // Off-white with mint and charcoal - light, fresh, modern
  // ============================================================
  static const mintFresh = ThemePalette(
    name: 'Mint Fresh',
    icon: Icons.spa_rounded,
    brightness: Brightness.light,
    background: Color(0xFFFAFDFB),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFECFDF5),
    surfaceLighter: Color(0xFFD1FAE5),
    primary: Color(0xFF059669),
    primaryDark: Color(0xFF047857),
    secondary: Color(0xFF374151),
    accent: Color(0xFF34D399),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF9CA3AF),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    divider: Color(0xFFD1FAE5),
    cardBorder: Color(0xFFA7F3D0),
  );
}


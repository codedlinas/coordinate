import 'package:flutter/material.dart';

/// Defines a complete design system for the app's UI theme.
/// Each palette provides colors, typography, shapes, shadows, and effects
/// for a truly distinct visual experience.
class ThemePalette {
  final String name;
  final String description;
  final IconData icon;
  final Brightness brightness;

  // ============================================================
  // COLORS
  // ============================================================
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color surfaceLighter;
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color error;
  final Color divider;
  final Color cardBorder;

  // ============================================================
  // TYPOGRAPHY
  // ============================================================
  final String fontFamily;
  final String? headingFontFamily; // null = use fontFamily
  final FontWeight headingWeight;
  final FontWeight bodyWeight;
  final double letterSpacingHeading;
  final double letterSpacingBody;
  final double fontSizeMultiplier; // Scale all fonts

  // ============================================================
  // SHAPES
  // ============================================================
  final double cardRadius;
  final double buttonRadius;
  final double inputRadius;
  final double chipRadius;
  final double dialogRadius;

  // ============================================================
  // SHADOWS
  // ============================================================
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> elevatedShadow;
  final List<BoxShadow>? glowShadow; // For neon effects

  // ============================================================
  // EFFECTS
  // ============================================================
  final bool useGlassmorphism;
  final double glassBlur;
  final double glassOpacity;
  final Color? glassOverlayColor;
  final Gradient? cardGradient;
  final Gradient? backgroundGradient;

  // ============================================================
  // SPACING & DENSITY
  // ============================================================
  final double spacingMultiplier; // 0.85 compact, 1.0 normal, 1.15 spacious
  final EdgeInsets cardPadding;
  final double cardElevation;

  // ============================================================
  // BORDERS
  // ============================================================
  final double borderWidth;
  final bool showCardBorders;
  final Color? glowBorderColor; // For neon border effects

  const ThemePalette({
    required this.name,
    required this.description,
    required this.icon,
    required this.brightness,
    // Colors
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
    // Typography
    required this.fontFamily,
    this.headingFontFamily,
    this.headingWeight = FontWeight.w700,
    this.bodyWeight = FontWeight.w400,
    this.letterSpacingHeading = -0.5,
    this.letterSpacingBody = 0.0,
    this.fontSizeMultiplier = 1.0,
    // Shapes
    this.cardRadius = 16.0,
    this.buttonRadius = 12.0,
    this.inputRadius = 12.0,
    this.chipRadius = 8.0,
    this.dialogRadius = 20.0,
    // Shadows
    this.cardShadow = const [],
    this.elevatedShadow = const [],
    this.glowShadow,
    // Effects
    this.useGlassmorphism = false,
    this.glassBlur = 10.0,
    this.glassOpacity = 0.1,
    this.glassOverlayColor,
    this.cardGradient,
    this.backgroundGradient,
    // Spacing
    this.spacingMultiplier = 1.0,
    this.cardPadding = const EdgeInsets.all(16),
    this.cardElevation = 0.0,
    // Borders
    this.borderWidth = 1.0,
    this.showCardBorders = true,
    this.glowBorderColor,
  });

  /// All available theme palettes
  static const List<ThemePalette> palettes = [
    obsidianGlass,
    neonPulse,
    midnightLuxe,
    terminalGreen,
    carbonFiber,
    arcticMist,
    paperCraft,
    minimalMono,
    sunriseWarm,
    neoBrutal,
  ];

  // ============================================================
  // THEME 1: OBSIDIAN GLASS (Glassmorphism Dark)
  // Frosted glass cards, soft glows, floating feel
  // ============================================================
  static const obsidianGlass = ThemePalette(
    name: 'Obsidian Glass',
    description: 'Frosted glass on dark',
    icon: Icons.blur_on_rounded,
    brightness: Brightness.dark,
    // Colors - Muted purple/blue on charcoal
    background: Color(0xFF0D0D12),
    surface: Color(0xFF1A1A24),
    surfaceLight: Color(0xFF252532),
    surfaceLighter: Color(0xFF32324A),
    primary: Color(0xFF8B5CF6),
    primaryDark: Color(0xFF7C3AED),
    secondary: Color(0xFF06B6D4),
    accent: Color(0xFFF472B6),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFA1A1B5),
    textMuted: Color(0xFF6B6B80),
    success: Color(0xFF10B981),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF43F5E),
    divider: Color(0xFF32324A),
    cardBorder: Color(0xFF42425A),
    // Typography - Clean sans-serif
    fontFamily: 'Inter',
    headingWeight: FontWeight.w600,
    letterSpacingHeading: -0.3,
    // Shapes - Rounded, floating
    cardRadius: 20.0,
    buttonRadius: 14.0,
    dialogRadius: 24.0,
    // Shadows - Soft glow
    cardShadow: [
      BoxShadow(
        color: Color(0x208B5CF6),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x308B5CF6),
        blurRadius: 30,
        offset: Offset(0, 12),
      ),
    ],
    // Effects - Glassmorphism enabled
    useGlassmorphism: true,
    glassBlur: 16.0,
    glassOpacity: 0.08,
    glassOverlayColor: Color(0xFF8B5CF6),
    // Spacing - Airy
    spacingMultiplier: 1.1,
    cardPadding: EdgeInsets.all(20),
    // Borders - Subtle
    borderWidth: 1.0,
    showCardBorders: true,
  );

  // ============================================================
  // THEME 2: NEON PULSE (Cyberpunk)
  // Electric neons, glowing borders, futuristic
  // ============================================================
  static const neonPulse = ThemePalette(
    name: 'Neon Pulse',
    description: 'Electric cyberpunk glow',
    icon: Icons.electric_bolt_rounded,
    brightness: Brightness.dark,
    // Colors - Pure black with electric accents
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    surfaceLight: Color(0xFF141414),
    surfaceLighter: Color(0xFF1F1F1F),
    primary: Color(0xFFFF00FF),
    primaryDark: Color(0xFFCC00CC),
    secondary: Color(0xFF00FFFF),
    accent: Color(0xFFBFFF00),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFFF99FF),
    textMuted: Color(0xFF666666),
    success: Color(0xFF00FF88),
    warning: Color(0xFFFFFF00),
    error: Color(0xFFFF3366),
    divider: Color(0xFF2A2A2A),
    cardBorder: Color(0xFFFF00FF),
    // Typography - Futuristic
    fontFamily: 'Orbitron',
    headingFontFamily: 'Orbitron',
    headingWeight: FontWeight.w700,
    letterSpacingHeading: 2.0,
    letterSpacingBody: 0.5,
    fontSizeMultiplier: 0.95,
    // Shapes - Sharp with slight rounding
    cardRadius: 4.0,
    buttonRadius: 4.0,
    inputRadius: 4.0,
    chipRadius: 2.0,
    dialogRadius: 8.0,
    // Shadows - Neon glow
    cardShadow: [
      BoxShadow(
        color: Color(0x60FF00FF),
        blurRadius: 12,
        spreadRadius: -2,
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x80FF00FF),
        blurRadius: 24,
        spreadRadius: 0,
      ),
    ],
    glowShadow: [
      BoxShadow(
        color: Color(0xFFFF00FF),
        blurRadius: 8,
        spreadRadius: -4,
      ),
    ],
    // Effects
    useGlassmorphism: false,
    glowBorderColor: Color(0xFFFF00FF),
    // Spacing - Compact, dense
    spacingMultiplier: 0.9,
    cardPadding: EdgeInsets.all(16),
    // Borders - Glowing
    borderWidth: 1.5,
    showCardBorders: true,
  );

  // ============================================================
  // THEME 3: MIDNIGHT LUXE (Elegant Dark)
  // Deep navy, champagne gold, refined luxury
  // ============================================================
  static const midnightLuxe = ThemePalette(
    name: 'Midnight Luxe',
    description: 'Elegant gold on navy',
    icon: Icons.diamond_rounded,
    brightness: Brightness.dark,
    // Colors - Navy with gold accents
    background: Color(0xFF0A0F1C),
    surface: Color(0xFF121829),
    surfaceLight: Color(0xFF1A2238),
    surfaceLighter: Color(0xFF242D48),
    primary: Color(0xFFD4AF37),
    primaryDark: Color(0xFFB8960C),
    secondary: Color(0xFFF5E6C8),
    accent: Color(0xFFE8C872),
    textPrimary: Color(0xFFF5F0E6),
    textSecondary: Color(0xFFB8A88A),
    textMuted: Color(0xFF6B6355),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    divider: Color(0xFF2A3550),
    cardBorder: Color(0xFF3A4560),
    // Typography - Elegant serif headings
    fontFamily: 'Cormorant Garamond',
    headingFontFamily: 'Playfair Display',
    headingWeight: FontWeight.w600,
    bodyWeight: FontWeight.w400,
    letterSpacingHeading: 0.5,
    letterSpacingBody: 0.2,
    fontSizeMultiplier: 1.05,
    // Shapes - Medium rounded, refined
    cardRadius: 12.0,
    buttonRadius: 8.0,
    inputRadius: 8.0,
    chipRadius: 6.0,
    dialogRadius: 16.0,
    // Shadows - Subtle, elegant
    cardShadow: [
      BoxShadow(
        color: Color(0x20000000),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x18D4AF37),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
    // Effects
    useGlassmorphism: false,
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0A0F1C), Color(0xFF0F1628)],
    ),
    // Spacing - Generous, luxurious
    spacingMultiplier: 1.15,
    cardPadding: EdgeInsets.all(20),
    // Borders - Refined
    borderWidth: 1.0,
    showCardBorders: true,
  );

  // ============================================================
  // THEME 4: TERMINAL GREEN (Retro Hacker)
  // Phosphor green, monospace, CRT aesthetic
  // ============================================================
  static const terminalGreen = ThemePalette(
    name: 'Terminal',
    description: 'Retro hacker console',
    icon: Icons.terminal_rounded,
    brightness: Brightness.dark,
    // Colors - Classic terminal green
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    surfaceLight: Color(0xFF111111),
    surfaceLighter: Color(0xFF1A1A1A),
    primary: Color(0xFF00FF41),
    primaryDark: Color(0xFF00CC33),
    secondary: Color(0xFF00FF41),
    accent: Color(0xFFFFB000),
    textPrimary: Color(0xFF00FF41),
    textSecondary: Color(0xFF00CC33),
    textMuted: Color(0xFF006622),
    success: Color(0xFF00FF41),
    warning: Color(0xFFFFB000),
    error: Color(0xFFFF3333),
    divider: Color(0xFF003311),
    cardBorder: Color(0xFF00FF41),
    // Typography - Monospace, technical
    fontFamily: 'JetBrains Mono',
    headingFontFamily: 'JetBrains Mono',
    headingWeight: FontWeight.w700,
    bodyWeight: FontWeight.w400,
    letterSpacingHeading: 1.0,
    letterSpacingBody: 0.5,
    fontSizeMultiplier: 0.92,
    // Shapes - Sharp, minimal
    cardRadius: 2.0,
    buttonRadius: 2.0,
    inputRadius: 2.0,
    chipRadius: 2.0,
    dialogRadius: 4.0,
    // Shadows - None, flat
    cardShadow: [],
    elevatedShadow: [],
    glowShadow: [
      BoxShadow(
        color: Color(0x4000FF41),
        blurRadius: 4,
        spreadRadius: 0,
      ),
    ],
    // Effects - Minimal
    useGlassmorphism: false,
    // Spacing - Dense, information-rich
    spacingMultiplier: 0.85,
    cardPadding: EdgeInsets.all(12),
    // Borders - Visible, terminal-like
    borderWidth: 1.0,
    showCardBorders: true,
    glowBorderColor: Color(0xFF00FF41),
  );

  // ============================================================
  // THEME 5: CARBON FIBER (Technical Dark)
  // Professional, technical, clean
  // ============================================================
  static const carbonFiber = ThemePalette(
    name: 'Carbon',
    description: 'Technical precision',
    icon: Icons.precision_manufacturing_rounded,
    brightness: Brightness.dark,
    // Colors - Dark gray with blue accent
    background: Color(0xFF121418),
    surface: Color(0xFF1A1D24),
    surfaceLight: Color(0xFF242830),
    surfaceLighter: Color(0xFF2E333D),
    primary: Color(0xFF0EA5E9),
    primaryDark: Color(0xFF0284C7),
    secondary: Color(0xFF64748B),
    accent: Color(0xFF22D3EE),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    divider: Color(0xFF334155),
    cardBorder: Color(0xFF3F4A5C),
    // Typography - Technical, clean
    fontFamily: 'DM Sans',
    headingFontFamily: 'DM Sans',
    headingWeight: FontWeight.w600,
    bodyWeight: FontWeight.w400,
    letterSpacingHeading: -0.2,
    letterSpacingBody: 0.0,
    fontSizeMultiplier: 1.0,
    // Shapes - Crisp, medium
    cardRadius: 8.0,
    buttonRadius: 6.0,
    inputRadius: 6.0,
    chipRadius: 4.0,
    dialogRadius: 12.0,
    // Shadows - Subtle depth
    cardShadow: [
      BoxShadow(
        color: Color(0x20000000),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x30000000),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    // Effects
    useGlassmorphism: false,
    // Spacing - Standard
    spacingMultiplier: 1.0,
    cardPadding: EdgeInsets.all(16),
    // Borders - Subtle
    borderWidth: 1.0,
    showCardBorders: true,
  );

  // ============================================================
  // THEME 6: ARCTIC MIST (Glassmorphism Light)
  // Frosted white glass, airy, floating
  // ============================================================
  static const arcticMist = ThemePalette(
    name: 'Arctic Mist',
    description: 'Frosted glass on light',
    icon: Icons.ac_unit_rounded,
    brightness: Brightness.light,
    // Colors - Soft blue/gray
    background: Color(0xFFF0F4F8),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFE8EEF4),
    surfaceLighter: Color(0xFFD0DAE6),
    primary: Color(0xFF0EA5E9),
    primaryDark: Color(0xFF0284C7),
    secondary: Color(0xFFF472B6),
    accent: Color(0xFF7DD3FC),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    divider: Color(0xFFE2E8F0),
    cardBorder: Color(0xFFCBD5E1),
    // Typography - Clean, airy
    fontFamily: 'Plus Jakarta Sans',
    headingWeight: FontWeight.w600,
    letterSpacingHeading: -0.3,
    // Shapes - Very rounded, floating
    cardRadius: 24.0,
    buttonRadius: 16.0,
    inputRadius: 14.0,
    chipRadius: 10.0,
    dialogRadius: 28.0,
    // Shadows - Soft, floating
    cardShadow: [
      BoxShadow(
        color: Color(0x150EA5E9),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
      BoxShadow(
        color: Color(0x08000000),
        blurRadius: 40,
        offset: Offset(0, 16),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x200EA5E9),
        blurRadius: 32,
        offset: Offset(0, 12),
      ),
    ],
    // Effects - Light glassmorphism
    useGlassmorphism: true,
    glassBlur: 20.0,
    glassOpacity: 0.7,
    glassOverlayColor: Color(0xFFFFFFFF),
    // Spacing - Generous, airy
    spacingMultiplier: 1.15,
    cardPadding: EdgeInsets.all(20),
    // Borders - Very subtle
    borderWidth: 1.0,
    showCardBorders: true,
  );

  // ============================================================
  // THEME 7: PAPER CRAFT (Material/Tactile)
  // Warm off-white, pronounced shadows, paper-like
  // ============================================================
  static const paperCraft = ThemePalette(
    name: 'Paper Craft',
    description: 'Tactile material layers',
    icon: Icons.layers_rounded,
    brightness: Brightness.light,
    // Colors - Warm off-white
    background: Color(0xFFFAF8F5),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFF5F2EE),
    surfaceLighter: Color(0xFFEDE9E3),
    primary: Color(0xFFE07A5F),
    primaryDark: Color(0xFFC9604A),
    secondary: Color(0xFF81B29A),
    accent: Color(0xFFF2CC8F),
    textPrimary: Color(0xFF3D405B),
    textSecondary: Color(0xFF5C5F7A),
    textMuted: Color(0xFF9395A8),
    success: Color(0xFF81B29A),
    warning: Color(0xFFF2CC8F),
    error: Color(0xFFE07A5F),
    divider: Color(0xFFE5E1DB),
    cardBorder: Color(0xFFE5E1DB),
    // Typography - Friendly, rounded
    fontFamily: 'Nunito',
    headingFontFamily: 'Nunito',
    headingWeight: FontWeight.w700,
    bodyWeight: FontWeight.w400,
    letterSpacingHeading: -0.2,
    letterSpacingBody: 0.1,
    fontSizeMultiplier: 1.02,
    // Shapes - Medium rounded
    cardRadius: 12.0,
    buttonRadius: 10.0,
    inputRadius: 10.0,
    chipRadius: 8.0,
    dialogRadius: 16.0,
    // Shadows - Pronounced, lifted
    cardShadow: [
      BoxShadow(
        color: Color(0x12000000),
        blurRadius: 1,
        offset: Offset(0, 1),
      ),
      BoxShadow(
        color: Color(0x10000000),
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
      BoxShadow(
        color: Color(0x08000000),
        blurRadius: 24,
        offset: Offset(0, 12),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x15000000),
        blurRadius: 2,
        offset: Offset(0, 2),
      ),
      BoxShadow(
        color: Color(0x12000000),
        blurRadius: 16,
        offset: Offset(0, 8),
      ),
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 32,
        offset: Offset(0, 16),
      ),
    ],
    // Effects - No glass, material feel
    useGlassmorphism: false,
    cardElevation: 2.0,
    // Spacing - Comfortable
    spacingMultiplier: 1.05,
    cardPadding: EdgeInsets.all(18),
    // Borders - Hidden, shadow-based
    borderWidth: 0.0,
    showCardBorders: false,
  );

  // ============================================================
  // THEME 8: MINIMAL MONO (Ultra-Clean)
  // Pure white, maximum whitespace, single accent
  // ============================================================
  static const minimalMono = ThemePalette(
    name: 'Minimal',
    description: 'Ultra-clean simplicity',
    icon: Icons.crop_square_rounded,
    brightness: Brightness.light,
    // Colors - Monochromatic with single accent
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFF8F9FA),
    surfaceLighter: Color(0xFFF1F3F5),
    primary: Color(0xFF000000),
    primaryDark: Color(0xFF1A1A1A),
    secondary: Color(0xFF6B7280),
    accent: Color(0xFF3B82F6),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF9CA3AF),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    divider: Color(0xFFE5E7EB),
    cardBorder: Color(0xFFE5E7EB),
    // Typography - Thin, geometric
    fontFamily: 'Outfit',
    headingFontFamily: 'Outfit',
    headingWeight: FontWeight.w500,
    bodyWeight: FontWeight.w300,
    letterSpacingHeading: -0.5,
    letterSpacingBody: 0.2,
    fontSizeMultiplier: 1.0,
    // Shapes - Rounded, soft
    cardRadius: 16.0,
    buttonRadius: 12.0,
    inputRadius: 10.0,
    chipRadius: 8.0,
    dialogRadius: 20.0,
    // Shadows - Very subtle
    cardShadow: [
      BoxShadow(
        color: Color(0x06000000),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
    // Effects - None, pure
    useGlassmorphism: false,
    // Spacing - Maximum whitespace
    spacingMultiplier: 1.2,
    cardPadding: EdgeInsets.all(24),
    // Borders - Nearly invisible
    borderWidth: 1.0,
    showCardBorders: true,
  );

  // ============================================================
  // THEME 9: SUNRISE WARM (Organic/Soft)
  // Cream background, warm colors, cozy feel
  // ============================================================
  static const sunriseWarm = ThemePalette(
    name: 'Sunrise',
    description: 'Warm organic tones',
    icon: Icons.wb_sunny_rounded,
    brightness: Brightness.light,
    // Colors - Warm, earthy
    background: Color(0xFFFFFBF5),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFFFF5EB),
    surfaceLighter: Color(0xFFFFEDD8),
    primary: Color(0xFFD97706),
    primaryDark: Color(0xFFB45309),
    secondary: Color(0xFF65A30D),
    accent: Color(0xFFF59E0B),
    textPrimary: Color(0xFF422006),
    textSecondary: Color(0xFF78350F),
    textMuted: Color(0xFFA16207),
    success: Color(0xFF65A30D),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFDC2626),
    divider: Color(0xFFFED7AA),
    cardBorder: Color(0xFFFED7AA),
    // Typography - Soft, humanist
    fontFamily: 'Nunito Sans',
    headingFontFamily: 'Fraunces',
    headingWeight: FontWeight.w600,
    bodyWeight: FontWeight.w400,
    letterSpacingHeading: -0.3,
    letterSpacingBody: 0.1,
    fontSizeMultiplier: 1.02,
    // Shapes - Very rounded, friendly
    cardRadius: 20.0,
    buttonRadius: 14.0,
    inputRadius: 12.0,
    chipRadius: 10.0,
    dialogRadius: 24.0,
    // Shadows - Warm-tinted
    cardShadow: [
      BoxShadow(
        color: Color(0x10D97706),
        blurRadius: 16,
        offset: Offset(0, 6),
      ),
      BoxShadow(
        color: Color(0x08000000),
        blurRadius: 32,
        offset: Offset(0, 12),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x18D97706),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
    // Effects - Subtle warmth
    useGlassmorphism: false,
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFBF5), Color(0xFFFFF5EB)],
    ),
    // Spacing - Generous, cozy
    spacingMultiplier: 1.1,
    cardPadding: EdgeInsets.all(20),
    // Borders - Warm, soft
    borderWidth: 1.5,
    showCardBorders: true,
  );

  // ============================================================
  // THEME 10: NEO BRUTAL (Bold Statement)
  // Stark white, bold colors, thick borders, no shadows
  // ============================================================
  static const neoBrutal = ThemePalette(
    name: 'Neo Brutal',
    description: 'Bold & unapologetic',
    icon: Icons.square_rounded,
    brightness: Brightness.light,
    // Colors - High contrast primaries
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFF5F5F5),
    surfaceLighter: Color(0xFFEEEEEE),
    primary: Color(0xFF0066FF),
    primaryDark: Color(0xFF0052CC),
    secondary: Color(0xFFFF3366),
    accent: Color(0xFFFFCC00),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF333333),
    textMuted: Color(0xFF666666),
    success: Color(0xFF00CC66),
    warning: Color(0xFFFFCC00),
    error: Color(0xFFFF3333),
    divider: Color(0xFF000000),
    cardBorder: Color(0xFF000000),
    // Typography - Chunky, bold
    fontFamily: 'Space Grotesk',
    headingFontFamily: 'Space Grotesk',
    headingWeight: FontWeight.w700,
    bodyWeight: FontWeight.w500,
    letterSpacingHeading: -0.5,
    letterSpacingBody: 0.0,
    fontSizeMultiplier: 1.0,
    // Shapes - Sharp corners
    cardRadius: 0.0,
    buttonRadius: 0.0,
    inputRadius: 0.0,
    chipRadius: 0.0,
    dialogRadius: 0.0,
    // Shadows - None, flat
    cardShadow: [
      // Offset shadow for brutalist effect
      BoxShadow(
        color: Color(0xFF000000),
        blurRadius: 0,
        offset: Offset(4, 4),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0xFF000000),
        blurRadius: 0,
        offset: Offset(6, 6),
      ),
    ],
    // Effects - None
    useGlassmorphism: false,
    // Spacing - Standard
    spacingMultiplier: 1.0,
    cardPadding: EdgeInsets.all(16),
    // Borders - Thick, bold
    borderWidth: 3.0,
    showCardBorders: true,
  );
}

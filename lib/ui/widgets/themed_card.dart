import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_palette.dart';

/// A theme-aware card widget that automatically applies the correct styling
/// based on the current theme palette, including glassmorphism effects,
/// shadows, borders, and padding.
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final bool elevated;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final Color? highlightColor;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevated = false,
    this.onTap,
    this.isHighlighted = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.currentPalette;
    final effectivePadding = padding ?? palette.cardPadding;
    final shadows = elevated ? palette.elevatedShadow : palette.cardShadow;
    
    // Determine background color
    Color bgColor = backgroundColor ?? palette.surface;
    if (isHighlighted && highlightColor != null) {
      bgColor = highlightColor!.withValues(alpha: 0.08);
    }

    // Build the card content
    Widget cardContent = Container(
      padding: effectivePadding,
      child: child,
    );

    // Apply glassmorphism if enabled
    if (palette.useGlassmorphism) {
      return _buildGlassCard(
        palette: palette,
        shadows: shadows,
        margin: margin,
        onTap: onTap,
        isHighlighted: isHighlighted,
        highlightColor: highlightColor,
        child: cardContent,
      );
    }

    // Standard card
    return _buildStandardCard(
      palette: palette,
      bgColor: bgColor,
      shadows: shadows,
      margin: margin,
      onTap: onTap,
      isHighlighted: isHighlighted,
      highlightColor: highlightColor,
      child: cardContent,
    );
  }

  Widget _buildGlassCard({
    required ThemePalette palette,
    required List<BoxShadow> shadows,
    EdgeInsets? margin,
    VoidCallback? onTap,
    required bool isHighlighted,
    Color? highlightColor,
    required Widget child,
  }) {
    final borderColor = isHighlighted && highlightColor != null
        ? highlightColor.withValues(alpha: 0.5)
        : palette.cardBorder.withValues(alpha: 0.3);

    Widget glass = ClipRRect(
      borderRadius: BorderRadius.circular(palette.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: palette.glassBlur,
          sigmaY: palette.glassBlur,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: (palette.glassOverlayColor ?? palette.surface)
                .withValues(alpha: palette.glassOpacity),
            borderRadius: BorderRadius.circular(palette.cardRadius),
            border: palette.showCardBorders
                ? Border.all(color: borderColor, width: palette.borderWidth)
                : null,
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      glass = Padding(padding: margin, child: glass);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: glass);
    }

    return glass;
  }

  Widget _buildStandardCard({
    required ThemePalette palette,
    required Color bgColor,
    required List<BoxShadow> shadows,
    EdgeInsets? margin,
    VoidCallback? onTap,
    required bool isHighlighted,
    Color? highlightColor,
    required Widget child,
  }) {
    final borderColor = isHighlighted && highlightColor != null
        ? highlightColor.withValues(alpha: 0.5)
        : palette.cardBorder;

    // Check for glow border effect (used in Neon Pulse, Terminal themes)
    final hasGlowBorder = palette.glowBorderColor != null && isHighlighted;

    Widget card = Container(
      decoration: BoxDecoration(
        color: bgColor,
        gradient: palette.cardGradient,
        borderRadius: BorderRadius.circular(palette.cardRadius),
        border: palette.showCardBorders
            ? Border.all(
                color: hasGlowBorder ? palette.glowBorderColor! : borderColor,
                width: palette.borderWidth,
              )
            : null,
        boxShadow: [
          ...shadows,
          // Add glow effect for highlighted items in glow themes
          if (hasGlowBorder && palette.glowShadow != null)
            ...palette.glowShadow!,
        ],
      ),
      child: child,
    );

    if (margin != null) {
      card = Padding(padding: margin, child: card);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}

/// A section container that groups related content with themed styling
class ThemedSection extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;

  const ThemedSection({
    super.key,
    required this.child,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ThemedCard(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }
}

/// A themed container for stat displays with icon and accent color
class ThemedStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? accentColor;
  final bool compact;

  const ThemedStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accentColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.currentPalette;
    final color = accentColor ?? palette.primary;
    final scale = palette.fontSizeMultiplier;

    return ThemedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(palette.chipRadius + 2),
            ),
            child: Icon(
              icon,
              color: color,
              size: compact ? 16 : 20,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                  fontSize: (compact ? 18 : 20) * scale,
                ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// A themed banner for displaying current status (e.g., "Currently in [Country]")
class ThemedStatusBanner extends StatelessWidget {
  final Widget leading;
  final String text;
  final Widget? trailing;
  final Color statusColor;

  const ThemedStatusBanner({
    super.key,
    required this.leading,
    required this.text,
    this.trailing,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.currentPalette;

    return ThemedCard(
      isHighlighted: true,
      highlightColor: statusColor,
      padding: EdgeInsets.symmetric(
        horizontal: 16 * palette.spacingMultiplier,
        vertical: 12 * palette.spacingMultiplier,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: palette.glowShadow != null
                  ? [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
          ),
          SizedBox(width: 12 * palette.spacingMultiplier),
          leading,
          SizedBox(width: 10 * palette.spacingMultiplier),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 14 * palette.fontSizeMultiplier,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A themed chip/badge widget
class ThemedChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool filled;

  const ThemedChip({
    super.key,
    required this.label,
    this.color,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.currentPalette;
    final chipColor = color ?? palette.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6 * palette.spacingMultiplier,
        vertical: 2 * palette.spacingMultiplier,
      ),
      decoration: BoxDecoration(
        color: filled ? chipColor : chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(palette.chipRadius),
        border: filled ? null : Border.all(color: chipColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled
              ? (palette.brightness == Brightness.dark
                  ? palette.background
                  : Colors.white)
              : chipColor,
          fontSize: 9 * palette.fontSizeMultiplier,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}



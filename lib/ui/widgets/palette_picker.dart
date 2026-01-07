import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/theme_provider.dart';
import '../theme/theme_palette.dart';

/// Shows a bottom sheet for selecting a theme palette
void showPalettePicker(BuildContext context) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const PalettePickerSheet(),
  );
}

class PalettePickerSheet extends ConsumerWidget {
  const PalettePickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(themePaletteIndexProvider);
    final palettes = ThemePalette.palettes;
    final currentPalette = palettes[currentIndex];

    return Container(
      decoration: BoxDecoration(
        color: currentPalette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: currentPalette.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title area
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        currentPalette.primary.withValues(alpha: 0.2),
                        currentPalette.secondary.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.palette_rounded,
                    color: currentPalette.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Design Themes',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: currentPalette.textPrimary,
                          letterSpacing: currentPalette.letterSpacingHeading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '10 unique visual experiences',
                        style: TextStyle(
                          fontSize: 14,
                          color: currentPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable grid of themes
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: palettes.length,
              itemBuilder: (context, index) {
                final palette = palettes[index];
                final isSelected = index == currentIndex;

                return _ThemePreviewCard(
                  palette: palette,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(themePaletteIndexProvider.notifier).setPalette(index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  final ThemePalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(palette.cardRadius),
          border: Border.all(
            color: isSelected ? palette.primary : palette.cardBorder,
            width: isSelected ? 2.5 : palette.borderWidth,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                  ...palette.cardShadow,
                ]
              : palette.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(palette.cardRadius - 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Color bar at top
              SizedBox(
                height: 6,
                child: Row(
                  children: [
                    Expanded(child: Container(color: palette.primary)),
                    Expanded(child: Container(color: palette.secondary)),
                    Expanded(child: Container(color: palette.accent)),
                    Expanded(child: Container(color: palette.success)),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.all(palette.cardRadius > 16 ? 18 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with icon and name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: palette.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(palette.chipRadius + 4),
                          ),
                          child: Icon(
                            palette.icon,
                            color: palette.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                palette.name,
                                style: TextStyle(
                                  fontSize: 17 * palette.fontSizeMultiplier,
                                  fontWeight: palette.headingWeight,
                                  color: palette.textPrimary,
                                  letterSpacing: palette.letterSpacingHeading,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                palette.description,
                                style: TextStyle(
                                  fontSize: 13 * palette.fontSizeMultiplier,
                                  color: palette.textSecondary,
                                  letterSpacing: palette.letterSpacingBody,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: palette.primary,
                              borderRadius: BorderRadius.circular(palette.chipRadius),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: palette.brightness == Brightness.dark
                                    ? palette.background
                                    : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Preview mini-card to show the theme's style
                    Container(
                      padding: EdgeInsets.all(12 * palette.spacingMultiplier),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(palette.cardRadius * 0.6),
                        border: palette.showCardBorders
                            ? Border.all(
                                color: palette.cardBorder,
                                width: palette.borderWidth,
                              )
                            : null,
                        boxShadow: palette.cardShadow.isNotEmpty
                            ? [
                                BoxShadow(
                                  color: palette.cardShadow.first.color.withValues(alpha: 0.5),
                                  blurRadius: palette.cardShadow.first.blurRadius * 0.5,
                                  offset: palette.cardShadow.first.offset * 0.5,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Sample stat icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: palette.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(palette.chipRadius),
                            ),
                            child: Icon(
                              Icons.public,
                              color: palette.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sample Card',
                                  style: TextStyle(
                                    fontSize: 13 * palette.fontSizeMultiplier,
                                    fontWeight: FontWeight.w600,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Typography & spacing preview',
                                  style: TextStyle(
                                    fontSize: 11 * palette.fontSizeMultiplier,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Sample button
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12 * palette.spacingMultiplier,
                              vertical: 6 * palette.spacingMultiplier,
                            ),
                            decoration: BoxDecoration(
                              color: palette.primary,
                              borderRadius: BorderRadius.circular(palette.buttonRadius * 0.6),
                            ),
                            child: Text(
                              'Button',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: palette.brightness == Brightness.dark
                                    ? palette.background
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Feature tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _FeatureTag(
                          label: palette.brightness == Brightness.dark ? 'Dark' : 'Light',
                          palette: palette,
                        ),
                        if (palette.useGlassmorphism)
                          _FeatureTag(label: 'Glass', palette: palette),
                        if (palette.cardRadius == 0)
                          _FeatureTag(label: 'Sharp', palette: palette)
                        else if (palette.cardRadius >= 20)
                          _FeatureTag(label: 'Rounded', palette: palette),
                        if (palette.glowBorderColor != null)
                          _FeatureTag(label: 'Glow', palette: palette),
                        if (palette.spacingMultiplier >= 1.1)
                          _FeatureTag(label: 'Spacious', palette: palette)
                        else if (palette.spacingMultiplier <= 0.9)
                          _FeatureTag(label: 'Compact', palette: palette),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTag extends StatelessWidget {
  final String label;
  final ThemePalette palette;

  const _FeatureTag({
    required this.label,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8 * palette.spacingMultiplier,
        vertical: 4 * palette.spacingMultiplier,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceLight,
        borderRadius: BorderRadius.circular(palette.chipRadius),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10 * palette.fontSizeMultiplier,
          fontWeight: FontWeight.w500,
          color: palette.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

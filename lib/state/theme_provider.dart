import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../ui/theme/theme_palette.dart';

/// Manages the selected theme palette index with persistence.
class ThemePaletteNotifier extends StateNotifier<int> {
  static const String _boxName = 'app_preferences';
  static const String _paletteKey = 'selectedPaletteIndex';

  ThemePaletteNotifier() : super(0) {
    _loadSavedPalette();
  }

  /// Load the saved palette index from Hive storage
  Future<void> _loadSavedPalette() async {
    try {
      final box = await Hive.openBox(_boxName);
      final savedIndex = box.get(_paletteKey, defaultValue: 0) as int;
      // Ensure the index is valid
      if (savedIndex >= 0 && savedIndex < ThemePalette.palettes.length) {
        state = savedIndex;
      }
    } catch (e) {
      // If loading fails, stick with default (0)
    }
  }

  /// Set the palette by index and persist the selection
  Future<void> setPalette(int index) async {
    if (index < 0 || index >= ThemePalette.palettes.length) return;
    
    state = index;
    
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_paletteKey, index);
    } catch (e) {
      // Persistence failed, but state is still updated
    }
  }

  /// Cycle to the next palette (wraps around)
  Future<void> nextPalette() async {
    final nextIndex = (state + 1) % ThemePalette.palettes.length;
    await setPalette(nextIndex);
  }

  /// Cycle to the previous palette (wraps around)
  Future<void> previousPalette() async {
    final prevIndex = (state - 1 + ThemePalette.palettes.length) % ThemePalette.palettes.length;
    await setPalette(prevIndex);
  }
}

/// Provider for the selected palette index
final themePaletteIndexProvider = StateNotifierProvider<ThemePaletteNotifier, int>((ref) {
  return ThemePaletteNotifier();
});

/// Derived provider that returns the actual ThemePalette object
final currentPaletteProvider = Provider<ThemePalette>((ref) {
  final index = ref.watch(themePaletteIndexProvider);
  return ThemePalette.palettes[index];
});

/// Provider for the list of all available palettes
final allPalettesProvider = Provider<List<ThemePalette>>((ref) {
  return ThemePalette.palettes;
});



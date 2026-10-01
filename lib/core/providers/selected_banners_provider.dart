import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Built-in banner definitions (asset path + display label)
// ─────────────────────────────────────────────────────────────────────────────

class BuiltinBanner {
  final String assetPath;
  final String label;
  const BuiltinBanner({required this.assetPath, required this.label});
}

const List<BuiltinBanner> kBuiltinBanners = [
  BuiltinBanner(assetPath: 'assets/images/image.png', label: 'Banner 1'),
  BuiltinBanner(assetPath: 'assets/images/image2.jpg', label: 'Banner 2'),
  BuiltinBanner(assetPath: 'assets/images/image3.jpg', label: 'Banner 3'),
];

const String _kPrefKey = 'selected_banner_indices';

// ─────────────────────────────────────────────────────────────────────────────
// Notifier — stores the set of enabled banner indices {0, 1, 2}
// ─────────────────────────────────────────────────────────────────────────────

class SelectedBannersNotifier extends AsyncNotifier<Set<int>> {
  @override
  Future<Set<int>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_kPrefKey);
    if (saved == null) {
      // Default: all 3 banners selected
      return {0, 1, 2};
    }
    return saved.map(int.parse).toSet();
  }

  Future<void> toggle(int index) async {
    final current = Set<int>.from(state.valueOrNull ?? {0, 1, 2});
    if (current.contains(index)) {
      if (current.length == 1) return; // keep at least one active
      current.remove(index);
    } else {
      current.add(index);
    }
    state = AsyncData(current);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kPrefKey,
      current.map((i) => i.toString()).toList(),
    );
  }

  Future<void> selectAll() async {
    state = const AsyncData({0, 1, 2});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kPrefKey, ['0', '1', '2']);
  }
}

final selectedBannersProvider =
    AsyncNotifierProvider<SelectedBannersNotifier, Set<int>>(
      SelectedBannersNotifier.new,
    );

/// Convenience: returns the list of currently-active built-in banner asset paths
final activeBannerAssetsProvider = Provider<List<String>>((ref) {
  final selected = ref.watch(selectedBannersProvider).valueOrNull ?? {0, 1, 2};
  final sorted = selected.toList()..sort();
  return sorted.map((i) => kBuiltinBanners[i].assetPath).toList();
});

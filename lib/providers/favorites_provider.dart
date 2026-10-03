import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import 'repository_providers.dart';

/// Favorite station ids, persisted locally.
class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() =>
      ref.watch(favoritesRepositoryProvider).loadIds();

  bool isFavorite(String stationId) => state.contains(stationId);

  Future<void> toggle(String stationId) async {
    final next = Set<String>.of(state);
    next.contains(stationId)
        ? next.remove(stationId)
        : next.add(stationId);
    try {
      await ref.read(favoritesRepositoryProvider).saveIds(next);
      state = next;
    } catch (_) {
      throw const StorageException();
    }
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(
        FavoritesNotifier.new);

import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';

/// Favorite station ids. Same swap-later contract as the booking repo.
abstract class FavoritesRepository {
  /// Synchronous: the box is opened in main() before any provider builds.
  Set<String> loadIds();
  Future<void> saveIds(Set<String> ids);
}

class HiveFavoritesRepository implements FavoritesRepository {
  HiveFavoritesRepository(this._box);
  final Box _box;

  static const _key = 'favorite_ids';

  @override
  Set<String> loadIds() {
    try {
      final raw = _box.get(_key);
      if (raw is List) return raw.whereType<String>().toSet();
      return {};
    } catch (_) {
      throw const StorageException(
          'Could not load your favorites from this device.');
    }
  }

  @override
  Future<void> saveIds(Set<String> ids) async {
    try {
      await _box.put(_key, ids.toList());
    } catch (_) {
      throw const StorageException();
    }
  }

  static Future<Box> openBox() =>
      Hive.openBox(AppConstants.favoritesBox);
}

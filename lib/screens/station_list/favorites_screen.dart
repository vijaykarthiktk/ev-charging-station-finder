import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/charging_station.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/station_provider.dart';
import '../../widgets/async_state_views.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/station_card.dart';
import '../station_detail/station_detail_screen.dart';

/// Saved stations. Hearts are toggled on station detail screens.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(stationsProvider);
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          child: stations.when(
            data: (list) {
              final saved = list
                  .where((s) => favorites.contains(s.id))
                  .toList();
              if (saved.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const ScreenHeader(title: 'Favorites'),
                    const SizedBox(height: 24),
                    const EmptyState(
                      icon: Icons.favorite_border,
                      message:
                          'No favorites yet. Tap the heart on any station to save it here.',
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: ScreenHeader(title: 'Favorites'),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: saved.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) => StationCard(
                        station: saved[i],
                        onTap: () => _open(context, ref, saved[i]),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const StationListSkeleton(),
            error: (e, _) => ErrorState(
              error: e,
              onRetry: () => ref.invalidate(stationsProvider),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref, ChargingStation station) {
    ref.read(selectedStationProvider.notifier).select(station);
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => StationDetailScreen(station: station)),
    );
  }
}

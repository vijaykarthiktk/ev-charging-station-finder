import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/charger_type.dart';
import '../../models/charging_station.dart';
import '../../providers/booking_provider.dart';
import '../../providers/station_filter.dart';
import '../../providers/station_provider.dart';
import '../../widgets/async_state_views.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/search_field.dart';
import '../../widgets/station_card.dart';
import '../station_detail/station_detail_screen.dart';
import 'active_booking_screen.dart';
import 'filter_screen.dart';
import 'map_screen.dart';

/// Home: title + filter entry, search, active-booking banner, station list.
class StationListScreen extends ConsumerStatefulWidget {
  const StationListScreen({super.key});

  @override
  ConsumerState<StationListScreen> createState() => _StationListScreenState();
}

class _StationListScreenState extends ConsumerState<StationListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stations = ref.watch(filteredStationsProvider);
    final active = ref.watch(activeBookingProvider);
    final filterActive = ref.watch(stationFilterProvider).isActive;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: ScreenHeader(
                  title: 'ChargeFind',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Map view',
                        icon: const Icon(Icons.map_outlined),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const MapScreen()),
                        ),
                      ),
                      _FilterButton(
                          active: filterActive,
                          onPressed: _openFilters),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SearchField(
                  controller: _searchController,
                  onChanged: (value) =>
                      ref.read(searchQueryProvider.notifier).set(value),
                ),
              ),
              if (active != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _ActiveBanner(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ActiveBookingScreen()),
                    ),
                  ),
                ),
              Expanded(
                child: stations.when(
                  data: (list) {
                    if (list.isEmpty) {
                      final searching =
                          ref.watch(searchQueryProvider).isNotEmpty ||
                              filterActive;
                      return EmptyState(
                        message: searching
                            ? 'No stations match. Try adjusting search or filters.'
                            : 'No charging stations found nearby.',
                      );
                    }
                    final searching =
                        ref.watch(searchQueryProvider).isNotEmpty ||
                            filterActive;
                    final scrollable = isWide(context)
                        ? GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: 288,
                            ),
                            itemCount: list.length,
                            itemBuilder: (_, i) => StationCard(
                                station: list[i],
                                onTap: () => _open(list[i])),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: list.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => StationCard(
                                station: list[i],
                                onTap: () => _open(list[i])),
                          );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (searching)
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 0),
                            child: Text(
                              '${list.length} station${list.length == 1 ? '' : 's'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                            ),
                          ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refresh,
                            child: scrollable,
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
            ],
          ),
        ),
      ),
    );
  }

  void _openFilters() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FilterScreen()),
      );

  Future<void> _refresh() async {
    ref.invalidate(stationsProvider);
    ref.invalidate(availabilityProvider);
    await ref.read(stationsProvider.future);
  }

  void _open(ChargingStation station) {
    ref.read(selectedStationProvider.notifier).select(station);
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => StationDetailScreen(station: station)),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onPressed});
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      tooltip: 'Filters',
      icon: const Icon(Icons.tune),
      onPressed: onPressed,
    );
    return active ? Badge(smallSize: 8, child: button) : button;
  }
}

class _ActiveBanner extends ConsumerWidget {
  const _ActiveBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeBookingProvider);
    if (active == null) return const SizedBox.shrink();
    const ink = Color(0xFF0A4D2B);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE1F2E6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active booking · ${active.stationName}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: ink)),
            const SizedBox(height: 2),
            Text(
                '${active.chargerType.fullLabel} · Booking ${active.id}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: ink)),
          ],
        ),
      ),
    );
  }
}

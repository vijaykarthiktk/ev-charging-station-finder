import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/charger_type.dart';
import '../../models/connector_type.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/station_filter.dart';
import '../../providers/station_provider.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/screen_header.dart';

/// Figma 07 Filters as a working screen: charger type, availability,
/// max price, and sort — applied to the station list on Apply.
class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({super.key});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  late StationFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(stationFilterProvider);
  }

  int get _matchCount {
    final stations = ref.watch(stationsProvider).value ?? [];
    final free = <String, int>{};
    for (final s in stations) {
      final v = ref.watch(availabilityProvider(s.id)).value;
      if (v != null && !v.isOffline) free[s.id] = v.available;
    }
    return applyStationFilter(
      stations,
      ref.watch(searchQueryProvider),
      _draft,
      free,
      favoriteIds: ref.watch(favoritesProvider),
      now: DateTime.now(),
    ).length;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const ScreenHeader(title: 'Filters', showBack: true),
              const SizedBox(height: 20),
              _label(context, 'Charger type'),
              for (final t in ChargerType.values)
                _checkRow(
                  context,
                  label: t.label,
                  checked: _draft.types.contains(t),
                  onTap: () => setState(() {
                    final next = Set<ChargerType>.of(_draft.types);
                    next.contains(t) ? next.remove(t) : next.add(t);
                    _draft = _draft.copyWith(types: next);
                  }),
                ),
              const SizedBox(height: 16),
              _label(context, 'Connectors'),
              for (final c in ConnectorType.values)
                _checkRow(
                  context,
                  label: c.label,
                  checked: _draft.connectors.contains(c),
                  onTap: () => setState(() {
                    final next = Set<ConnectorType>.of(_draft.connectors);
                    next.contains(c) ? next.remove(c) : next.add(c);
                    _draft = _draft.copyWith(connectors: next);
                  }),
                ),
              const SizedBox(height: 16),
              _label(context, 'Availability'),
              Row(
                children: [
                  _pill(
                    context,
                    label: 'Available',
                    selected: _draft.availability ==
                        AvailabilityFilter.available,
                    onTap: () => setState(() => _draft = _draft.copyWith(
                        availability:
                            _draft.availability == AvailabilityFilter.available
                                ? AvailabilityFilter.any
                                : AvailabilityFilter.available)),
                  ),
                  const SizedBox(width: 8),
                  _pill(
                    context,
                    label: 'Limited',
                    selected:
                        _draft.availability == AvailabilityFilter.limited,
                    onTap: () => setState(() => _draft = _draft.copyWith(
                        availability:
                            _draft.availability == AvailabilityFilter.limited
                                ? AvailabilityFilter.any
                                : AvailabilityFilter.limited)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _switchRow(
                context,
                label: 'Favorites only',
                value: _draft.favoritesOnly,
                onChanged: (v) =>
                    setState(() => _draft = _draft.copyWith(favoritesOnly: v)),
              ),
              _switchRow(
                context,
                label: 'Open now',
                value: _draft.openNow,
                onChanged: (v) =>
                    setState(() => _draft = _draft.copyWith(openNow: v)),
              ),
              const SizedBox(height: 16),
              _label(context, 'Max price'),
              Text('Up to ${formatRupees(_draft.maxPrice.round())} / kWh',
                  style: text.bodyMedium),
              Slider(
                value: _draft.maxPrice,
                min: StationFilter.minPriceBound,
                max: StationFilter.maxPriceBound,
                divisions: (StationFilter.maxPriceBound -
                        StationFilter.minPriceBound)
                    .round(),
                label: formatRupees(_draft.maxPrice.round()),
                onChanged: (v) =>
                    setState(() => _draft = _draft.copyWith(maxPrice: v)),
              ),
              const SizedBox(height: 8),
              _label(context, 'Max distance'),
              Text(
                  'Within ${_draft.maxDistanceKm.round()} km',
                  style: text.bodyMedium),
              Slider(
                value: _draft.maxDistanceKm,
                min: StationFilter.minDistanceBound,
                max: StationFilter.maxDistanceBound,
                divisions: (StationFilter.maxDistanceBound -
                        StationFilter.minDistanceBound)
                    .round(),
                label: '${_draft.maxDistanceKm.round()} km',
                onChanged: (v) => setState(
                    () => _draft = _draft.copyWith(maxDistanceKm: v)),
              ),
              const SizedBox(height: 8),
              _label(context, 'Sort by'),
              for (final s in StationSort.values)
                _radioRow(
                  context,
                  label: switch (s) {
                    StationSort.nearest => 'Nearest first',
                    StationSort.priceLow => 'Lowest price',
                    StationSort.mostAvailable => 'Most available',
                    StationSort.topRated => 'Top rated',
                  },
                  selected: _draft.sort == s,
                  onTap: () =>
                      setState(() => _draft = _draft.copyWith(sort: s)),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ref.read(stationFilterProvider.notifier).apply(_draft);
                    Navigator.of(context).pop();
                  },
                  child: Text('Show $_matchCount stations'),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(stationFilterProvider.notifier).reset();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Reset all'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      );

  Widget _checkRow(BuildContext context,
      {required String label,
      required bool checked,
      required VoidCallback onTap}) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: checked
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: checked
                  ? Icon(Icons.check, size: 16, color: scheme.onPrimary)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(BuildContext context,
      {required String label,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyLarge)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context,
      {required String label,
      required bool selected,
      required VoidCallback onTap}) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected
                    ? scheme.onPrimary
                    : scheme.onSurfaceVariant)),
      ),
    );
  }

  Widget _radioRow(BuildContext context,
      {required String label,
      required bool selected,
      required VoidCallback onTap}) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(width: 12),
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

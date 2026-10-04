import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/formatters.dart';
import '../../models/availability_status.dart';
import '../../models/charging_station.dart';
import '../../providers/location_provider.dart';
import '../../providers/station_provider.dart';
import '../../widgets/async_state_views.dart';
import '../../widgets/availability_indicator.dart';
import '../station_detail/station_detail_screen.dart';

/// Full-screen station map: OSM tiles, status-colored pins, tap for a
/// station sheet. Camera fits all stations; the FAB centers on the
/// device when location is available.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _controller = MapController();
  var _fitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fitToStations(List<ChargingStation> stations) {
    if (stations.isEmpty || _fitted) return;
    _fitted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(
            [for (final s in stations) LatLng(s.latitude, s.longitude)],
          ),
          padding: const EdgeInsets.all(48),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final stations = ref.watch(stationsProvider).value ?? [];
    final user = ref.watch(userLocationProvider).value;
    _fitToStations(stations);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: user ?? const LatLng(22.5, 79.0),
              initialZoom: user != null ? 12 : 5,
              onMapReady: () => _fitToStations(stations),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.chargefind.chargefind',
              ),
              MarkerLayer(
                markers: [
                  if (user != null)
                    Marker(
                      point: user,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  for (final s in stations)
                    Marker(
                      point: LatLng(s.latitude, s.longitude),
                      width: 48,
                      height: 48,
                      child: _Pin(
                        status:
                            ref.watch(stationStatusProvider(s.id)),
                        onTap: () => _openSheet(s),
                      ),
                    ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: stations.isEmpty
                          ? const SizedBox(
                              height: 16,
                              child: LinearProgressIndicator(),
                            )
                          : Text(
                              '${stations.length} stations nearby',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (stations.isEmpty)
            Center(
              child: ref.watch(stationsProvider).when(
                    data: (_) => const SizedBox.shrink(),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => ErrorState(
                      error: e,
                      onRetry: () =>
                          ref.invalidate(stationsProvider),
                    ),
                  ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'My location',
        onPressed: () {
          final loc = ref.read(userLocationProvider).value;
          if (loc == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Location unavailable.')),
            );
            return;
          }
          _controller.move(loc, 13);
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _openSheet(ChargingStation station) {
    ref.read(selectedStationProvider.notifier).select(station);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(station.name,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  AvailabilityIndicator(
                      status: ref.watch(stationStatusProvider(station.id))),
                  const Spacer(),
                  Text(
                    '${formatRupees(station.pricePerKwh)} / kWh · ${station.distanceKm.toStringAsFixed(1)} km',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              StationDetailScreen(station: station)),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status-colored map pin with a bolt glyph.
class _Pin extends StatelessWidget {
  const _Pin({required this.status, required this.onTap});
  final AvailabilityStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: status.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.bolt, size: 20, color: Colors.white),
      ),
    );
  }
}

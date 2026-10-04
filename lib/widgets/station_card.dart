import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/formatters.dart';
import '../models/availability_status.dart';
import '../models/charging_station.dart';
import '../providers/favorites_provider.dart';
import '../providers/review_provider.dart';
import '../providers/station_provider.dart';
import 'charger_badge.dart';

/// Station card: name + favorite, badges, price/slots, status pill,
/// full-width detail action. Availability streams in async — a skeleton
/// shows until real data arrives, never fake numbers.
class StationCard extends ConsumerWidget {
  const StationCard({
    super.key,
    required this.station,
    required this.onTap,
  });

  final ChargingStation station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(availabilityProvider(station.id));
    final isFavorite =
        ref.watch(favoritesProvider).contains(station.id);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(station.name,
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  InkWell(
                    onTap: () => _toggleFavorite(context, ref),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 22,
                        color: isFavorite
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in station.chargerTypes)
                    ChargerBadge(type: t, compact: true),
                ],
              ),
              const SizedBox(height: 8),
              _RatingRow(stationId: station.id),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(formatRupees(station.pricePerKwh),
                      style: text.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(' / kWh', style: text.bodySmall),
                  const Spacer(),
                  summary.when(
                    data: (s) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${s.available} slot${s.available == 1 ? '' : 's'}',
                          style: text.bodyMedium,
                        ),
                        Text(
                          ' · ${station.distanceKm.toStringAsFixed(1)} km',
                          style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    loading: () => const _PulseBar(width: 96),
                    error: (_, _) => Text(
                      'slots unavailable',
                      style: text.bodySmall
                          ?.copyWith(color: scheme.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              summary.when(
                data: (s) => _StatusPill(
                  status: AvailabilityStatusX.fromCounts(
                    isOffline: s.isOffline,
                    available: s.available,
                    total: s.total,
                  ),
                ),
                loading: () => const _PulseBar(width: 120),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onTap,
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

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(favoritesProvider.notifier).toggle(station.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e is AppException
                ? e.userMessage
                : 'Could not save favorite.')),
      );
    }
  }
}

/// Tinted status pill: dot + icon + label, never color alone.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final AvailabilityStatus status;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: status.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Icon(status.icon, size: 15, color: status.color),
          const SizedBox(width: 4),
          Text(status.label,
              style: text.bodySmall?.copyWith(
                  color: status.color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Compact "★ 4.5 (12)" row; muted "No reviews yet" when unreviewed.
class _RatingRow extends ConsumerWidget {
  const _RatingRow({required this.stationId});
  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(reviewSummaryProvider(stationId));
    final text = Theme.of(context).textTheme;
    if (summary.count == 0) {
      return Text('No reviews yet',
          style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: 15, color: Colors.amber.shade700),
        const SizedBox(width: 4),
        Text(
          '${summary.avg.toStringAsFixed(1)} (${summary.count})',
          style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Gray shimmer-less placeholder bar shown instead of fake availability.
class _PulseBar extends StatefulWidget {
  const _PulseBar({required this.width});
  final double width;

  @override
  State<_PulseBar> createState() => _PulseBarState();
}

class _PulseBarState extends State<_PulseBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 0.7).animate(_controller),
      child: Container(
        width: widget.width,
        height: 14,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }
}

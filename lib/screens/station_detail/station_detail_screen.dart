import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/availability_status.dart';
import '../../models/charger_type.dart';
import '../../models/charging_station.dart';
import '../../models/connector_type.dart';
import '../../providers/booking_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/station_provider.dart';
import '../../widgets/async_state_views.dart';
import '../../widgets/availability_indicator.dart';
import '../../widgets/charger_badge.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/write_review_sheet.dart';
import '../slot_booking/slot_booking_screen.dart';

/// Station profile: essential info, live availability, specs, amenities,
/// booking CTA. Refreshes itself off providers.
class StationDetailScreen extends ConsumerWidget {
  const StationDetailScreen({super.key, required this.station});

  final ChargingStation station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(availabilityProvider(station.id));
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ScreenHeader(
                title: 'Station Details',
                showBack: true,
                step: 1,
                stepLabel: 'Choose Station',
                trailing: _FavoriteButton(stationId: station.id),
              ),
              const SizedBox(height: 12),
              Text(station.name, style: text.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${station.address} · ${station.distanceKm.toStringAsFixed(1)} km',
                style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in station.chargerTypes)
                    ChargerBadge(type: t, compact: true),
                ],
              ),
              const SizedBox(height: 12),
              _RatingHeader(stationId: station.id),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: availability.when(
                    data: (s) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Available Slots', style: text.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          '${s.available} / ${s.total} slots available',
                          style: text.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        AvailabilityIndicator(
                          status: AvailabilityStatusX.fromCounts(
                            isOffline: s.isOffline,
                            available: s.available,
                            total: s.total,
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _stat(context, 'Total', '${s.total}'),
                            _stat(
                                context, 'Available', '${s.available}'),
                            _stat(context, 'Occupied', '${s.occupied}'),
                          ],
                        ),
                      ],
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, _) => ErrorState(
                      error: e,
                      onRetry: () => ref
                          .invalidate(availabilityProvider(station.id)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pricing & Specs', style: text.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(formatRupees(station.pricePerKwh),
                              style: text.headlineSmall),
                          const SizedBox(width: 4),
                          Text('/ kWh', style: text.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final t in station.chargerTypes)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(t.fullLabel,
                                      style: text.bodyMedium)),
                              Text(
                                  '${station.powerKw(t).toStringAsFixed(station.powerKw(t).truncateToDouble() == station.powerKw(t) ? 0 : 1)} kW',
                                  style: text.bodyMedium),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        station.connectors.map((c) => c.label).join(' · '),
                        style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        station.operatingStartHour == 0 &&
                                station.operatingEndHour == 24
                            ? 'Open 24 × 7'
                            : 'Open ${formatOperatingHours(station.operatingStartHour, station.operatingEndHour)}',
                        style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amenities', style: text.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in station.amenities)
                            _AmenChip(label: a),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ReviewsSection(stationId: station.id),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            border: Border(
              top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: station.isOffline
                  ? null
                  : () {
                      ref
                          .read(bookingFormProvider.notifier)
                          .init(
                              chargerType:
                                  station.chargerTypes.first);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SlotBookingScreen(
                              station: station),
                        ),
                      );
                    },
              child: Text(station.isOffline
                  ? 'Station Offline'
                  : 'Book a Slot'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => Column(
        children: [
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      );
}

class _AmenChip extends StatelessWidget {
  const _AmenChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _RatingHeader extends ConsumerWidget {
  const _RatingHeader({required this.stationId});
  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(reviewSummaryProvider(stationId));
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    if (summary.count == 0) {
      return Text('No reviews yet — be the first',
          style: text.bodyMedium?.copyWith(color: muted));
    }
    return Row(
      children: [
        Icon(Icons.star, size: 18, color: Colors.amber.shade700),
        const SizedBox(width: 4),
        Text(summary.avg.toStringAsFixed(1),
            style: text.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(' · ${summary.count} review${summary.count == 1 ? '' : 's'}',
            style: text.bodyMedium?.copyWith(color: muted)),
      ],
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.stationId});
  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(stationReviewsProvider(stationId));
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reviews & Ratings', style: text.titleMedium),
            const SizedBox(height: 8),
            reviews.when(
              data: (list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('No reviews yet.',
                        style: text.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  );
                }
                return Column(
                  children: [
                    for (final r in list.take(3))
                      _ReviewTile(
                        rating: r.rating,
                        comment: r.comment,
                        author: r.author,
                        createdAt: r.createdAt,
                      ),
                    if (list.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                            '+ ${list.length - 3} more review${list.length - 3 == 1 ? '' : 's'}',
                            style: text.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref
                    .invalidate(stationReviewsProvider(stationId)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => FractionallySizedBox(
                      heightFactor: 0.75,
                      child: WriteReviewSheet(stationId: stationId),
                    ),
                  ),
                  child: const Text('Write a Review'),
                ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.rating,
    required this.comment,
    required this.author,
    required this.createdAt,
  });
  final int rating;
  final String comment;
  final String author;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= rating ? Icons.star : Icons.star_border,
                  size: 14,
                  color: i <= rating
                      ? Colors.amber.shade700
                      : muted,
                ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(comment, style: text.bodyMedium),
          ],
          const SizedBox(height: 2),
          Text('$author · ${formatDate(createdAt)}',
              style: text.bodySmall?.copyWith(color: muted)),
        ],
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.stationId});
  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite =
        ref.watch(favoritesProvider).contains(stationId);
    return IconButton(
      tooltip: isFavorite ? 'Remove favorite' : 'Save favorite',
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Theme.of(context).colorScheme.error : null,
      ),
      onPressed: () async {
        try {
          await ref.read(favoritesProvider.notifier).toggle(stationId);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e is AppException
                    ? e.userMessage
                    : 'Could not save favorite.')),
          );
        }
      },
    );
  }
}

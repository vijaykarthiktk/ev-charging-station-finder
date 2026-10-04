import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/connector_type.dart';
import '../../models/vehicle_profile.dart';
import '../../providers/spending_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/screen_header.dart';
import 'profile_screen.dart';

/// Profile tab: garage header plus owned vehicles. The active vehicle
/// (radio) drives session estimates and connector matching.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garage = ref.watch(vehicleProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const ScreenHeader(title: 'Profile'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/images/ev_car.svg',
                      height: 120,
                      semanticsLabel: 'Electric car charging',
                    ),
                    const SizedBox(height: 8),
                    Text('My Garage',
                        style: text.titleMedium?.copyWith(
                            color: scheme.onPrimaryContainer)),
                    Text(
                      garage.vehicles.isEmpty
                          ? 'Add your EV for accurate estimates'
                          : '${garage.vehicles.length} vehicle${garage.vehicles.length == 1 ? '' : 's'} · ${garage.active?.name ?? ''} active',
                      style: text.bodySmall?.copyWith(
                          color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final v in garage.vehicles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _VehicleCard(vehicle: v),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  ),
                  child: const Text('Add Vehicle'),
                ),
              ),
              const SizedBox(height: 24),
              Text('Charging Stats', style: text.titleMedium),
              const SizedBox(height: 8),
              _StatsGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends ConsumerWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(spendingSummaryProvider);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: [
        _StatTile(
            value: '${stats.sessions}',
            label: 'Sessions'),
        _StatTile(
            value: formatKwh(stats.energyKwh), label: 'Energy'),
        _StatTile(
            value: formatRupees(stats.spent), label: 'Spent'),
        _StatTile(
            value: stats.topStation ?? '—', label: 'Top station'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(label,
                style: text.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends ConsumerWidget {
  const _VehicleCard({required this.vehicle});
  final VehicleProfile vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final selected =
        ref.watch(vehicleProvider).active?.id == vehicle.id;
    return Card(
      child: InkWell(
        onTap: () => _select(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.name, style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${vehicle.batteryKwh.round()} kWh · ${vehicle.connector.label}',
                      style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit vehicle',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          ProfileScreen(vehicle: vehicle)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _select(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(vehicleProvider.notifier).selectVehicle(vehicle.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e is AppException
                ? e.userMessage
                : 'Could not select vehicle.')),
      );
    }
  }
}

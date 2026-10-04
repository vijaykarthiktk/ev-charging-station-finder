import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../models/connector_type.dart';
import '../../models/vehicle_profile.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/screen_header.dart';

/// Add or edit one garage vehicle: name, battery capacity, connector.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.vehicle});

  /// Null adds a new vehicle; non-null edits it in place.
  final VehicleProfile? vehicle;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;
  late double _batteryKwh;
  late ConnectorType _connector;

  bool get _editing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _nameController = TextEditingController(text: v?.name ?? '');
    _batteryKwh = v?.batteryKwh ?? 40;
    _connector = v?.connector ?? ConnectorType.ccs2;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
              ScreenHeader(
                  title: _editing ? 'Edit Vehicle' : 'Add Vehicle',
                  showBack: true),
              const SizedBox(height: 20),
              Text('Vehicle name', style: text.bodyMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Nexon EV',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Battery capacity', style: text.bodyMedium),
              const SizedBox(height: 4),
              Text('${_batteryKwh.round()} kWh',
                  style: text.titleLarge),
              Slider(
                value: _batteryKwh,
                min: 20,
                max: 100,
                divisions: 80,
                label: '${_batteryKwh.round()} kWh',
                onChanged: (v) =>
                    setState(() => _batteryKwh = v),
              ),
              const SizedBox(height: 16),
              Text('Connector', style: text.bodyMedium),
              const SizedBox(height: 8),
              SegmentedButton<ConnectorType>(
                segments: [
                  for (final c in ConnectorType.values)
                    ButtonSegment(value: c, label: Text(c.label)),
                ],
                selected: {_connector},
                onSelectionChanged: (s) =>
                    setState(() => _connector = s.first),
              ),
              const SizedBox(height: 12),
              Text(
                'Used for session cost estimates and connector matching.',
                style: text.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  onPressed: _save,
                  child:
                      Text(_editing ? 'Save Changes' : 'Add Vehicle'),
                ),
              ),
              const SizedBox(height: 4),
              if (_editing)
                Center(
                  child: TextButton(
                    onPressed: _remove,
                    child: const Text('Remove vehicle'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final notifier = ref.read(vehicleProvider.notifier);
    try {
      if (_editing) {
        await notifier.updateVehicle(VehicleProfile(
          id: widget.vehicle!.id,
          name: _nameController.text,
          batteryKwh: _batteryKwh.roundToDouble(),
          connector: _connector,
        ));
      } else {
        await notifier.addVehicle(
          name: _nameController.text,
          batteryKwh: _batteryKwh.roundToDouble(),
          connector: _connector,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _editing ? 'Vehicle updated.' : 'Vehicle added.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e is AppException
                ? e.userMessage
                : 'Something went wrong. Please try again.')),
      );
    }
  }

  Future<void> _remove() async {
    try {
      await ref
          .read(vehicleProvider.notifier)
          .removeVehicle(widget.vehicle!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle removed.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove vehicle.')),
      );
    }
  }
}

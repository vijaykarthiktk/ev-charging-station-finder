import 'package:flutter/material.dart';

import '../models/availability_status.dart';

/// Availability as color + icon + text (never color alone).
class AvailabilityIndicator extends StatelessWidget {
  const AvailabilityIndicator({super.key, required this.status, this.large = false});

  final AvailabilityStatus status;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = large
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: large ? 12 : 9,
          height: large ? 12 : 9,
          decoration:
              BoxDecoration(color: status.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Icon(status.icon, size: large ? 20 : 16, color: status.color),
        const SizedBox(width: 4),
        Text(
          status.label,
          style: style?.copyWith(
            color: status.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../models/charger_type.dart';

/// Distinct pill per charger type: text + icon + tinted background.
class ChargerBadge extends StatelessWidget {
  const ChargerBadge({super.key, required this.type, this.compact = false});

  final ChargerType type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: type.badgeColor(scheme),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon,
              size: compact ? 13 : 15, color: type.onBadgeColor(scheme)),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: (compact
                    ? Theme.of(context).textTheme.labelSmall
                    : Theme.of(context).textTheme.labelMedium)
                ?.copyWith(
              color: type.onBadgeColor(scheme),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Figma-style in-body header: title row + optional "Step N of 4" caption.
/// Screens render this instead of an AppBar to match the prototype.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.trailing,
    this.step,
    this.stepLabel,
  });

  final String title;
  final bool showBack;
  final Widget? trailing;
  final int? step;
  final String? stepLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (showBack)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.chevron_left, size: 28),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            Expanded(
              child: Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 20)),
            ),
            if (trailing case final Widget t) t,
          ],
        ),
        if (step != null && stepLabel != null) ...[
          const SizedBox(height: 4),
          StepCaption(step: step!, label: stepLabel!),
        ],
      ],
    );
  }
}

/// "Step 2 of 4 · Select Slot" progress cue used on every booking screen.
class StepCaption extends StatelessWidget {
  const StepCaption({super.key, required this.step, required this.label});

  final int step;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Step $step of 4 · $label',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

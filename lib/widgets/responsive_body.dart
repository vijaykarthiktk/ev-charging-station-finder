import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Centers content and caps its width on tablets/desktop. No hard-coded
/// screen dimensions — adapts to whatever constraints arrive.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: maxWidth ?? AppConstants.maxContentWidth),
        child: child,
      ),
    );
  }
}

/// True on tablets/desktop widths.
bool isWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= AppConstants.wideLayoutBreakpoint;

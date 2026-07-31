import 'package:flutter/material.dart';

/// P4.4: fixed-width financial displays (the dashboard's hero balance
/// number in particular) were built assuming a fairly narrow range of
/// system text scale. At the OS's largest accessibility settings
/// (TextScaler.linear(2.0)+) an uncapped scale factor could make a long
/// balance value clip past legibility despite its ellipsis fallback.
/// Clamping still lets low-vision users get meaningfully larger text (up to
/// 1.6x) without letting the extreme end of the range break constrained
/// layouts throughout the app.
class TextScaleClamp extends StatelessWidget {
  const TextScaleClamp({
    super.key,
    required this.child,
    this.minScaleFactor = 0.85,
    this.maxScaleFactor = 1.6,
  });

  final Widget child;
  final double minScaleFactor;
  final double maxScaleFactor;

  @override
  Widget build(BuildContext context) {
    final clamped = MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: minScaleFactor,
      maxScaleFactor: maxScaleFactor,
    );
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: clamped),
      child: child,
    );
  }
}

import 'package:flutter/widgets.dart';

/// Renders a numeric value as text that smoothly counts up or down whenever the
/// value changes — e.g. an account balance after a transaction is added.
///
/// Deliberately understated: it does **not** animate on first build (so screens
/// don't "roll up" on load), only on subsequent value changes, over a short
/// ease-out. This keeps the effect professional rather than flashy.
class AnimatedCountText extends StatelessWidget {
  const AnimatedCountText({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.duration = const Duration(milliseconds: 420),
    this.curve = Curves.easeOutCubic,
  });

  /// The current numeric value to display.
  final double value;

  /// Formats an interpolated value into the displayed string (e.g. currency).
  final String Function(double value) formatter;

  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    // A Tween with a null `begin` makes TweenAnimationBuilder skip the initial
    // animation and, on each rebuild with a new `end`, tween from the currently
    // displayed value to the new value.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, _) {
        return Text(
          formatter(animatedValue),
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

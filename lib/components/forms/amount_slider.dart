import 'package:flutter/material.dart';

class AmountSlider extends StatelessWidget {
  const AmountSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.labelBuilder,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final String Function(double value)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: value.clamp(min, max),
      min: min,
      max: max,
      divisions: divisions,
      label: labelBuilder?.call(value),
      onChanged: onChanged,
    );
  }
}

import 'package:flutter/material.dart';

enum RiskLevel { low, medium, high }

class RiskIndicator extends StatelessWidget {
  const RiskIndicator({
    super.key,
    required this.level,
    this.label,
  });

  final RiskLevel level;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (tone, text) = switch (level) {
      RiskLevel.low => (Colors.green, label ?? 'Low risk'),
      RiskLevel.medium => (Colors.orange, label ?? 'Medium risk'),
      RiskLevel.high => (colorScheme.error, label ?? 'High risk'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withOpacity( 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_rounded, size: 14, color: tone),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

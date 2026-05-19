import 'package:flutter/material.dart';

class AlertBanner extends StatelessWidget {
  final String message;
  final Color color;

  const AlertBanner({super.key, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withAlpha(31),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}





import 'package:flutter/material.dart';

class AppSheetContainer extends StatelessWidget {
  const AppSheetContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modalBackgroundColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surface;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: modalBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity( 0.15),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        // Inner transparent Material sits BELOW the colored box so ListTile /
        // SwitchListTile descendants paint their background + ink on it rather
        // than on the outer Material (which the colored box would otherwise
        // cover — Flutter 3.44 asserts on that).
        child: Material(
          type: MaterialType.transparency,
          child: child,
        ),
      ),
    );
  }
}

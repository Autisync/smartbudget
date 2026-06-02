import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class AppBottomAction {
  const AppBottomAction({
    required this.value,
    required this.label,
    this.icon,
    this.destructive = false,
    this.enabled = true,
  });

  final String value;
  final String label;
  final IconData? icon;
  final bool destructive;
  final bool enabled;
}

class AppBottomActionSheet extends StatelessWidget {
  const AppBottomActionSheet({
    super.key,
    required this.title,
    required this.actions,
  });

  final String title;
  final List<AppBottomAction> actions;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<AppBottomAction> actions,
  }) {
    return showCupertinoModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      expand: false,
      builder: (_) => AppBottomActionSheet(
        title: title,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.72;
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...actions.map((action) {
                  final color = action.destructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface;
                  return ListTile(
                    enabled: action.enabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: action.icon == null
                        ? null
                        : Icon(action.icon, color: color),
                    title: Text(
                      action.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: action.destructive
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    onTap: action.enabled
                        ? () => Navigator.of(context).pop(action.value)
                        : null,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:smartbudget/components/sheets/app_bottom_action_sheet.dart';

class AppActionItem {
  const AppActionItem({
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

class AppActionMenu extends StatelessWidget {
  const AppActionMenu({
    super.key,
    required this.title,
    required this.items,
    required this.onSelected,
    this.tooltip,
  });

  final String title;
  final List<AppActionItem> items;
  final ValueChanged<String> onSelected;
  final String? tooltip;

  bool _useBottomSheet(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    return shortestSide < 600;
  }

  Future<void> _openBottomSheet(BuildContext context) async {
    final selected = await AppBottomActionSheet.show(
      context,
      title: title,
      actions: items
          .map(
            (item) => AppBottomAction(
              value: item.value,
              label: item.label,
              icon: item.icon,
              destructive: item.destructive,
              enabled: item.enabled,
            ),
          )
          .toList(growable: false),
    );
    if (selected != null) {
      onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconButton = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.more_horiz,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    if (_useBottomSheet(context)) {
      return Tooltip(
        message: tooltip ?? title,
        child: IconButton(
          onPressed: () => _openBottomSheet(context),
          icon: iconButton,
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: tooltip ?? title,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 10,
      color: theme.colorScheme.surface,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      position: PopupMenuPosition.under,
      icon: iconButton,
      onSelected: onSelected,
      itemBuilder: (_) => items
          .map(
            (item) => PopupMenuItem<String>(
              value: item.value,
              enabled: item.enabled,
              child: Row(
                children: [
                  if (item.icon != null)
                    Icon(
                      item.icon,
                      size: 18,
                      color: item.destructive
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ),
                  if (item.icon != null) const SizedBox(width: 10),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: item.destructive
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          item.destructive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

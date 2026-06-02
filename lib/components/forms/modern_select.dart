import 'package:flutter/material.dart';
import 'package:smartbudget/components/forms/app_select_field.dart';

class ModernSelect<T> extends StatelessWidget {
  const ModernSelect({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.helperText,
    this.prefixIcon,
    this.searchable = false,
    this.searchHintText,
  });

  final T value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? helperText;
  final IconData? prefixIcon;
  final bool searchable;
  final String? searchHintText;

  @override
  Widget build(BuildContext context) {
    return AppSelectField<T>(
      value: value,
      label: label,
      helperText: helperText,
      prefixIcon: prefixIcon,
      searchable: searchable,
      searchHintText: searchHintText,
      options: items
          .map(
            (item) => AppDropdownOption<T>(
              value: item.value as T,
              label: _labelForItem(item.child),
              leading: _leadingForItem(item.child),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
    );
  }

  String _labelForItem(Widget child) {
    if (child is Text) {
      return child.data ?? '';
    }
    if (child is Row) {
      for (final rowChild in child.children) {
        if (rowChild is Text) {
          return rowChild.data ?? '';
        }
      }
    }
    return child.toStringShort();
  }

  Widget? _leadingForItem(Widget child) {
    if (child is Row && child.children.isNotEmpty) {
      final first = child.children.first;
      if (first is Icon) {
        return Icon(first.icon, size: first.size, color: first.color);
      }
    }
    return null;
  }
}

class ModernDropdown<T> extends ModernSelect<T> {
  const ModernDropdown({
    super.key,
    required super.value,
    required super.label,
    required super.items,
    required super.onChanged,
    super.helperText,
    super.prefixIcon,
    super.searchable,
    super.searchHintText,
  });
}

import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:smartbudget/core/theme/input_styles.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({
    required this.value,
    required this.label,
    this.leading,
  });

  final T value;
  final String label;
  final Widget? leading;
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.menuMaxHeight = 320,
  });

  final T value;
  final List<AppDropdownOption<T>> options;
  final ValueChanged<T?> onChanged;
  final double menuMaxHeight;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: menuMaxHeight,
      borderRadius: BorderRadius.circular(18),
      icon: InputStyles.dropdownIcon(context),
      items: options
          .map(
            (option) => DropdownMenuItem<T>(
              value: option.value,
              child: Row(
                children: [
                  if (option.leading != null) ...[
                    option.leading!,
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      option.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
    );
  }
}

class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.value,
    required this.label,
    required this.options,
    required this.onChanged,
    this.helperText,
    this.prefixIcon,
    this.searchable = false,
    this.searchHintText,
  });

  final T value;
  final String label;
  final List<AppDropdownOption<T>> options;
  final ValueChanged<T?> onChanged;
  final String? helperText;
  final IconData? prefixIcon;
  final bool searchable;
  final String? searchHintText;

  @override
  Widget build(BuildContext context) {
    if (searchable) {
      return _SearchableSelectField<T>(
        value: value,
        label: label,
        options: options,
        onChanged: onChanged,
        helperText: helperText,
        prefixIcon: prefixIcon,
        searchHintText: searchHintText,
      );
    }

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(18),
          icon: InputStyles.dropdownIcon(context),
          items: options
              .map(
                (option) => DropdownMenuItem<T>(
                  value: option.value,
                  child: Row(
                    children: [
                      if (option.leading != null) ...[
                        option.leading!,
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SearchableSelectField<T> extends StatelessWidget {
  const _SearchableSelectField({
    required this.value,
    required this.label,
    required this.options,
    required this.onChanged,
    this.helperText,
    this.prefixIcon,
    this.searchHintText,
  });

  final T value;
  final String label;
  final List<AppDropdownOption<T>> options;
  final ValueChanged<T?> onChanged;
  final String? helperText;
  final IconData? prefixIcon;
  final String? searchHintText;

  @override
  Widget build(BuildContext context) {
    final selected = options.where((option) => option.value == value);
    final selectedLabel = selected.isEmpty ? '' : selected.first.label;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final picked = await showCupertinoModalBottomSheet<T>(
          context: context,
          expand: false,
          builder: (sheetContext) => _SearchableSelectSheet<T>(
            title: label,
            options: options,
            initialValue: value,
            searchHintText: searchHintText,
          ),
        );

        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
          suffixIcon: InputStyles.dropdownIcon(context),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchableSelectSheet<T> extends StatefulWidget {
  const _SearchableSelectSheet({
    required this.title,
    required this.options,
    required this.initialValue,
    this.searchHintText,
  });

  final String title;
  final List<AppDropdownOption<T>> options;
  final T initialValue;
  final String? searchHintText;

  @override
  State<_SearchableSelectSheet<T>> createState() =>
      _SearchableSelectSheetState<T>();
}

class _SearchableSelectSheetState<T> extends State<_SearchableSelectSheet<T>> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.options
        : widget.options
            .where(
              (option) => option.label.toLowerCase().contains(query),
            )
            .toList(growable: false);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: widget.searchHintText ?? 'Search options',
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final option = filtered[index];
                      final selected = option.value == widget.initialValue;
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: option.leading,
                        title: Text(option.label),
                        trailing: selected
                            ? Icon(
                                Icons.check_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(option.value),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

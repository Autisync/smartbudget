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
    return AppSelectField<T>(
      value: value,
      label: '',
      options: options,
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
    final selected = options.where((option) => option.value == value);
    final selectedOption = selected.isEmpty ? null : selected.first;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final picked = await showCupertinoModalBottomSheet<T>(
          context: context,
          expand: false,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => _SelectSheet<T>(
            title: label,
            options: options,
            initialValue: value,
            searchable: searchable,
            searchHintText: searchHintText,
          ),
        );

        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label.isEmpty ? null : label,
          helperText: helperText,
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
          suffixIcon: InputStyles.dropdownIcon(context),
        ),
        child: Row(
          children: [
            if (selectedOption?.leading != null) ...[
              selectedOption!.leading!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                selectedOption?.label ?? '',
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

class _SelectSheet<T> extends StatefulWidget {
  const _SelectSheet({
    required this.title,
    required this.options,
    required this.initialValue,
    required this.searchable,
    this.searchHintText,
  });

  final String title;
  final List<AppDropdownOption<T>> options;
  final T initialValue;
  final bool searchable;
  final String? searchHintText;

  @override
  State<_SelectSheet<T>> createState() => _SelectSheetState<T>();
}

class _SelectSheetState<T> extends State<_SelectSheet<T>> {
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity( 0.18),
              blurRadius: 28,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: SizedBox(
              height: widget.searchable
                  ? MediaQuery.sizeOf(context).height * 0.72
                  : null,
              child: Column(
                mainAxisSize:
                    widget.searchable ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withOpacity( 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  if (widget.searchable) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.searchHintText ?? 'Search options',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: widget.searchHintText ?? 'Search options',
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Flexible(
                    fit: widget.searchable ? FlexFit.tight : FlexFit.loose,
                    child: ListView.separated(
                      shrinkWrap: !widget.searchable,
                      physics: widget.searchable
                          ? null
                          : const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        final selected = option.value == widget.initialValue;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).pop(option.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? colorScheme.primaryContainer
                                      .withOpacity( 0.55)
                                  : colorScheme.surfaceContainerHighest
                                      .withOpacity( 0.42),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? colorScheme.primary
                                        .withOpacity( 0.32)
                                    : colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (option.leading != null) ...[
                                  option.leading!,
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Text(
                                    option.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No options found',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

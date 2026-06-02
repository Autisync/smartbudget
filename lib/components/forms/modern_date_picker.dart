import 'package:flutter/material.dart';
import 'package:smartbudget/core/widgets/form_date_field.dart';

class ModernDatePicker extends StatelessWidget {
  const ModernDatePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return FormDateField(
      label: label,
      value: value,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

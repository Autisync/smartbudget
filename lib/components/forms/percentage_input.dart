import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartbudget/components/forms/financial_input.dart';

class PercentageInput extends StatelessWidget {
  const PercentageInput({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return FinancialInput(
      controller: controller,
      label: label,
      validator: validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      suffixIcon: Icons.percent_rounded,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
    );
  }
}

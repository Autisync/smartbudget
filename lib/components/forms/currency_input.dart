import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/components/forms/financial_input.dart';

class CurrencyInput extends StatelessWidget {
  const CurrencyInput({
    super.key,
    required this.controller,
    required this.label,
    required this.currencySymbol,
    this.helperText,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String currencySymbol;
  final String? helperText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return FinancialInput(
      controller: controller,
      label: label,
      helperText: helperText,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      onChanged: onChanged,
      prefixText: '$currencySymbol ',
      hintText: '0.00',
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        _CurrencyTextFormatter(),
      ],
    );
  }
}

class _CurrencyTextFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,##0.##');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text;
    if (rawText.isEmpty) {
      return newValue;
    }

    final parts = rawText.split('.');
    final hasDecimal = parts.length > 1;
    final integerRaw = parts.first.replaceAll(',', '');
    final integerValue = int.tryParse(integerRaw);
    if (integerValue == null) {
      return oldValue;
    }

    final formattedInt = _formatter.format(integerValue);
    String finalText = formattedInt;

    if (hasDecimal) {
      final decimalPart = parts.sublist(1).join();
      finalText =
          '$formattedInt.${decimalPart.substring(0, decimalPart.length.clamp(0, 2))}';
    }

    return TextEditingValue(
      text: finalText,
      selection: TextSelection.collapsed(offset: finalText.length),
    );
  }
}

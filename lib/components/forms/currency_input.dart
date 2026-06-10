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
    this.decimalDigits = 2,
    this.allowNegative = false,
  });

  final TextEditingController controller;
  final String label;
  final String currencySymbol;
  final String? helperText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  /// Number of decimal places permitted, driven by the active currency's minor
  /// units (ISO 4217): 0 for JPY, 3 for some Gulf currencies, 2 by default.
  final int decimalDigits;

  /// Allow a leading minus so liability accounts (credit cards, overdrafts) and
  /// negative opening balances can be entered.
  final bool allowNegative;

  @override
  Widget build(BuildContext context) {
    final pattern = allowNegative ? r'[0-9.,-]' : r'[0-9.,]';
    return FinancialInput(
      controller: controller,
      label: label,
      helperText: helperText,
      keyboardType: TextInputType.numberWithOptions(
        decimal: decimalDigits > 0,
        signed: allowNegative,
      ),
      validator: validator,
      onChanged: onChanged,
      prefixText: '$currencySymbol ',
      hintText: decimalDigits > 0 ? '0.00' : '0',
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(pattern)),
        _CurrencyTextFormatter(
          decimalDigits: decimalDigits,
          allowNegative: allowNegative,
        ),
      ],
    );
  }
}

class _CurrencyTextFormatter extends TextInputFormatter {
  _CurrencyTextFormatter({
    required this.decimalDigits,
    required this.allowNegative,
  });

  final int decimalDigits;
  final bool allowNegative;

  final NumberFormat _formatter = NumberFormat('#,##0.##');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var rawText = newValue.text;
    if (rawText.isEmpty) {
      return newValue;
    }

    // Keep only a single leading minus when negatives are allowed.
    var negative = false;
    if (allowNegative && rawText.contains('-')) {
      negative = rawText.startsWith('-');
      rawText = rawText.replaceAll('-', '');
      if (rawText.isEmpty) {
        return const TextEditingValue(
          text: '-',
          selection: TextSelection.collapsed(offset: 1),
        );
      }
    }

    final parts = rawText.split('.');
    final hasDecimal = parts.length > 1 && decimalDigits > 0;
    final integerRaw = parts.first.replaceAll(',', '');
    final integerValue = int.tryParse(integerRaw.isEmpty ? '0' : integerRaw);
    if (integerValue == null) {
      return oldValue;
    }

    final formattedInt = _formatter.format(integerValue);
    String finalText = formattedInt;

    if (hasDecimal) {
      final decimalPart = parts.sublist(1).join();
      final clamped =
          decimalPart.substring(0, decimalPart.length.clamp(0, decimalDigits));
      finalText = '$formattedInt.$clamped';
    }

    if (negative) finalText = '-$finalText';

    return TextEditingValue(
      text: finalText,
      selection: TextSelection.collapsed(offset: finalText.length),
    );
  }
}

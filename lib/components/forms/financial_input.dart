import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModernInput extends StatelessWidget {
  const ModernInput({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.helperText,
    this.validator,
    this.keyboardType,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.onChanged,
    this.inputFormatters,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? helperText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? prefixText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final fillColor = brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final borderColor = brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.10);

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: maxLines,
      minLines: 1,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        prefixText: prefixText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.6,
          ),
        ),
      ),
    );
  }
}

class FinancialInput extends ModernInput {
  const FinancialInput({
    super.key,
    required super.controller,
    required super.label,
    super.hintText,
    super.helperText,
    super.validator,
    super.keyboardType,
    super.prefixText,
    super.prefixIcon,
    super.suffixIcon,
    super.maxLines,
    super.onChanged,
    super.inputFormatters,
    super.textInputAction,
  });
}

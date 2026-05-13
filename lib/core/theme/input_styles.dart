import 'package:flutter/material.dart';

class InputStyles {
  static const double fieldRadius = 14;
  static const double fieldSpacing = 16;
  static const EdgeInsets fieldPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 18,
  );

  static Color inputFill(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF232838)
        : const Color(0xFFF5F5F5);
  }

  static Color labelColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : Colors.grey.shade500;
  }

  static Color dropdownIconColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : Colors.grey.shade600;
  }

  static Color inputTextColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFFF8FAFC)
        : Colors.grey.shade900;
  }

  static TextStyle inputTextStyle(ThemeData theme) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: inputTextColor(theme.brightness),
      height: 1.2,
    );
  }

  static TextStyle supportingTextStyle(ThemeData theme) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: labelColor(theme.brightness),
    );
  }

  static InputDecorationTheme inputDecorationTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color errorColor,
  }) {
    final neutral = labelColor(brightness);
    return InputDecorationTheme(
      filled: true,
      fillColor: inputFill(brightness),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: _border(color: Colors.transparent),
      enabledBorder: _border(color: Colors.transparent),
      disabledBorder: _border(color: Colors.transparent),
      focusedBorder: _border(color: primaryColor, width: 2),
      errorBorder: _border(color: errorColor, width: 2),
      focusedErrorBorder: _border(color: errorColor, width: 2),
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: neutral,
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primaryColor,
      ),
      hintStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: neutral,
      ),
      prefixIconColor: neutral,
      suffixIconColor: neutral,
      contentPadding: fieldPadding,
    );
  }

  static SliderThemeData sliderTheme({
    required Color primaryColor,
    required Color inactiveColor,
  }) {
    return SliderThemeData(
      trackHeight: 4,
      activeTrackColor: primaryColor,
      inactiveTrackColor: inactiveColor,
      overlayColor: primaryColor.withValues(alpha: 0.12),
      thumbColor: Colors.white,
      thumbShape: const _InputSliderThumbShape(),
      showValueIndicator: ShowValueIndicator.onDrag,
      valueIndicatorColor: primaryColor,
      valueIndicatorTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static Widget dropdownIcon(BuildContext context) {
    return Icon(
      Icons.keyboard_arrow_down_rounded,
      color: dropdownIconColor(Theme.of(context).brightness),
    );
  }

  static BoxDecoration dateFieldDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: inputFill(theme.brightness),
      borderRadius: BorderRadius.circular(fieldRadius),
    );
  }

  static BoxDecoration costSummaryDecoration(BuildContext context) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration importanceBannerDecoration(Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
    );
  }

  static OutlineInputBorder _border({
    required Color color,
    double width = 0,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _InputSliderThumbShape extends RoundSliderThumbShape {
  const _InputSliderThumbShape() : super(enabledThumbRadius: 10);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    context.canvas.drawCircle(
      center + const Offset(0, 2),
      10,
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    super.paint(
      context,
      center,
      activationAnimation: activationAnimation,
      enableAnimation: enableAnimation,
      isDiscrete: isDiscrete,
      labelPainter: labelPainter,
      parentBox: parentBox,
      sliderTheme: sliderTheme.copyWith(thumbColor: Colors.white),
      textDirection: textDirection,
      value: value,
      textScaleFactor: textScaleFactor,
      sizeWithOverflow: sizeWithOverflow,
    );
  }
}

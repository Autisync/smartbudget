import 'package:flutter/widgets.dart';

class UiTokens {
  const UiTokens._();

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(16, 16, 16, 100);
  static const EdgeInsets screenPaddingScrollable =
      EdgeInsets.fromLTRB(16, 16, 16, 120);

  static EdgeInsets adaptiveScreenPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottom = width >= 900 ? 24.0 : 80.0;
    return EdgeInsets.fromLTRB(16, 16, 16, safeBottom + bottom);
  }

  static EdgeInsets adaptiveScrollablePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottom = width >= 900 ? 28.0 : 100.0;
    return EdgeInsets.fromLTRB(16, 16, 16, safeBottom + bottom);
  }

  static const double sectionGapSm = 12;
  static const double sectionGapMd = 16;
  static const double sectionGapLg = 24;
  static const double sectionGapXl = 28;

  static const double radiusMd = 16;
  static const double radiusLg = 18;
  static const double radiusXl = 22;

  static const double chipSpacing = 8;
  static const double chipRunSpacing = 8;
}

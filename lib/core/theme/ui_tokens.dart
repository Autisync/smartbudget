import 'package:flutter/widgets.dart';

class UiTokens {
  const UiTokens._();

  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(20, 16, 20, 100);
  static const EdgeInsets screenPaddingScrollable =
      EdgeInsets.fromLTRB(20, 16, 20, 120);

  static EdgeInsets adaptiveScreenPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottom = width >= 900 ? 24.0 : 80.0;
    final horizontal = width >= 1200
        ? 40.0
        : width >= 700
            ? 32.0
            : 20.0;
    return EdgeInsets.fromLTRB(horizontal, 16, horizontal, safeBottom + bottom);
  }

  static EdgeInsets adaptiveScrollablePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottom = width >= 900 ? 28.0 : 100.0;
    final horizontal = width >= 1200
        ? 40.0
        : width >= 700
            ? 32.0
            : 20.0;
    return EdgeInsets.fromLTRB(horizontal, 16, horizontal, safeBottom + bottom);
  }

  static const double sectionGapSm = 12;
  static const double sectionGapMd = 16;
  static const double sectionGapLg = 24;
  static const double sectionGapXl = 28;

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radius2xl = 28;

  static const Duration motionFast = Duration(milliseconds: 160);
  static const Duration motionMedium = Duration(milliseconds: 240);
  static const Duration motionSlow = Duration(milliseconds: 360);
  static const Curve motionCurve = Cubic(0.2, 0.8, 0.2, 1);

  static const double touchTarget = 48;

  static const double chipSpacing = 8;
  static const double chipRunSpacing = 8;
}

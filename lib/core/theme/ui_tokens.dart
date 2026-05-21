import 'package:flutter/widgets.dart';
import 'package:smartbudget/core/theme/app_radius.dart';
import 'package:smartbudget/core/theme/app_spacing.dart';

class UiTokens {
  const UiTokens._();

  static const double space4 = AppSpacing.xxs;
  static const double space8 = AppSpacing.xs;
  static const double space12 = AppSpacing.sm;
  static const double space16 = AppSpacing.md;
  static const double space20 = AppSpacing.lg;
  static const double space24 = AppSpacing.xl;
  static const double space32 = AppSpacing.xxl;

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(20, 16, 20, 120);
  static const EdgeInsets screenPaddingScrollable =
      EdgeInsets.fromLTRB(20, 16, 20, 136);

  static EdgeInsets adaptiveScreenPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottom = width >= 900 ? 24.0 : 96.0;
    final horizontal = width >= 1200
        ? 32.0
        : width >= 700
            ? 32.0
            : 20.0;
    return EdgeInsets.fromLTRB(horizontal, 16, horizontal, safeBottom + bottom);
  }

  static EdgeInsets adaptiveScrollablePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottom = width >= 900 ? 32.0 : 112.0;
    final horizontal = width >= 1200
        ? 32.0
        : width >= 700
            ? 32.0
            : 20.0;
    return EdgeInsets.fromLTRB(horizontal, 16, horizontal, safeBottom + bottom);
  }

  static const double sectionGapSm = 12;
  static const double sectionGapMd = 16;
  static const double sectionGapLg = 24;
  static const double sectionGapXl = 28;

  static const double radiusSm = AppRadius.sm;
  static const double radiusMd = AppRadius.md;
  static const double radiusLg = AppRadius.lg;
  static const double radiusXl = AppRadius.xl;
  static const double radius2xl = AppRadius.xxl;

  static const Duration motionFast = Duration(milliseconds: 160);
  static const Duration motionMedium = Duration(milliseconds: 240);
  static const Duration motionSlow = Duration(milliseconds: 360);
  static const Curve motionCurve = Cubic(0.2, 0.8, 0.2, 1);

  static const double touchTarget = 48;

  static const double chipSpacing = 8;
  static const double chipRunSpacing = 8;
}

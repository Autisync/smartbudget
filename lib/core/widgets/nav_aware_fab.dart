import 'package:flutter/material.dart';

double navAwareFabBottomPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 900) {
    return 16;
  }

  final safeBottom = MediaQuery.paddingOf(context).bottom;
  final baseOffset = width < 780 ? 76.0 : 56.0;
  return baseOffset + (safeBottom * 0.35);
}

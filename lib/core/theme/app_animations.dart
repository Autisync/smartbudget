import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  const AppAnimations._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 340);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve standard = Curves.easeOut;

  static List<Effect<dynamic>> cardEntrance({Duration? delay}) {
    return [
      FadeEffect(
        duration: normal,
        delay: delay ?? Duration.zero,
        curve: emphasized,
        begin: 0,
        end: 1,
      ),
      MoveEffect(
        duration: normal,
        delay: delay ?? Duration.zero,
        curve: emphasized,
        begin: const Offset(0, 8),
        end: Offset.zero,
      ),
    ];
  }

  static Widget sharedAxis({
    required Widget child,
    required Animation<double> primary,
    required Animation<double> secondary,
    SharedAxisTransitionType type = SharedAxisTransitionType.scaled,
  }) {
    return SharedAxisTransition(
      animation: primary,
      secondaryAnimation: secondary,
      transitionType: type,
      fillColor: Colors.transparent,
      child: child,
    );
  }
}

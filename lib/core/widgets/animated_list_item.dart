import 'package:flutter/material.dart';

/// Wraps a list item in a staggered slide-up + fade entrance animation.
///
/// Stagger delay = [index] × [staggerMs] (capped at [maxDelayMs]).
/// After the animation completes the widget stays at full opacity with no
/// transform overhead — the controller is disposed automatically.
///
/// Usage:
/// ```dart
/// ListView.builder(
///   itemBuilder: (ctx, i) => AnimatedListItem(
///     index: i,
///     child: MyTile(items[i]),
///   ),
/// )
/// ```
class AnimatedListItem extends StatefulWidget {
  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.staggerMs = 55,
    this.maxDelayMs = 400,
    this.durationMs = 380,
    this.slideOffsetY = 22.0,
    this.curve = Curves.easeOutCubic,
  });

  final int index;
  final Widget child;
  final int staggerMs;
  final int maxDelayMs;
  final int durationMs;
  final double slideOffsetY;
  final Curve curve;

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );

    final curved =
        CurvedAnimation(parent: _ctrl, curve: widget.curve);

    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideOffsetY),
      end: Offset.zero,
    ).animate(curved);

    final delayMs =
        (widget.index * widget.staggerMs).clamp(0, widget.maxDelayMs);

    if (delayMs == 0) {
      _ctrl.forward();
    } else {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      child: widget.child,
      builder: (context, child) => FadeTransition(
        opacity: _opacity,
        child: Transform.translate(
          offset: _slide.value,
          child: child,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

/// Shared swipe clip for Slidable and Dismissible items.
///
/// When used inside a [Slidable], the widget listens to the controller's
/// animation so the clip updates on every drag frame. When used outside a
/// Slidable, an explicit [swipeDirection] can be provided for Dismissible.
class SwipeableCard extends StatefulWidget {
  const SwipeableCard({
    super.key,
    required this.radius,
    required this.child,
    this.swipeDirection,
  });

  final double radius;
  final Widget child;
  final DismissDirection? swipeDirection;

  static BorderRadius borderRadiusForPaneType(
    ActionPaneType paneType,
    double radius,
  ) {
    return switch (paneType) {
      ActionPaneType.start => BorderRadius.horizontal(
          left: Radius.zero,
          right: Radius.circular(radius),
        ),
      ActionPaneType.end => BorderRadius.horizontal(
          left: Radius.circular(radius),
          right: Radius.zero,
        ),
      ActionPaneType.none => BorderRadius.circular(radius),
    };
  }

  static BorderRadius borderRadiusForDismissDirection(
    DismissDirection? direction,
    double radius,
  ) {
    return switch (direction) {
      DismissDirection.startToEnd => BorderRadius.horizontal(
          left: Radius.zero,
          right: Radius.circular(radius),
        ),
      DismissDirection.endToStart => BorderRadius.horizontal(
          left: Radius.circular(radius),
          right: Radius.zero,
        ),
      _ => BorderRadius.circular(radius),
    };
  }

  @override
  State<SwipeableCard> createState() => _SlidableEdgeClipState();
}

class _SlidableEdgeClipState extends State<SwipeableCard> {
  SlidableController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPaneType();
  }

  void _syncPaneType() {
    _controller = Slidable.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller ?? Slidable.of(context);
    if (controller == null) {
      return ClipRRect(
        borderRadius: SwipeableCard.borderRadiusForDismissDirection(
          widget.swipeDirection,
          widget.radius,
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: controller.animation,
      child: widget.child,
      builder: (context, child) {
        final borderRadius = SwipeableCard.borderRadiusForPaneType(
          controller.actionPaneType.value,
          widget.radius,
        );

        return ClipRRect(borderRadius: borderRadius, child: child);
      },
    );
  }
}

typedef SlidableEdgeClip = SwipeableCard;
import 'package:flutter/material.dart';

class EmptyStateCard extends StatefulWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  State<EmptyStateCard> createState() => _EmptyStateCardState();
}

class _EmptyStateCardState extends State<EmptyStateCard>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550))
      ..forward();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final cardAnim = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack));
    final iconAnim = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.15, 0.65, curve: Curves.easeOutBack));
    final textAnim = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.35, 0.9, curve: Curves.easeOut));

    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (context, child) => Transform.scale(
        scale: 0.90 + 0.10 * cardAnim.value,
        child: Opacity(opacity: cardAnim.value.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            // Floating icon
            AnimatedBuilder(
              animation: Listenable.merge([iconAnim, _floatCtrl]),
              builder: (context, _) {
                final floatY = (_floatCtrl.value * 2 - 1) * 4;
                return Transform.translate(
                  offset: Offset(0, floatY),
                  child: Transform.scale(
                    scale: iconAnim.value,
                    child: Opacity(
                      opacity: iconAnim.value.clamp(0.0, 1.0),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color:
                              colorScheme.primary.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(widget.icon,
                            size: 26, color: colorScheme.primary),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Text
            AnimatedBuilder(
              animation: textAnim,
              builder: (context, child) => Opacity(
                opacity: textAnim.value,
                child: Transform.translate(
                    offset: Offset(0, 10 * (1 - textAnim.value)),
                    child: child),
              ),
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (widget.action != null) ...[
                    const SizedBox(height: 14),
                    widget.action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

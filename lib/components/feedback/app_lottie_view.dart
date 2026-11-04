import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLottieView extends StatelessWidget {
  const AppLottieView({
    super.key,
    required this.assetPath,
    this.width = 120,
    this.height = 120,
    this.repeat = false,
    this.animate = true,
    this.semanticLabel,
    this.fallbackIcon = Icons.animation_outlined,
  });

  final String assetPath;
  final double width;
  final double height;
  final bool repeat;
  final bool animate;
  final String? semanticLabel;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final reducedMotion = media?.disableAnimations ?? false;
    final shouldAnimate = animate && !reducedMotion;

    final child = Lottie.asset(
      assetPath,
      width: width,
      height: height,
      repeat: repeat && shouldAnimate,
      animate: shouldAnimate,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _FallbackIcon(
        icon: fallbackIcon,
        size: width.clamp(48, 140),
      ),
    );

    if (semanticLabel == null) {
      return child;
    }
    return Semantics(
      label: semanticLabel,
      image: true,
      child: child,
    );
  }
}

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    required this.message,
    this.assetPath = 'assets/animations/loading.json',
    this.title,
  });

  final String? title;
  final String message;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLottieView(
              assetPath: assetPath,
              repeat: true,
              animate: true,
              semanticLabel: 'Loading animation',
              fallbackIcon: Icons.sync,
            ),
            const SizedBox(height: 12),
            if (title != null)
              Text(
                title!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            if (title != null) const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSuccessState extends StatelessWidget {
  const AppSuccessState({
    super.key,
    required this.title,
    required this.message,
    this.assetPath = 'assets/animations/success.json',
    this.action,
  });

  final String title;
  final String message;
  final String assetPath;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLottieView(
              assetPath: assetPath,
              semanticLabel: 'Success animation',
              fallbackIcon: Icons.check_circle_rounded,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            if (action != null) ...[
              const SizedBox(height: 14),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class AppAnimatedSuccessState extends AppSuccessState {
  const AppAnimatedSuccessState({
    super.key,
    required super.title,
    required super.message,
    super.assetPath = 'assets/animations/success.json',
    super.action,
  });
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.assetPath = 'assets/animations/error.json',
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLottieView(
              assetPath: assetPath,
              semanticLabel: 'Error animation',
              fallbackIcon: Icons.error_outline_rounded,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppAnimatedWarningState extends StatelessWidget {
  const AppAnimatedWarningState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.assetPath = 'assets/animations/warning.json',
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLottieView(
              assetPath: assetPath,
              semanticLabel: 'Warning animation',
              fallbackIcon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppAnimatedEmptyState extends StatelessWidget {
  const AppAnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.lottieAsset,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final String? lottieAsset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lottieAsset != null)
              AppLottieView(
                assetPath: lottieAsset!,
                semanticLabel: '$title animation',
                fallbackIcon: icon,
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 34, color: scheme.primary),
              ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: scheme.primary),
    );
  }
}

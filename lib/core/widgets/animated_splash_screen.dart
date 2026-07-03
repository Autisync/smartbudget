import 'package:flutter/material.dart';

/// A lively, white-background splash shown on the `/splash` route while the app
/// boots. The logo fades and springs in over a soft pulsing halo, the wordmark
/// rises in beneath it, and a slim gradient bar sweeps to signal progress.
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({
    super.key,
    this.label = 'Getting things ready…',
  });

  final String label;

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;
  late final AnimationController _sweep;

  static const _brand = Color(0xFF4F5FA7);

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoScale = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );
    final logoFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    final textAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing halo behind the logo.
                  AnimatedBuilder(
                    animation: Listenable.merge([_pulse, logoFade]),
                    builder: (context, _) {
                      final t = Curves.easeInOut.transform(_pulse.value);
                      return Opacity(
                        opacity: logoFade.value,
                        child: Container(
                          width: 130 + t * 34,
                          height: 130 + t * 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _brand.withOpacity( 0.05 + t * 0.05),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final t = Curves.easeInOut.transform(_pulse.value);
                      return Container(
                        width: 108 + t * 16,
                        height: 108 + t * 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _brand.withOpacity( 0.08),
                        ),
                      );
                    },
                  ),
                  // Logo with spring + fade entrance and gentle float.
                  AnimatedBuilder(
                    animation: Listenable.merge([logoScale, logoFade, _pulse]),
                    builder: (context, child) {
                      final float =
                          (Curves.easeInOut.transform(_pulse.value) * 2 - 1) * 4;
                      return Opacity(
                        opacity: logoFade.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, float),
                          child: Transform.scale(
                            scale: logoScale.value,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _brand.withOpacity( 0.18),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo/app_logo.png',
                        width: 76,
                        height: 76,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 64,
                          color: _brand,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Wordmark rises + fades in.
            AnimatedBuilder(
              animation: textAnim,
              builder: (context, child) => Opacity(
                opacity: textAnim.value,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - textAnim.value)),
                  child: child,
                ),
              ),
              child: const Text(
                'SmartSpend',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Color(0xFF1B2240),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: textAnim,
              builder: (context, child) =>
                  Opacity(opacity: textAnim.value, child: child),
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8A90A6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 26),
            // Sweeping gradient progress bar.
            AnimatedBuilder(
              animation: Listenable.merge([_sweep, textAnim]),
              builder: (context, _) {
                return Opacity(
                  opacity: textAnim.value,
                  child: SizedBox(
                    width: 150,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: CustomPaint(
                        painter: _SweepBarPainter(
                          progress: _sweep.value,
                          color: _brand,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SweepBarPainter extends CustomPainter {
  _SweepBarPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()..color = color.withOpacity( 0.12);
    canvas.drawRect(Offset.zero & size, track);

    // A highlight segment slides left→right, then wraps.
    const segment = 0.42;
    final start = (progress * (1 + segment)) - segment;
    final left = (start * size.width).clamp(-size.width, size.width);
    final rect = Rect.fromLTWH(left, 0, size.width * segment, size.height);
    final shimmer = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity( 0.0),
          color,
          color.withOpacity( 0.0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, shimmer);
  }

  @override
  bool shouldRepaint(covariant _SweepBarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

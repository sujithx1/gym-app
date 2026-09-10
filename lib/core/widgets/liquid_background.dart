import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/gym_theme.dart';

/// Animated background that renders soft, flowing organic liquid shapes on all sides
class LiquidBackground extends StatefulWidget {
  final Widget child;
  final bool enableBlobs;

  const LiquidBackground({
    super.key,
    required this.child,
    this.enableBlobs = true,
  });

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableBlobs) return widget.child;

    return Stack(
      children: [
        // Background Base
        Positioned.fill(
          child: Container(color: GymTheme.background),
        ),

        // Animated Liquid Blob Canvas on Top, Sides, & Bottom
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _LiquidBlobPainter(_controller.value),
              );
            },
          ),
        ),

        // Foreground Content
        widget.child,
      ],
    );
  }
}

class _LiquidBlobPainter extends CustomPainter {
  final double animationValue;

  _LiquidBlobPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final double t = animationValue * 2 * math.pi;

    // Top-Left Soft Liquid Blob (Mint)
    final paint1 = Paint()
      ..color = GymTheme.mint.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    final Offset center1 = Offset(
      size.width * 0.1 + math.sin(t) * 30,
      size.height * 0.08 + math.cos(t * 0.8) * 30,
    );
    canvas.drawCircle(center1, size.width * 0.45, paint1);

    // Top-Right Soft Liquid Blob (Lavender)
    final paint2 = Paint()
      ..color = GymTheme.lavender.withValues(alpha: 0.40)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    final Offset center2 = Offset(
      size.width * 0.85 + math.cos(t * 1.2) * 25,
      size.height * 0.25 + math.sin(t * 0.9) * 25,
    );
    canvas.drawCircle(center2, size.width * 0.40, paint2);

    // Mid-Right Soft Liquid Blob (Peach)
    final paint3 = Paint()
      ..color = GymTheme.peach.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 55);

    final Offset center3 = Offset(
      size.width * 0.9 + math.sin(t * 0.7) * 20,
      size.height * 0.6 + math.cos(t * 1.1) * 35,
    );
    canvas.drawCircle(center3, size.width * 0.35, paint3);

    // Bottom-Left Soft Liquid Blob (Blue)
    final paint4 = Paint()
      ..color = GymTheme.blue.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    final Offset center4 = Offset(
      size.width * 0.05 + math.cos(t) * 25,
      size.height * 0.8 + math.sin(t * 0.6) * 30,
    );
    canvas.drawCircle(center4, size.width * 0.38, paint4);
  }

  @override
  bool shouldRepaint(covariant _LiquidBlobPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// A container card with a soft liquid glowing border and fluid side indicator
class LiquidCard extends StatefulWidget {
  final Widget child;
  final Color accentColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const LiquidCard({
    super.key,
    required this.child,
    this.accentColor = GymTheme.mint,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
    this.onTap,
  });

  @override
  State<LiquidCard> createState() => _LiquidCardState();
}

class _LiquidCardState extends State<LiquidCard> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(28);

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final double glowVal = _glowController.value;

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: GymTheme.surface,
              borderRadius: br,
              border: Border.all(
                color: Color.lerp(
                  GymTheme.border,
                  widget.accentColor,
                  0.4 + glowVal * 0.4,
                )!,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withValues(alpha: 0.25 + glowVal * 0.2),
                  blurRadius: 16 + glowVal * 10,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: br,
              child: Stack(
                children: [
                  // Subtle liquid accent side bar on left edge
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          bottomLeft: Radius.circular(28),
                        ),
                      ),
                    ),
                  ),

                  // Card Content
                  Padding(
                    padding: widget.padding,
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

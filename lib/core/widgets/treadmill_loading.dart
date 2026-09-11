import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/gym_theme.dart';

/// Animated Treadmill Running Loading Widget used across the app during reloads & fetching
class TreadmillLoadingIndicator extends StatefulWidget {
  final String message;
  final double size;

  const TreadmillLoadingIndicator({
    super.key,
    this.message = 'Loading workout session...',
    this.size = 56,
  });

  @override
  State<TreadmillLoadingIndicator> createState() => _TreadmillLoadingIndicatorState();
}

class _TreadmillLoadingIndicatorState extends State<TreadmillLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double bounce = (math.sin(_controller.value * math.pi * 2)).abs() * -6;
        final double legAngle = math.sin(_controller.value * math.pi * 2) * 0.2;

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Liquid Glass Backing Circle with glowing aura
                Container(
                  width: widget.size * 1.5,
                  height: widget.size * 1.5,
                  decoration: BoxDecoration(
                    color: GymTheme.surface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color.lerp(
                        GymTheme.periwinkle,
                        GymTheme.yellow,
                        _controller.value,
                      )!,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GymTheme.periwinkle.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // Treadmill Runner Icon bouncing & tilting slightly
                Transform.translate(
                  offset: Offset(0, bounce),
                  child: Transform.rotate(
                    angle: legAngle,
                    child: const Icon(
                      Icons.directions_run_rounded,
                      size: 34,
                      color: GymTheme.primary,
                    ),
                  ),
                ),

                // Moving Treadmill Belt Line Underneath Runner
                Positioned(
                  bottom: widget.size * 0.26,
                  child: Container(
                    width: widget.size * 0.85,
                    height: 4,
                    decoration: BoxDecoration(
                      color: GymTheme.primary,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: GymTheme.primary.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (widget.message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.message,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: GymTheme.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

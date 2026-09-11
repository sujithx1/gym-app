import 'package:flutter/material.dart';
import '../theme/gym_theme.dart';

/// Tactile, springy iOS button widget with press-down scale animation
class IosButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;

  const IosButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor = GymTheme.primary,
    this.foregroundColor = Colors.white,
    this.height = 54.0,
    this.width,
    this.borderRadius,
    this.borderSide,
  });

  @override
  State<IosButton> createState() => _IosButtonState();
}

class _IosButtonState extends State<IosButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _scaleController.reverse();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(24);
    final bool isEnabled = widget.onPressed != null;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              height: widget.height,
              width: widget.width,
              decoration: BoxDecoration(
                color: isEnabled ? widget.backgroundColor : GymTheme.border,
                borderRadius: br,
                border: widget.borderSide != null
                    ? Border.fromBorderSide(widget.borderSide!)
                    : Border.all(
                        color: Colors.white.withValues(alpha: isEnabled ? 0.35 : 0.15),
                        width: 1.5,
                      ),
                boxShadow: isEnabled && widget.backgroundColor != Colors.transparent
                    ? [
                        BoxShadow(
                          color: widget.backgroundColor.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          spreadRadius: -2,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: DefaultTextStyle(
                style: TextStyle(
                  color: widget.foregroundColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

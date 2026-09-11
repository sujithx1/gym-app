import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../theme/gym_theme.dart';

/// Reusable running-person loading indicator widget.
class TreadmillLoadingWidget extends StatefulWidget {
  final String? message;
  final double size;
  final Color? color;
  final bool showGlassCard;

  const TreadmillLoadingWidget({
    super.key,
    this.message,
    this.size = 64.0,
    this.color,
    this.showGlassCard = false,
  });

  @override
  State<TreadmillLoadingWidget> createState() => _TreadmillLoadingWidgetState();
}

/// Backward compatibility alias.
typedef TreadmillLoadingIndicator = TreadmillLoadingWidget;

class _TreadmillLoadingWidgetState extends State<TreadmillLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? GymTheme.primary;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = _controller.value * 2 * math.pi;

            return Transform.translate(
              offset: Offset(0, -2 * math.sin(value)),
              child: Transform.rotate(
                angle: 0.06 * math.sin(value),
                child: Icon(
                  Icons.directions_run,
                  size: widget.size,
                  color: themeColor,
                ),
              ),
            );
          },
        ),

        if (widget.message != null && widget.message!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: GymTheme.textPrimary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ],
    );

    // No card / no circle.
    if (!widget.showGlassCard) {
      return content;
    }

    // Optional glass card.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: GymTheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: GymTheme.periwinkle.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: GymTheme.periwinkle.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: content,
    );
  }
}

/// Global loading overlay.
///
/// Shows ONLY the animated running person while an API request is active.
class GlobalTreadmillOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalTreadmillOverlay({super.key, required this.child});

  @override
  ConsumerState<GlobalTreadmillOverlay> createState() =>
      _GlobalTreadmillOverlayState();
}

class _GlobalTreadmillOverlayState
    extends ConsumerState<GlobalTreadmillOverlay> {
  bool _showOverlay = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onLoadingStateChanged(int activeRequests) {
    final bool isLoading = activeRequests > 0;

    if (isLoading) {
      // Anti-flicker delay.
      if (!_showOverlay && _debounceTimer == null) {
        _debounceTimer = Timer(const Duration(milliseconds: 200), () {
          _debounceTimer = null;

          if (mounted && ref.read(apiLoadingProvider) > 0) {
            setState(() {
              _showOverlay = true;
            });
          }
        });
      }
    } else {
      // Hide immediately when all requests finish.
      _debounceTimer?.cancel();
      _debounceTimer = null;

      if (_showOverlay) {
        setState(() {
          _showOverlay = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(apiLoadingProvider, (previous, next) {
      _onLoadingStateChanged(next);
    });

    return Stack(
      children: [
        widget.child,

        if (_showOverlay)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  alignment: Alignment.center,

                  // ONLY RUNNING PERSON.
                  child: const TreadmillLoadingWidget(
                    size: 70,
                    showGlassCard: false,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pull-to-refresh indicator.
///
/// Shows ONLY the animated running person.
/// No circular background.
class TreadmillRefreshIndicator extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const TreadmillRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  State<TreadmillRefreshIndicator> createState() =>
      _TreadmillRefreshIndicatorState();
}

class _TreadmillRefreshIndicatorState extends State<TreadmillRefreshIndicator> {
  double _pullDistance = 0.0;
  bool _isRefreshing = false;

  static const double _refreshThreshold = 65.0;

  Future<void> _triggerRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _pullDistance = _refreshThreshold;
    });

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _pullDistance = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (_isRefreshing) return false;

        if (notification is ScrollUpdateNotification) {
          if (notification.metrics.pixels < 0) {
            setState(() {
              _pullDistance = (-notification.metrics.pixels).clamp(0.0, 100.0);
            });
          } else if (_pullDistance > 0 && notification.metrics.pixels >= 0) {
            setState(() {
              _pullDistance = 0.0;
            });
          }
        } else if (notification is OverscrollNotification) {
          if (notification.overscroll < 0) {
            setState(() {
              _pullDistance = (_pullDistance - notification.overscroll).clamp(
                0.0,
                100.0,
              );
            });
          }
        } else if (notification is ScrollEndNotification) {
          if (_pullDistance >= _refreshThreshold) {
            _triggerRefresh();
          } else if (_pullDistance > 0) {
            setState(() {
              _pullDistance = 0.0;
            });
          }
        }

        return false;
      },

      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,

          if (_pullDistance > 10 || _isRefreshing)
            Positioned(
              top: _isRefreshing
                  ? 12.0
                  : (_pullDistance * 0.5 - 20.0).clamp(0.0, 40.0),
              left: 0,
              right: 0,

              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _isRefreshing
                      ? 1.0
                      : (_pullDistance / _refreshThreshold).clamp(0.0, 1.0),

                  // NO Container.
                  // NO Circle.
                  // ONLY RUNNING PERSON.
                  child: const TreadmillLoadingWidget(
                    size: 32,
                    showGlassCard: false,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

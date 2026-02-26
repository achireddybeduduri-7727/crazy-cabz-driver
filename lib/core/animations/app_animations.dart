import 'package:flutter/material.dart';

class AppAnimations {
  // Smooth page transition animations
  static const Duration fastTransition = Duration(milliseconds: 200);
  static const Duration normalTransition = Duration(milliseconds: 300);
  static const Duration slowTransition = Duration(milliseconds: 500);

  // Smooth curves for liquid animations
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve fastCurve = Curves.easeOutQuart;

  // Page transition builder for smooth navigation
  static PageRouteBuilder<T> smoothPageRoute<T>({
    required Widget page,
    Duration duration = normalTransition,
    Curve curve = smoothCurve,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Smooth slide and fade transition
        final slideAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }

  // Smooth scale transition for dialogs and modals
  static PageRouteBuilder<T> scalePageRoute<T>({
    required Widget page,
    Duration duration = normalTransition,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: smoothCurve));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: smoothCurve));

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }

  // Smooth list item animations
  static Widget animatedListItem({
    required Widget child,
    required int index,
    Duration delay = const Duration(milliseconds: 50),
  }) {
    return TweenAnimationBuilder<double>(
      duration:
          normalTransition +
          Duration(milliseconds: index * delay.inMilliseconds),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: smoothCurve,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }

  // Smooth button press animation
  static Widget animatedButton({
    required Widget child,
    required VoidCallback onPressed,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween<double>(begin: 1.0, end: 1.0),
      curve: bounceCurve,
      builder: (context, scale, _) {
        return GestureDetector(
          onTapDown: (_) => {},
          onTapCancel: () => {},
          onTap: onPressed,
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }

  // Smooth shimmer loading effect
  static Widget shimmerEffect({
    required Widget child,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween<double>(begin: -1.0, end: 1.0),
      curve: Curves.linear,
      onEnd: () {}, // This will restart the animation
      builder: (context, value, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(value * 3.14159),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }

  // Smooth floating action button animation
  static Widget animatedFAB({
    required Widget child,
    required VoidCallback onPressed,
    bool isVisible = true,
  }) {
    return AnimatedScale(
      scale: isVisible ? 1.0 : 0.0,
      duration: normalTransition,
      curve: bounceCurve,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: fastTransition,
        child: FloatingActionButton(onPressed: onPressed, child: child),
      ),
    );
  }

  // Smooth card slide animation
  static Widget slideInCard({
    required Widget child,
    required bool isVisible,
    Direction direction = Direction.left,
  }) {
    late Offset beginOffset;
    switch (direction) {
      case Direction.left:
        beginOffset = const Offset(-1.0, 0.0);
        break;
      case Direction.right:
        beginOffset = const Offset(1.0, 0.0);
        break;
      case Direction.top:
        beginOffset = const Offset(0.0, -1.0);
        break;
      case Direction.bottom:
        beginOffset = const Offset(0.0, 1.0);
        break;
    }

    return AnimatedSlide(
      offset: isVisible ? Offset.zero : beginOffset,
      duration: normalTransition,
      curve: smoothCurve,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: normalTransition,
        curve: smoothCurve,
        child: child,
      ),
    );
  }
}

enum Direction { left, right, top, bottom }

// Extension for smooth context navigation
extension SmoothNavigation on BuildContext {
  Future<T?> pushSmooth<T>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(AppAnimations.smoothPageRoute<T>(page: page));
  }

  Future<T?> pushScaleSmooth<T>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(AppAnimations.scalePageRoute<T>(page: page));
  }

  void popSmooth<T>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }
}

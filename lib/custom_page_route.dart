import 'package:flutter/material.dart';

class CustomPageRoute<T> extends PageRoute<T> {
  final Widget child;
  final Duration duration;

  CustomPageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    super.settings,
  });

  @override
  final bool opaque = true;

  @override
  final bool barrierDismissible = false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  // Slightly faster reverse for snappier back navigation
  @override
  Duration get reverseTransitionDuration => Duration(milliseconds: duration.inMilliseconds - 50);

  @override
  Widget buildPage(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      ) {
    // Semantics wrapper improves accessibility without performance cost
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: child,
    );
  }

  @override
  Widget buildTransitions(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    // Only animate when needed
    if (animation.status == AnimationStatus.completed) {
      return child;
    }

    // Use physics-based curve for most natural motion
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.4, 0.0, 0.2, 1.0), // Material Design standard easing
      reverseCurve: const Cubic(0.4, 0.0, 0.6, 1.0),
    );

    return RepaintBoundary(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: Tween<double>(
            begin: 0.9,
            end: 1.0,
          ).animate(curvedAnimation),
          // Secondary RepaintBoundary for child isolation
          child: RepaintBoundary(child: child),
        ),
      ),
    );
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Disable transitions to modal routes for better performance
    return nextRoute is CustomPageRoute && !nextRoute.fullscreenDialog;
  }

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return previousRoute is CustomPageRoute;
  }
}


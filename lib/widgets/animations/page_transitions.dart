import 'package:flutter/material.dart';

/// Custom Page Route Transitions
/// Smooth và modern page transitions cho app

/// Fade + Slide transition (iOS style)
class FadeSlideTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  FadeSlideTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

/// Scale + Fade transition (modern style)
class ScaleFadeTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  ScaleFadeTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeIn,
            );

            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                ),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

/// Slide Up transition (Bottom sheet style)
class SlideUpTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  SlideUpTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Shared Axis Transition (Material Design 3)
class SharedAxisTransition extends PageRouteBuilder {
  final Widget page;
  final SharedAxisType type;
  final Duration duration;

  SharedAxisTransition({
    required this.page,
    this.type = SharedAxisType.horizontal,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            Offset beginOffset;
            switch (type) {
              case SharedAxisType.horizontal:
                beginOffset = const Offset(0.1, 0);
                break;
              case SharedAxisType.vertical:
                beginOffset = const Offset(0, 0.1);
                break;
              case SharedAxisType.scaled:
                return FadeTransition(
                  opacity: curvedAnimation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation),
                    child: child,
                  ),
                );
            }

            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: beginOffset,
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

enum SharedAxisType { horizontal, vertical, scaled }

/// Hero Page Route - for smooth hero animations
class HeroPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  
  HeroPageRoute({required this.builder}) : super();

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curvedAnimation,
      child: child,
    );
  }
}

/// Extension cho Navigator để dễ dàng sử dụng
extension NavigatorExtensions on NavigatorState {
  /// Navigate với fade slide transition
  Future<T?> pushFadeSlide<T>(Widget page) {
    return push(FadeSlideTransition(page: page));
  }

  /// Navigate với scale fade transition
  Future<T?> pushScaleFade<T>(Widget page) {
    return push(ScaleFadeTransition(page: page));
  }

  /// Navigate với slide up transition
  Future<T?> pushSlideUp<T>(Widget page) {
    return push(SlideUpTransition(page: page));
  }

  /// Navigate với hero animation
  Future<T?> pushHero<T>(Widget page) {
    return push(HeroPageRoute(builder: (_) => page));
  }
}

/// Extension cho BuildContext
extension ContextNavigator on BuildContext {
  /// Navigate với custom transition
  Future<T?> pushWithTransition<T>(Widget page, {TransitionType type = TransitionType.fadeSlide}) {
    switch (type) {
      case TransitionType.fadeSlide:
        return Navigator.of(this).push(FadeSlideTransition(page: page));
      case TransitionType.scaleFade:
        return Navigator.of(this).push(ScaleFadeTransition(page: page));
      case TransitionType.slideUp:
        return Navigator.of(this).push(SlideUpTransition(page: page));
      case TransitionType.hero:
        return Navigator.of(this).push(HeroPageRoute(builder: (_) => page));
    }
  }
}

enum TransitionType { fadeSlide, scaleFade, slideUp, hero }

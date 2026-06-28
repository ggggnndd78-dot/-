import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension AppNavigationContext on BuildContext {
  Future<T?> pushPath<T extends Object?>(String location) {
    return GoRouter.of(this).push<T>(location);
  }

  Future<T?> pushReplacementPath<T extends Object?>(String location) {
    return GoRouter.of(this).pushReplacement<T>(location);
  }

  void popOrGo([String? fallbackLocation]) {
    final router = GoRouter.of(this);
    if (router.canPop()) {
      router.pop();
      return;
    }
    if ((fallbackLocation ?? '').isNotEmpty) {
      router.go(fallbackLocation!);
    }
  }
}

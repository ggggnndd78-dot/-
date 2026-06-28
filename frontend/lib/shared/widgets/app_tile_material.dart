import 'package:flutter/material.dart';

/// Provides a local Material ancestor for ListTile/Ink widgets placed inside
/// decorated containers so ripple and selected states remain visible.
class AppTileMaterial extends StatelessWidget {
  const AppTileMaterial({
    super.key,
    required this.child,
    this.borderRadius,
  });

  final Widget child;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      borderRadius: borderRadius,
      clipBehavior: borderRadius == null ? Clip.none : Clip.antiAlias,
      child: child,
    );
  }
}

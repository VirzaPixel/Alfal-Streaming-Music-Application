
import 'package:flutter/material.dart';
import '../config/theme.dart';

class AGlass extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;

  const AGlass({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.5,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final defaultRadius = BorderRadius.circular(20);
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: borderRadius ?? defaultRadius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AColors.surface.withOpacity(opacity),
            borderRadius: borderRadius ?? defaultRadius,
            border: border ?? Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

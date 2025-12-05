import 'dart:ui';
import 'package:flutter/material.dart';

/// Universal Loading Overlay Widget
/// Hiển thị vòng xoay tròn ở giữa màn hình với nền mờ phía sau
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? backgroundColor;
  final Color? progressColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.backgroundColor,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: backgroundColor ?? Colors.black.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressColor ?? Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

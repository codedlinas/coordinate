import 'package:flutter/material.dart';

/// Wrapper widget that constrains content to phone-like width
/// and centers it on larger screens
class PhoneWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const PhoneWrapper({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        child: child,
      ),
    );
  }
}





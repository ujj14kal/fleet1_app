import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class TruckAssetImage extends StatelessWidget {
  final String asset;
  final double scale;
  final double fallbackSize;
  final Color fallbackColor;

  const TruckAssetImage({
    super.key,
    required this.asset,
    this.scale = 1.18,
    this.fallbackSize = 42,
    this.fallbackColor = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateY(-0.16)
        ..rotateZ(-math.pi / 90)
        ..scale(scale),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Icon(
          Icons.local_shipping_rounded,
          color: fallbackColor,
          size: fallbackSize,
        ),
      ),
    );
  }
}

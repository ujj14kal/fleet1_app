import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Fleet1-branded truck loading animation.
/// The road dashes animate leftward; wheels rotate — pure CustomPainter, no plugins.
class TruckLoader extends StatefulWidget {
  final String message;
  const TruckLoader({super.key, this.message = 'Loading...'});

  @override
  State<TruckLoader> createState() => _TruckLoaderState();
}

class _TruckLoaderState extends State<TruckLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 240,
          height: 86,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) =>
                CustomPaint(painter: _TruckRoadPainter(_ctrl.value)),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.message,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _TruckRoadPainter extends CustomPainter {
  final double t; // 0 → 1 repeating
  static final TextPainter _fleetTP = TextPainter(
    text: const TextSpan(
      text: 'FLEET',
      style: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _oneTP = TextPainter(
    text: const TextSpan(
      text: '1',
      style: TextStyle(
        color: AppColors.primaryAmber,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final Paint _roadPaint = Paint()..color = const Color(0xFF374151);
  static final Paint _roadTopPaint = Paint()..color = const Color(0xFF4B5563);
  static final Paint _dashPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.55)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  static final Paint _shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.16);
  static final Paint _cargoPaint = Paint()..color = AppColors.primaryNavy;
  static final Paint _amberPaint = Paint()..color = AppColors.primaryAmber;
  static final Paint _linePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.08)
    ..strokeWidth = 1;
  static final Paint _windshieldPaint = Paint()..color = Colors.white.withValues(alpha: 0.88);
  static final Paint _bumperPaint = Paint()..color = const Color(0xFF0F172A);
  static final Paint _headlightPaint = Paint()..color = Colors.white;
  static final Paint _headlightGlowPaint = Paint()..color = Colors.white.withValues(alpha: 0.22);
  static final Paint _tirePaint = Paint()..color = const Color(0xFF1E293B);
  static final Paint _rimPaint = Paint()..color = const Color(0xFF64748B);
  static final Paint _hubPaint = Paint()..color = const Color(0xFFCBD5E1);
  static final Paint _boltPaint = Paint()..color = const Color(0xFF94A3B8);

  const _TruckRoadPainter(this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    // ── Road ─────────────────────────────────────────────
    final roadTop = h * 0.74;
    final roadH = h - roadTop;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, roadTop, w, roadH),
        const Radius.circular(6),
      ),
      _roadPaint,
    );
    // top edge
    canvas.drawRect(
      Rect.fromLTWH(0, roadTop, w, 2.5),
      _roadTopPaint,
    );

    // ── Scrolling dashes ─────────────────────────────────
    const dW = 20.0, gap = 14.0;
    final dashY = roadTop + roadH * 0.48;
    final offset = t * (dW + gap);
    for (double x = -offset; x < w + dW; x += dW + gap) {
      canvas.drawLine(Offset(x, dashY), Offset(x + dW, dashY), _dashPaint);
    }

    // ── Geometry ─────────────────────────────────────────
    final wheelR = h * 0.132;
    final groundY = roadTop; // wheel bottom sits here
    final bob = math.sin(t * 2 * math.pi) * h * 0.018;

    // cargo box
    const cL = 8.0;
    final cT = h * 0.09;
    final cW = w * 0.572;
    final cH = groundY - cT;

    // cab
    final cabL = cL + cW;
    final cabT = h * 0.24;
    final cabW = w * 0.268;
    final cabH = groundY - cabT;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cL + (cW + cabW) * 0.5, groundY + h * 0.035),
        width: (cW + cabW) * 0.78,
        height: h * 0.08,
      ),
      _shadowPaint,
    );

    canvas.save();
    canvas.translate(0, bob);

    // ── Cargo box ────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cL, cT, cW, cH),
        topLeft: const Radius.circular(4),
        bottomLeft: const Radius.circular(2),
      ),
      _cargoPaint,
    );
    // amber top stripe
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cL, cT, cW, h * 0.065),
        topLeft: const Radius.circular(4),
      ),
      _amberPaint,
    );
    // vertical panel lines for depth
    for (double lx = cL + cW * 0.25; lx < cL + cW - 4; lx += cW * 0.25) {
      canvas.drawLine(Offset(lx, cT + h * 0.07), Offset(lx, groundY), _linePaint);
    }
    // FLEET + 1 text
    _paintFleet1(canvas, Offset(cL + cW / 2, cT + cH * 0.57));

    // ── Cab ──────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cabL, cabT, cabW, cabH),
        topRight: const Radius.circular(10),
        bottomRight: const Radius.circular(4),
      ),
      _amberPaint,
    );
    // windshield
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cabL + 5, cabT + 5, cabW - 14, cabH * 0.52),
        const Radius.circular(5),
      ),
      _windshieldPaint,
    );
    // front bumper
    canvas.drawRect(
      Rect.fromLTWH(cabL + cabW - 5, cabT + cabH * 0.66, 5, cabH * 0.30),
      _bumperPaint,
    );
    // headlight
    canvas.drawCircle(
      Offset(cabL + cabW - 1, cabT + cabH * 0.82),
      4.5,
      _headlightPaint,
    );
    canvas.drawCircle(
      Offset(cabL + cabW - 1, cabT + cabH * 0.82),
      8,
      _headlightGlowPaint,
    );

    // ── Wheels ───────────────────────────────────────────
    final wheelPositions = [
      Offset(cL + cW * 0.22, groundY),
      Offset(cL + cW * 0.74, groundY),
      Offset(cabL + cabW * 0.62, groundY),
    ];
    for (final pos in wheelPositions) {
      _drawWheel(canvas, pos, wheelR);
    }
    canvas.restore();
  }

  void _drawWheel(Canvas canvas, Offset center, double r) {
    final cy = center.dy - r; // wheel center Y (sits on road)
    final c = Offset(center.dx, cy);

    // tire
    canvas.drawCircle(c, r, _tirePaint);
    // rim
    canvas.drawCircle(c, r * 0.62, _rimPaint);
    // hub
    canvas.drawCircle(c, r * 0.24, _hubPaint);

    // rotating lug bolts
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * 2 * math.pi);
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * math.pi;
      canvas.drawCircle(
        Offset(math.cos(angle) * r * 0.40, math.sin(angle) * r * 0.40),
        1.8,
        _boltPaint,
      );
    }
    canvas.restore();
  }

  void _paintFleet1(Canvas canvas, Offset center) {
    final totalW = _fleetTP.width + _oneTP.width;
    final startX = center.dx - totalW / 2;
    final textY = center.dy - _fleetTP.height / 2;
    _fleetTP.paint(canvas, Offset(startX, textY));
    _oneTP.paint(canvas, Offset(startX + _fleetTP.width, textY));
  }

  @override
  bool shouldRepaint(covariant _TruckRoadPainter old) => old.t != t;
}

/// Compact loader for buttons and dense surfaces.
class TruckLoaderCompact extends StatefulWidget {
  final Color? roadColor;
  final double width;
  final double height;
  const TruckLoaderCompact({
    super.key,
    this.roadColor,
    this.width = 112,
    this.height = 38,
  });

  @override
  State<TruckLoaderCompact> createState() => _TruckLoaderCompactState();
}

class _TruckLoaderCompactState extends State<TruckLoaderCompact>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) =>
            CustomPaint(painter: _TruckRoadPainter(_ctrl.value)),
      ),
    );
  }
}

/// Full-screen loader — use this when an entire page is loading.
class TruckLoaderPage extends StatelessWidget {
  final String message;
  const TruckLoaderPage({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: TruckLoader(message: message)),
    );
  }
}

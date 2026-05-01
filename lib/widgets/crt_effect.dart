import 'dart:math' as math;
import 'package:flutter/material.dart';

class CRTEffect extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const CRTEffect({super.key, required this.child, this.enabled = true});

  @override
  State<CRTEffect> createState() => _CRTEffectState();
}

class _CRTEffectState extends State<CRTEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        // Scanlines
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: CRTScanlinePainter(_controller.value),
                );
              },
            ),
          ),
        ),
        // Faint flicker
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final opacity = 0.01 + math.Random().nextDouble() * 0.02;
                return Container(
                  color: Colors.white.withOpacity(opacity),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class CRTScanlinePainter extends CustomPainter {
  final double animationValue;

  CRTScanlinePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 1.0;

    const step = 3.0;
    final offset = animationValue * step;

    for (double y = offset; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

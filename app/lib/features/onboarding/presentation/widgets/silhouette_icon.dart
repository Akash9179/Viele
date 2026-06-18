import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../data/onboarding_data.dart';

/// Refined line-art body silhouette: a head + a smooth, stroked torso/hip
/// outline (croquis-style), proportions varying by [SilhouetteShape].
/// Stand-in until illustrated assets are commissioned (`docs/design.md` §9).
class SilhouetteIcon extends StatelessWidget {
  const SilhouetteIcon({super.key, required this.shape, required this.selected});

  final SilhouetteShape shape;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 64),
      painter: _SilhouettePainter(
        shape: shape,
        color: selected ? AppColors.ink : AppColors.ink2,
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter({required this.shape, required this.color});

  final SilhouetteShape shape;
  final Color color;

  // (shoulder, waist, hip) widths as fractions of the canvas width.
  static const _widths = <SilhouetteShape, (double, double, double)>{
    SilhouetteShape.hourglass: (0.52, 0.30, 0.52),
    SilhouetteShape.pear: (0.42, 0.34, 0.60),
    SilhouetteShape.rectangle: (0.46, 0.42, 0.46),
    SilhouetteShape.apple: (0.44, 0.56, 0.46),
    SilhouetteShape.invertedTriangle: (0.60, 0.36, 0.40),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Head
    final headR = w * 0.10;
    final headC = Offset(cx, h * 0.11);
    canvas.drawCircle(headC, headR, stroke);

    final (sW, wW, hW) = _widths[shape]!;
    final hs = sW * w / 2;
    final hw = wW * w / 2;
    final hh = hW * w / 2;

    final yShoulder = h * 0.30;
    final yWaist = h * 0.56;
    final yHip = h * 0.75;
    final yHem = h * 0.92;
    final hemHalf = hh * 0.82;

    final lShoulder = Offset(cx - hs, yShoulder);
    final lWaist = Offset(cx - hw, yWaist);
    final lHip = Offset(cx - hh, yHip);
    final lHem = Offset(cx - hemHalf, yHem);
    final rShoulder = Offset(cx + hs, yShoulder);
    final rWaist = Offset(cx + hw, yWaist);
    final rHip = Offset(cx + hh, yHip);
    final rHem = Offset(cx + hemHalf, yHem);

    final path = Path()..moveTo(lShoulder.dx, lShoulder.dy);
    // left shoulder → waist
    path.cubicTo(
      cx - hs, yShoulder + (yWaist - yShoulder) * 0.42,
      cx - hw, yWaist - (yWaist - yShoulder) * 0.28,
      lWaist.dx, lWaist.dy,
    );
    // left waist → hip
    path.cubicTo(
      cx - hw, yWaist + (yHip - yWaist) * 0.32,
      cx - hh, yHip - (yHip - yWaist) * 0.42,
      lHip.dx, lHip.dy,
    );
    // left hip → hem
    path.quadraticBezierTo(cx - hh, yHem - (yHem - yHip) * 0.2, lHem.dx, lHem.dy);
    // hem across
    path.lineTo(rHem.dx, rHem.dy);
    // right hem → hip
    path.quadraticBezierTo(cx + hh, yHem - (yHem - yHip) * 0.2, rHip.dx, rHip.dy);
    // right hip → waist
    path.cubicTo(
      cx + hh, yHip - (yHip - yWaist) * 0.42,
      cx + hw, yWaist + (yHip - yWaist) * 0.32,
      rWaist.dx, rWaist.dy,
    );
    // right waist → shoulder
    path.cubicTo(
      cx + hw, yWaist - (yWaist - yShoulder) * 0.28,
      cx + hs, yShoulder + (yWaist - yShoulder) * 0.42,
      rShoulder.dx, rShoulder.dy,
    );
    // shoulders + neckline dip back to left shoulder
    path.cubicTo(
      cx + hs * 0.4, yShoulder + h * 0.045,
      cx - hs * 0.4, yShoulder + h * 0.045,
      lShoulder.dx, lShoulder.dy,
    );
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) =>
      old.shape != shape || old.color != color;
}

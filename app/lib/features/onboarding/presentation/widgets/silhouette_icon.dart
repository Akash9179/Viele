import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../data/onboarding_data.dart';

/// Draws a simple body silhouette (head + body polygon) per [SilhouetteShape].
/// Stand-in until illustrated assets are commissioned (`docs/design.md` §9).
class SilhouetteIcon extends StatelessWidget {
  const SilhouetteIcon({super.key, required this.shape, required this.selected});

  final SilhouetteShape shape;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(34, 58),
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

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final w = size.width;
    final h = size.height;

    if (shape == SilhouetteShape.notSure) {
      // A neutral "person" glyph for skip/unsure.
      canvas.drawCircle(Offset(w / 2, h * 0.32), w * 0.16, p);
      final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.5, w * 0.36, h * 0.4),
        const Radius.circular(6),
      );
      canvas.drawRRect(body, p);
      return;
    }

    // Head
    canvas.drawCircle(Offset(w / 2, h * 0.12), w * 0.15, p);

    // Body polygon per shape (normalized points).
    final pts = switch (shape) {
      SilhouetteShape.balanced => const [
          Offset(0.35, 0.25), Offset(0.65, 0.25), Offset(0.55, 0.55),
          Offset(0.65, 0.85), Offset(0.35, 0.85), Offset(0.45, 0.55),
        ],
      SilhouetteShape.fullerHips => const [
          Offset(0.40, 0.25), Offset(0.60, 0.25), Offset(0.50, 0.52),
          Offset(0.72, 0.85), Offset(0.28, 0.85),
        ],
      SilhouetteShape.straight => const [
          Offset(0.37, 0.25), Offset(0.63, 0.25),
          Offset(0.63, 0.86), Offset(0.37, 0.86),
        ],
      SilhouetteShape.fullerMiddle => const [
          Offset(0.38, 0.25), Offset(0.62, 0.25), Offset(0.74, 0.56),
          Offset(0.60, 0.86), Offset(0.40, 0.86), Offset(0.26, 0.56),
        ],
      SilhouetteShape.broadShoulder => const [
          Offset(0.28, 0.25), Offset(0.72, 0.25), Offset(0.60, 0.56),
          Offset(0.55, 0.86), Offset(0.45, 0.86), Offset(0.40, 0.56),
        ],
      SilhouetteShape.notSure => const [],
    };

    final path = Path()..moveTo(pts.first.dx * w, pts.first.dy * h);
    for (final pt in pts.skip(1)) {
      path.lineTo(pt.dx * w, pt.dy * h);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) =>
      old.shape != shape || old.color != color;
}

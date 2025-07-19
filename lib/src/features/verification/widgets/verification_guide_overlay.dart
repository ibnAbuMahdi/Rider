import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class VerificationGuideOverlay extends StatelessWidget {
  const VerificationGuideOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: VerificationGuidePainter(),
      child: Container(),
    );
  }
}

class VerificationGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw semi-transparent overlay
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Calculate guide box dimensions and position
    final boxWidth = size.width * 0.8;
    final boxHeight = size.height * 0.4;
    final boxLeft = (size.width - boxWidth) / 2;
    final boxTop = (size.height - boxHeight) / 2;

    // Clear the guide area (transparent box)
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear;
    
    final guidePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight),
          const Radius.circular(16),
        ),
      );

    canvas.drawPath(guidePath, clearPaint);

    // Draw guide box border
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight),
        const Radius.circular(16),
      ),
      borderPaint,
    );

    // Draw corner indicators
    _drawCornerIndicators(canvas, boxLeft, boxTop, boxWidth, boxHeight);

    // Draw center crosshair
    _drawCenterCrosshair(canvas, size);
  }

  void _drawCornerIndicators(Canvas canvas, double left, double top, double width, double height) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerSize = 20.0;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top + cornerSize),
      Offset(left, top),
      paint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerSize, top),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(left + width - cornerSize, top),
      Offset(left + width, top),
      paint,
    );
    canvas.drawLine(
      Offset(left + width, top),
      Offset(left + width, top + cornerSize),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + height - cornerSize),
      Offset(left, top + height),
      paint,
    );
    canvas.drawLine(
      Offset(left, top + height),
      Offset(left + cornerSize, top + height),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + width - cornerSize, top + height),
      Offset(left + width, top + height),
      paint,
    );
    canvas.drawLine(
      Offset(left + width, top + height),
      Offset(left + width, top + height - cornerSize),
      paint,
    );
  }

  void _drawCenterCrosshair(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const crosshairSize = 30.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Horizontal line
    canvas.drawLine(
      Offset(centerX - crosshairSize / 2, centerY),
      Offset(centerX + crosshairSize / 2, centerY),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(centerX, centerY - crosshairSize / 2),
      Offset(centerX, centerY + crosshairSize / 2),
      paint,
    );

    // Center dot
    canvas.drawCircle(
      Offset(centerX, centerY),
      3,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
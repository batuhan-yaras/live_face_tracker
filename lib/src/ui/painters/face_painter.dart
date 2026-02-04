import 'dart:ui'; // PathMetric için gerekli
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Defines the available visual styles for the face tracking frame.
enum FaceFrameStyle { cornerBracket, roundedBox, dottedLine }

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  // Customization properties
  final Color activeColor;
  final FaceFrameStyle style;

  FacePainter({
    required this.faces,
    required this.absoluteImageSize,
    required this.rotation,
    this.activeColor = Colors.cyanAccent,
    this.style = FaceFrameStyle.cornerBracket,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color =
              activeColor // Kullanıcının seçtiği renk
          ..strokeCap = StrokeCap.round;

    for (final Face face in faces) {
      final rect = face.boundingBox;

      // Scale and mirror logic (Standard setup)
      final double scaleX = size.width / absoluteImageSize.width;
      final double scaleY = size.height / absoluteImageSize.height;

      double left = size.width - (rect.right * scaleX);
      double top = rect.top * scaleY;
      double right = size.width - (rect.left * scaleX);
      double bottom = rect.bottom * scaleY;

      // Ensure valid dimensions
      if (left > right) {
        final temp = left;
        left = right;
        right = temp;
      }

      final Rect drawingRect = Rect.fromLTRB(left, top, right, bottom);

      // --- STYLE SWITCHER ---
      switch (style) {
        case FaceFrameStyle.cornerBracket:
          _drawCornerBrackets(canvas, drawingRect, paint);
          break;
        case FaceFrameStyle.roundedBox:
          _drawRoundedBox(canvas, drawingRect, paint);
          break;
        case FaceFrameStyle.dottedLine:
          _drawDashedRect(canvas, drawingRect, paint);
          break;
      }
    }
  }

  /// Draws the Sci-Fi style corner brackets.
  void _drawCornerBrackets(Canvas canvas, Rect rect, Paint paint) {
    final double cornerLength = rect.width * 0.15; // Responsive length
    final Path path = Path();

    // Top-Left
    path.moveTo(rect.left, rect.top + cornerLength);
    path.lineTo(rect.left, rect.top);
    path.lineTo(rect.left + cornerLength, rect.top);

    // Top-Right
    path.moveTo(rect.right - cornerLength, rect.top);
    path.lineTo(rect.right, rect.top);
    path.lineTo(rect.right, rect.top + cornerLength);

    // Bottom-Right
    path.moveTo(rect.right, rect.bottom - cornerLength);
    path.lineTo(rect.right, rect.bottom);
    path.lineTo(rect.right - cornerLength, rect.bottom);

    // Bottom-Left
    path.moveTo(rect.left + cornerLength, rect.bottom);
    path.lineTo(rect.left, rect.bottom);
    path.lineTo(rect.left, rect.bottom - cornerLength);

    canvas.drawPath(path, paint);
  }

  /// Draws a modern rounded rectangle.
  void _drawRoundedBox(Canvas canvas, Rect rect, Paint paint) {
    // Radius is 10% of the width for a proportional look
    final RRect roundedRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.width * 0.1),
    );
    canvas.drawRRect(roundedRect, paint);
  }

  /// Draws a dashed/dotted rectangle manually.
  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    // Create the full path of the rounded rectangle
    final Path path =
        Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(8)));

    // Use PathMetrics to iterate over the path and draw dashes
    final Path dashPath = Path();
    final double dashWidth = 10.0;
    final double dashSpace = 5.0;
    double distance = 0.0;

    for (final PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.activeColor != activeColor || // Renk değişirse tekrar çiz
        oldDelegate.style != style; // Stil değişirse tekrar çiz
  }
}

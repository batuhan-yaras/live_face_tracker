import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum FaceFrameStyle { cornerBracket, roundedBox, dottedLine }

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
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
    if (faces.isEmpty) return;

    final Paint paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = activeColor
          ..strokeCap = StrokeCap.round;

    for (final Face face in faces) {
      final Rect drawingRect = _scaleRect(
        rect: face.boundingBox,
        imageSize: absoluteImageSize,
        widgetSize: size,
        rotation: rotation,
      );

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

  /// Helper function to map face coordinates to screen coordinates.
  /// It handles scaling, centering, and mirroring (for front camera).
  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size widgetSize,
    required InputImageRotation rotation,
  }) {
    // Since we provide 'rotation' to ML Kit when creating InputImage,
    // it returns face coordinates already "UPRIGHT" (Corrected).
    // Therefore, we DO NOT need to swap X and Y axes manually.
    // We only need to match the dimensions and apply scaling.

    // 1. CALCULATE ROTATED DIMENSIONS
    // If the sensor is at 90 or 270 degrees, the "Effective Image"
    // processed by ML Kit has swapped Width and Height.
    final bool isRotated =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;

    final double imageWidth = isRotated ? imageSize.height : imageSize.width;
    final double imageHeight = isRotated ? imageSize.width : imageSize.height;

    // 2. SCALE (BoxFit.cover logic)
    // We scale the image to cover the screen (zoom/crop effect).
    final double scaleX = widgetSize.width / imageWidth;
    final double scaleY = widgetSize.height / imageHeight;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    // 3. CENTER (OFFSET)
    // Calculate how much of the image is cropped out to center it.
    final double offsetX = (imageWidth * scale - widgetSize.width) / 2;
    final double offsetY = (imageHeight * scale - widgetSize.height) / 2;

    // 4. CALCULATE COORDINATES
    // Note: No axis swapping (X <-> Y) is needed here.
    // We only perform MIRRORING for the X-axis (Front Camera assumption).

    // Mirroring X axis formula:
    // Normal: left = rect.left * scale - offsetX;
    // Mirrored: left = (imageWidth - rect.right) * scale - offsetX;

    double left = (imageWidth - rect.right) * scale - offsetX;
    double top = rect.top * scale - offsetY;
    double right = (imageWidth - rect.left) * scale - offsetX;
    double bottom = rect.bottom * scale - offsetY;

    // TODO: If rear camera is supported in the future, mirroring should be disabled here.
    // Currently assuming front camera usage.

    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect, Paint paint) {
    final double cornerLength = rect.width * 0.15;
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

  void _drawRoundedBox(Canvas canvas, Rect rect, Paint paint) {
    final RRect roundedRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.width * 0.1),
    );
    canvas.drawRRect(roundedRect, paint);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    final Path path =
        Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(8)));
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
        oldDelegate.activeColor != activeColor ||
        oldDelegate.style != style;
  }
}

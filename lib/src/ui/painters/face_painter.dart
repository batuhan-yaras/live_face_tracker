import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Enum to define different visual styles for the face tracking frame.
enum FaceFrameStyle {
  cornerBracket, // [ ] style
  roundedBox, // ( ) style
  dottedLine, // - - style
}

/// CustomPainter responsible for drawing the tracking frame on the camera preview.
class FacePainter extends CustomPainter {
  final Rect? faceRect;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final Color activeColor;
  final FaceFrameStyle style;
  final bool isFrontCamera; // Added to fix back camera inversion

  FacePainter({
    required this.faceRect,
    required this.absoluteImageSize,
    required this.rotation,
    this.activeColor = Colors.cyanAccent,
    this.style = FaceFrameStyle.cornerBracket,
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faceRect == null ||
        absoluteImageSize.width == 0 ||
        absoluteImageSize.height == 0) {
      return;
    }

    final Paint paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = activeColor;

    // Calculate scaling logic (Same as Isolate logic but for canvas drawing)
    final bool isRotated =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;

    final double imageWidth =
        isRotated ? absoluteImageSize.height : absoluteImageSize.width;
    final double imageHeight =
        isRotated ? absoluteImageSize.width : absoluteImageSize.height;

    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    final double offsetX = (imageWidth * scale - size.width) / 2;
    final double offsetY = (imageHeight * scale - size.height) / 2;

    double left, right;

    // FIX: Back Camera Inversion Logic for Internal Frame
    if (isFrontCamera) {
      left = (imageWidth - faceRect!.right) * scale - offsetX;
      right = (imageWidth - faceRect!.left) * scale - offsetX;
    } else {
      left = faceRect!.left * scale - offsetX;
      right = faceRect!.right * scale - offsetX;
    }

    final double top = faceRect!.top * scale - offsetY;
    final double bottom = faceRect!.bottom * scale - offsetY;

    final Rect mappedRect = Rect.fromLTRB(left, top, right, bottom);

    // Draw based on selected style
    switch (style) {
      case FaceFrameStyle.roundedBox:
        _drawRoundedBox(canvas, mappedRect, paint);
        break;
      case FaceFrameStyle.dottedLine:
        _drawDottedLine(canvas, mappedRect, paint);
        break;
      case FaceFrameStyle.cornerBracket:
      default:
        _drawCornerBrackets(canvas, mappedRect, paint);
        break;
    }
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect, Paint paint) {
    final double length = rect.width * 0.2;
    // Top Left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(length, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, length), paint);
    // Top Right
    canvas.drawLine(rect.topRight, rect.topRight - Offset(length, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, length), paint);
    // Bottom Left
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + Offset(length, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft - Offset(0, length),
      paint,
    );
    // Bottom Right
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - Offset(length, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - Offset(0, length),
      paint,
    );
  }

  void _drawRoundedBox(Canvas canvas, Rect rect, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      paint,
    );
  }

  void _drawDottedLine(Canvas canvas, Rect rect, Paint paint) {
    final Path path =
        Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(8)));
    final Path dashPath = Path();
    const double dashWidth = 10.0;
    const double dashSpace = 5.0;
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
    return oldDelegate.faceRect != faceRect ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.style != style ||
        oldDelegate.absoluteImageSize != absoluteImageSize;
  }
}

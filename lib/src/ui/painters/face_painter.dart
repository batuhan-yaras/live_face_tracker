import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum FaceFrameStyle { cornerBracket, roundedBox, dottedLine }

class FacePainter extends CustomPainter {
  /// The single animated face rectangle to be drawn.
  final Rect? faceRect;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final Color activeColor;
  final FaceFrameStyle style;

  FacePainter({
    required this.faceRect,
    required this.absoluteImageSize,
    required this.rotation,
    this.activeColor = Colors.cyanAccent,
    this.style = FaceFrameStyle.cornerBracket,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faceRect == null) return;

    final Paint paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = activeColor
          ..strokeCap = StrokeCap.round;

    /// Calculate the scaled coordinates for the single target rectangle.
    final Rect drawingRect = _scaleRect(
      rect: faceRect!,
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

  /// Scales the detection coordinates to match the screen size while handling mirroring.
  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size widgetSize,
    required InputImageRotation rotation,
  }) {
    final bool isRotated =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;

    final double imageWidth = isRotated ? imageSize.height : imageSize.width;
    final double imageHeight = isRotated ? imageSize.width : imageSize.height;

    final double scaleX = widgetSize.width / imageWidth;
    final double scaleY = widgetSize.height / imageHeight;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    final double offsetX = (imageWidth * scale - widgetSize.width) / 2;
    final double offsetY = (imageHeight * scale - widgetSize.height) / 2;

    double left = (imageWidth - rect.right) * scale - offsetX;
    double top = rect.top * scale - offsetY;
    double right = (imageWidth - rect.left) * scale - offsetX;
    double bottom = rect.bottom * scale - offsetY;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect, Paint paint) {
    final double cornerLength = rect.width * 0.15;
    final Path path = Path();
    path.moveTo(rect.left, rect.top + cornerLength);
    path.lineTo(rect.left, rect.top);
    path.lineTo(rect.left + cornerLength, rect.top);
    path.moveTo(rect.right - cornerLength, rect.top);
    path.lineTo(rect.right, rect.top);
    path.lineTo(rect.right, rect.top + cornerLength);
    path.moveTo(rect.right, rect.bottom - cornerLength);
    path.lineTo(rect.right, rect.bottom);
    path.lineTo(rect.right - cornerLength, rect.bottom);
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
        oldDelegate.style != style ||
        oldDelegate.activeColor != activeColor;
  }
}

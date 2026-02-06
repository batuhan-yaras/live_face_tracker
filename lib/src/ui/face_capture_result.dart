import 'dart:ui';
import 'package:camera/camera.dart';

/// A wrapper class that contains the captured image and the face metadata
/// at the moment of capture.
class FaceCaptureResult {
  /// The raw image file captured by the camera.
  final XFile image;

  /// The face bounding box coordinates relative to the **Camera Preview**.
  /// If no face was detected, this will be null.
  final Rect? rawFaceRect;

  /// The size of the camera preview when the photo was taken.
  /// This is essential for scaling the Rect to the full image resolution.
  final Size previewSize;

  FaceCaptureResult({
    required this.image,
    required this.rawFaceRect,
    required this.previewSize,
  });

  /// Helper method to convert the preview-based Face Rect to the
  /// actual resolution of the captured image.
  ///
  /// [actualImageSize] is the size of the full resolution photo (e.g. 4000x3000).
  Rect? getMappedFaceRect({required Size actualImageSize}) {
    if (rawFaceRect == null) return null;

    final double scaleX = actualImageSize.width / previewSize.width;
    final double scaleY = actualImageSize.height / previewSize.height;

    return Rect.fromLTRB(
      rawFaceRect!.left * scaleX,
      rawFaceRect!.top * scaleY,
      rawFaceRect!.right * scaleX,
      rawFaceRect!.bottom * scaleY,
    );
  }

  @override
  String toString() {
    return 'FaceCaptureResult(path: ${image.path}, faceDetected: ${rawFaceRect != null})';
  }
}

import 'dart:ui';
import 'package:camera/camera.dart';
import 'face_capture_result.dart'; // Yeni dosyayı import et

/// Controller to trigger actions on the FaceTrackerView from outside.
class FaceTrackerController {
  Future<XFile?> Function()? _takePictureHandler;

  // Stores the latest face coordinates and preview size
  Rect? _lastDetectedFaceRect;
  Size? _previewSize;

  /// Captures the photo and bundles it with the face metadata.
  /// Returns a [FaceCaptureResult] containing the file and coordinates.
  Future<FaceCaptureResult?> capture() async {
    if (_takePictureHandler == null) {
      throw Exception("FaceTrackerController is not attached.");
    }

    // 1. Capture the raw photo
    final XFile? photoFile = await _takePictureHandler!();

    if (photoFile == null) return null;

    // 2. Return the bundle
    return FaceCaptureResult(
      image: photoFile,
      rawFaceRect: _lastDetectedFaceRect,
      previewSize: _previewSize ?? Size.zero,
    );
  }

  /// Internal: Called by the view to update face data continuously
  void updateFaceData(Rect? faceRect, Size previewSize) {
    _lastDetectedFaceRect = faceRect;
    _previewSize = previewSize;
  }

  void attach(Future<XFile?> Function() handler) {
    _takePictureHandler = handler;
  }

  void dispose() {
    _takePictureHandler = null;
    _lastDetectedFaceRect = null;
    _previewSize = null;
  }
}

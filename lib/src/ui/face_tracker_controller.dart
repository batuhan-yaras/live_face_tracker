import 'package:camera/camera.dart';

/// Controller to trigger actions on the FaceTrackerView from outside.
class FaceTrackerController {
  // Bu fonksiyonu _FaceTrackerViewState içinde dolduracağız.
  Future<XFile?> Function()? _takePictureHandler;

  /// Captures a photo from the current camera stream.
  Future<XFile?> takePicture() async {
    if (_takePictureHandler == null) {
      throw Exception(
        "FaceTrackerController is not attached to a FaceTrackerView.",
      );
    }
    return await _takePictureHandler!();
  }

  /// Internal use: Connects the controller to the implementation.
  void attach(Future<XFile?> Function() handler) {
    _takePictureHandler = handler;
  }

  void dispose() {
    _takePictureHandler = null;
  }
}

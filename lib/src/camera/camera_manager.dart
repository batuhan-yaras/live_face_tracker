import 'package:camera/camera.dart';

/// Manages the lifecycle of the camera, including initialization, streaming of image frames, and resource disposal.
class CameraManager {
  // The controller provided by the camera package to interact with device hardware.
  CameraController? _controller;

  /// Exposes the controller to be used by the UI (e.g., CameraPreview).
  CameraController? get controller => _controller;

  /// Checks if the camera controller is initialized and ready.
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Initializes the camera.
  ///
  /// Prioritizes the front camera for face detection.
  /// Sets up the resolution and image format required for ML Kit.
  Future<void> initialize() async {
    // Fetch the list of available cameras on the device.
    final cameras = await availableCameras();

    // Select the front camera for face tracking purposes.
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      // Fallback to the first available camera if no front camera exists.
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      // 'high' resolution offers better quality but may impact performance.
      // Typically, 'medium' is sufficient for ML tasks.
      ResolutionPreset.high,
      enableAudio: false, // Audio is not needed for face tracking.
      imageFormatGroup:
          ImageFormatGroup.nv21, // Critical for ML Kit on Android.
    );

    // Initialize the controller resources.
    await _controller!.initialize();
  }

  /// Captures a photo from the current camera stream.
  Future<XFile?> takePicture() async {
    if (controller == null || !controller!.value.isInitialized) {
      return null;
    }
    if (controller!.value.isTakingPicture) {
      return null; // Zaten çekim yapılıyor
    }

    try {
      return await controller!.takePicture();
    } catch (e) {
      return null;
    }
  }

  /// Starts the live image stream from the camera.
  ///
  /// [onImage] is a callback function that receives each [CameraImage] frame.
  /// This stream allows for real-time processing (e.g., face detection).
  Future<void> startStream(Function(CameraImage) onImage) async {
    // Ensure the camera is initialized and not already streaming to avoid errors.
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isStreamingImages) {
      return;
    }

    // Begin streaming images.
    await _controller!.startImageStream((image) {
      onImage(image);
    });
  }

  /// Stops the live image stream to save resources when not needed.
  Future<void> stopStream() async {
    if (_controller?.value.isStreamingImages == true) {
      await _controller!.stopImageStream();
    }
  }

  /// Disposes of the camera controller to release memory and hardware resources.
  void dispose() {
    _controller?.dispose();
  }
}

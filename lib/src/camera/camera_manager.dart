import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Manages the camera lifecycle, including initialization, streaming, and switching.
class CameraManager {
  CameraController? _controller;
  CameraDescription? _currentCamera;
  List<CameraDescription> _cameras = []; // List to hold all available cameras

  CameraController? get controller => _controller;

  /// Initializes the camera session.
  ///
  /// If [initialCameraDirection] is provided, it attempts to select that specific camera.
  /// Defaults to [CameraLensDirection.front].
  Future<void> initialize({
    CameraLensDirection initialCameraDirection = CameraLensDirection.front,
  }) async {
    _cameras = await availableCameras();

    if (_cameras.isEmpty) {
      debugPrint("No cameras found");
      return;
    }

    // Attempt to find the camera with the desired direction; otherwise, fallback to the first available one.
    _currentCamera = _cameras.firstWhere(
      (cam) => cam.lensDirection == initialCameraDirection,
      orElse: () => _cameras.first,
    );

    await _initController(_currentCamera!);
  }

  /// Internal helper to configure and initialize the specific camera controller.
  Future<void> _initController(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await controller.initialize();
      _controller = controller;
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  /// Starts the image stream for real-time processing.
  Future<void> startStream(Function(CameraImage) onImage) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    await _controller!.startImageStream(onImage);
  }

  /// Stops the current image stream.
  Future<void> stopStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }

  /// Switches the camera to the opposite direction (Front <-> Back).
  ///
  /// Returns the new [CameraDescription] to allow the UI or Controller to update
  /// necessary properties (like rotation or mirroring).
  Future<CameraDescription?> switchCamera() async {
    if (_cameras.isEmpty || _currentCamera == null) return null;

    // 1. Determine the target direction
    final newDirection =
        _currentCamera!.lensDirection == CameraLensDirection.front
            ? CameraLensDirection.back
            : CameraLensDirection.front;

    final newCamera = _cameras.firstWhere(
      (cam) => cam.lensDirection == newDirection,
      orElse: () => _cameras.first,
    );

    // 2. Stop and dispose of the current controller
    await stopStream();
    await _controller?.dispose();
    _controller = null;

    // 3. Initialize the new camera
    _currentCamera = newCamera;

    // Re-initialize a fresh controller for the new camera.
    final controller = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await controller.initialize();
      _controller = controller;
    } catch (e) {
      debugPrint("Camera switch error: $e");
    }

    return _currentCamera;
  }

  /// Captures a high-resolution image using the current camera.
  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    if (_controller!.value.isTakingPicture) return null;

    return await _controller!.takePicture();
  }

  /// Disposes of the camera controller to release resources.
  void dispose() {
    _controller?.dispose();
  }
}

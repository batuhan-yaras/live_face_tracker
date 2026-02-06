import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraManager {
  CameraController? _controller;
  CameraDescription? _currentCamera;
  List<CameraDescription> _cameras = []; // Tüm kameraları tutacak liste

  CameraController? get controller => _controller;

  /// Initializes the camera.
  /// If [initialCameraDirection] is provided, it tries to select that camera.
  Future<void> initialize({
    CameraLensDirection initialCameraDirection = CameraLensDirection.front,
  }) async {
    _cameras = await availableCameras();

    if (_cameras.isEmpty) {
      debugPrint("No cameras found");
      return;
    }

    // İstenen yöndeki kamerayı bul, yoksa ilkini seç
    _currentCamera = _cameras.firstWhere(
      (cam) => cam.lensDirection == initialCameraDirection,
      orElse: () => _cameras.first,
    );

    await _initController(_currentCamera!);
  }

  /// Internal helper to initialize the specific camera controller
  Future<void> _initController(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid
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

  /// Starts the image stream for processing
  Future<void> startStream(Function(CameraImage) onImage) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    await _controller!.startImageStream(onImage);
  }

  /// Stops the stream
  Future<void> stopStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }

  /// Switches the camera to the opposite direction (Front <-> Back)
  /// Returns the new CameraDescription to update the UI/Controller
  Future<CameraDescription?> switchCamera() async {
    if (_cameras.isEmpty || _currentCamera == null) return null;

    // 1. Yönü değiştir
    final newDirection =
        _currentCamera!.lensDirection == CameraLensDirection.front
            ? CameraLensDirection.back
            : CameraLensDirection.front;

    final newCamera = _cameras.firstWhere(
      (cam) => cam.lensDirection == newDirection,
      orElse: () => _cameras.first,
    );

    // 2. Eskiyi durdur
    await stopStream();
    await _controller?.dispose();
    _controller = null;

    // 3. Yeniyi başlat (Mevcut _initController metodunu kullanarak)
    _currentCamera = newCamera;

    // _initController private olduğu için burada tekrar kodunu yazabilir
    // veya _initController'ı çağırabilirsin. En temiz yol:
    final controller = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid
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

  // ... (takePicture ve dispose metodların aynı kalabilir)
  Future<XFile?> takePicture() async {
    // ... (Mevcut kodun aynısı)
    if (_controller == null || !_controller!.value.isInitialized) return null;
    if (_controller!.value.isTakingPicture) return null;
    return await _controller!.takePicture();
  }

  void dispose() {
    _controller?.dispose();
  }
}

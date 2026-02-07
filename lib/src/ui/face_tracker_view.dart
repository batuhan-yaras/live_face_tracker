import 'dart:math' as math;
import 'dart:ui' as ui; // Needed for Rect/Size in compute
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // For compute
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../camera/camera_manager.dart';
import '../face_detection/face_detector_service.dart';
import 'face_capture_result.dart';
import 'face_tracker_controller.dart';
import 'painters/face_painter.dart';

/// The main widget that orchestrates the camera feed, face tracking UI, and exposes detection data.
class FaceTrackerView extends StatefulWidget {
  final Color activeColor;
  final FaceFrameStyle frameStyle;
  final FaceTrackerController? controller;
  final bool showFrame;
  final bool showCaptureButton;

  /// Callback that returns the list of detected faces mapped to screen coordinates.
  final Function(List<Rect> faces)? onFacesDetected;

  /// Callback fired when the built-in shutter button is pressed.
  final Function(FaceCaptureResult result)? onPhotoCaptured;

  const FaceTrackerView({
    super.key,
    this.activeColor = Colors.cyanAccent,
    this.frameStyle = FaceFrameStyle.cornerBracket,
    this.controller,
    this.onFacesDetected,
    this.showFrame = true,
    this.showCaptureButton = true,
    this.onPhotoCaptured,
  });

  @override
  State<FaceTrackerView> createState() => _FaceTrackerViewState();
}

class _FaceTrackerViewState extends State<FaceTrackerView> {
  final CameraManager _cameraManager = CameraManager();
  final FaceDetectorService _faceDetectorService = FaceDetectorService();

  // --- SMART SMOOTHING STATE ---
  Rect? _smoothFaceRect;
  // -----------------------------

  // UI State
  Rect? _targetFaceRect;
  Size _imageSize = Size.zero;
  InputImageRotation _rotation = InputImageRotation.rotation270deg;
  bool _isInitialized = false;
  bool _isBusy = false;
  Size _widgetSize = Size.zero;

  FaceTrackerController? _internalController;

  FaceTrackerController get _effectiveController =>
      widget.controller ?? (_internalController ??= FaceTrackerController());

  @override
  void initState() {
    super.initState();
    _initialize();
    _effectiveController.attach(
      takePicture: _cameraManager.takePicture,
      switchCamera: _onCameraSwitchRequest,
    );
  }

  Future<void> _initialize() async {
    await _cameraManager.initialize();
    await _cameraManager.startStream(_processCameraImage);
    if (mounted) setState(() => _isInitialized = true);
  }

  // --- CAMERA SWITCH LOGIC ---
  Future<void> _onCameraSwitchRequest() async {
    if (mounted) {
      // 1. Pause rendering immediately to prevent black screen glitches
      setState(() {
        _isInitialized = false;
        _targetFaceRect = null;
        _smoothFaceRect = null;
        _imageSize = Size.zero;
      });

      // 2. Notify external UI to clear immediately
      if (widget.onFacesDetected != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onFacesDetected!([]);
        });
      }
    }

    // 3. Perform the hardware switch
    final newCamera = await _cameraManager.switchCamera();

    // 4. Resume rendering with new camera
    if (newCamera != null && mounted) {
      await _cameraManager.startStream(_processCameraImage);
      setState(() => _isInitialized = true);
    }
  }

  void _processCameraImage(CameraImage image) async {
    // 🛑 BUSY CHECK: If previous frame is still processing, DROP this one.
    if (_isBusy) return;
    _isBusy = true;

    try {
      if (_cameraManager.controller == null) return;

      final description = _cameraManager.controller!.description;
      final sensorOrientation = description.sensorOrientation;
      final lensDirection = description.lensDirection;

      // 1. Detect Faces (Heavy ML Task)
      final detectedFaces = await _faceDetectorService.detectFacesFromImage(
        image,
        description,
        sensorOrientation,
      );

      if (!mounted) return;

      final newImageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final newRotation =
          InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation270deg;

      if (detectedFaces.isEmpty) {
        _smoothFaceRect = null;
        _targetFaceRect = null;

        setState(() {
          // DİKKAT: _imageSize = Size.zero YAPMA!
          // _imageSize'ı koru ki ekrandaki görüntü bozulmasın (Siyah ekran çözümü).
          if (newImageSize.width > 0) {
            _imageSize = newImageSize;
            _rotation = newRotation;
          }

          // Controller'a boş veri gönder
          if (_imageSize.width > 0) {
            _effectiveController.updateFaceData(null, _imageSize, description);
          }
        });

        // Dışarıya boş liste gönder (Custom UI temizlensin)
        if (widget.onFacesDetected != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onFacesDetected!([]);
          });
        }

        return; // İşlemi burada kes.
      }
      // ============================================================
      // 🛑 EMPTY STATE HANDLING (CRITICAL FIX)
      // ============================================================
      if (detectedFaces.isEmpty) {
        // Reset Logic: If no face, clear everything.
        _smoothFaceRect = null;
        _targetFaceRect = null;

        setState(() {
          _imageSize = newImageSize;
          _rotation = newRotation;
          // Clear controller data
          if (_imageSize != Size.zero) {
            _effectiveController.updateFaceData(null, _imageSize, description);
          }
        });

        // Notify external UI to clear (prevents sticky custom UI)
        if (widget.onFacesDetected != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onFacesDetected!([]);
          });
        }

        // EXIT EARLY: Do not run compute or math on empty data.
        // This prevents the "Black Screen" error caused by null calculations.
        return;
      }
      // ============================================================

      // --- IF WE ARE HERE, WE HAVE A FACE ---

      // 2. Offload Coordinate Mapping to Isolate (Compute)
      // Only run if widget size is known to avoid division by zero
      Rect? currentRawRect;
      if (_widgetSize != Size.zero &&
          _widgetSize.width > 0 &&
          _widgetSize.height > 0) {
        final mappingData = _MappingData(
          boundingBox: detectedFaces.first.boundingBox,
          imageSize: newImageSize,
          widgetSize: _widgetSize,
          rotation: newRotation,
          lensDirection: lensDirection,
        );

        // Run heavy math in background isolate
        currentRawRect = await compute(_mapFacesInIsolate, mappingData);
      }

      // 3. Smart Smoothing (Adaptive Low-Pass Filter)
      if (currentRawRect != null) {
        if (_smoothFaceRect == null) {
          _smoothFaceRect = currentRawRect; // Jump to position instantly
        } else {
          double distance =
              (_smoothFaceRect!.center - currentRawRect.center).distance;
          // Dynamic Sensitivity:
          // Fast movement (>50px) -> High lerp (0.9) -> Fast follow
          // Slow movement (<5px)  -> Low lerp (0.1)  -> Smooth/No jitter
          double sensitivity = 50.0;
          double lerpFactor = (distance / sensitivity).clamp(0.1, 0.9);
          _smoothFaceRect = Rect.lerp(
            _smoothFaceRect,
            currentRawRect,
            lerpFactor,
          );
        }
      }

      // 4. Update UI State (Internal Frame & Controller)
      setState(() {
        _targetFaceRect = detectedFaces.first.boundingBox;
        _imageSize = newImageSize;
        _rotation = newRotation;

        if (_imageSize != Size.zero) {
          _effectiveController.updateFaceData(
            _targetFaceRect,
            _imageSize,
            description,
          );
        }
      });

      // 5. Send Processed (Smoothed) Data to User
      if (widget.onFacesDetected != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onFacesDetected!(
              _smoothFaceRect != null ? [_smoothFaceRect!] : [],
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Error processing frame: $e");
    } finally {
      _isBusy = false; // Unlock for next frame
    }
  }

  @override
  void dispose() {
    _cameraManager.stopStream();
    _cameraManager.dispose();
    _faceDetectorService.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final result = await _effectiveController.capture();
    if (result != null && widget.onPhotoCaptured != null) {
      widget.onPhotoCaptured!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if camera is not ready
    if (!_isInitialized ||
        _cameraManager.controller == null ||
        !_cameraManager.controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: widget.activeColor),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _widgetSize = Size(constraints.maxWidth, constraints.maxHeight);

        final size = MediaQuery.of(context).size;
        var scale =
            size.aspectRatio * _cameraManager.controller!.value.aspectRatio;
        if (scale < 1) scale = 1 / scale;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Camera Preview
            Transform.scale(
              scale: scale,
              child: Center(child: CameraPreview(_cameraManager.controller!)),
            ),

            // Layer 2: Built-in Tracking Frame
            // We verify that _imageSize is valid to prevent drawing errors
            if (widget.showFrame &&
                _imageSize.width > 0 &&
                _targetFaceRect != null)
              TweenAnimationBuilder<Rect?>(
                tween: RectTween(
                  begin: _targetFaceRect, // Null yerine direkt hedefi ver
                  end: _targetFaceRect,
                ),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                builder: (context, animatedRect, child) {
                  return CustomPaint(
                    painter: FacePainter(
                      faceRect: animatedRect,
                      absoluteImageSize: _imageSize,
                      rotation: _rotation,
                      activeColor: widget.activeColor,
                      style: widget.frameStyle,
                      isFrontCamera:
                          _cameraManager
                              .controller
                              ?.description
                              .lensDirection ==
                          CameraLensDirection.front,
                    ),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  );
                },
              ),

            // Layer 3: Capture Button
            if (widget.showCaptureButton)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// --- ISOLATE HELPERS ---

/// Data transfer object for the compute function
class _MappingData {
  final Rect boundingBox;
  final Size imageSize;
  final Size widgetSize;
  final InputImageRotation rotation;
  final CameraLensDirection lensDirection;

  _MappingData({
    required this.boundingBox,
    required this.imageSize,
    required this.widgetSize,
    required this.rotation,
    required this.lensDirection,
  });
}

/// Standalone function to run in a background Isolate.
/// Maps camera coordinates to screen coordinates.
Rect _mapFacesInIsolate(_MappingData data) {
  final bool isRotated =
      data.rotation == InputImageRotation.rotation90deg ||
      data.rotation == InputImageRotation.rotation270deg;

  final double imageWidth =
      isRotated ? data.imageSize.height : data.imageSize.width;
  final double imageHeight =
      isRotated ? data.imageSize.width : data.imageSize.height;

  // Calculate Scale
  final double scaleX = data.widgetSize.width / imageWidth;
  final double scaleY = data.widgetSize.height / imageHeight;
  final double scale = scaleX > scaleY ? scaleX : scaleY;

  // Calculate Offset
  final double offsetX = (imageWidth * scale - data.widgetSize.width) / 2;
  final double offsetY = (imageHeight * scale - data.widgetSize.height) / 2;

  final rawFace = data.boundingBox;
  double left, right;

  // FIX: Back Camera Inversion Logic
  if (data.lensDirection == CameraLensDirection.front) {
    // Front Camera: Needs mirroring
    left = (imageWidth - rawFace.right) * scale - offsetX;
    right = (imageWidth - rawFace.left) * scale - offsetX;
  } else {
    // Back Camera: No mirroring (standard mapping)
    left = rawFace.left * scale - offsetX;
    right = rawFace.right * scale - offsetX;
  }

  double top = rawFace.top * scale - offsetY;
  double bottom = rawFace.bottom * scale - offsetY;

  return Rect.fromLTRB(left, top, right, bottom);
}

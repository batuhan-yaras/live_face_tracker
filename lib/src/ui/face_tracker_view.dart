import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../camera/camera_manager.dart';
import '../face_detection/face_detector_service.dart';
import 'painters/face_painter.dart';

/// The main widget that orchestrates the camera feed and face tracking UI.
class FaceTrackerView extends StatefulWidget {
  final Color activeColor;
  final FaceFrameStyle frameStyle;

  const FaceTrackerView({
    super.key,
    this.activeColor = Colors.cyanAccent,
    this.frameStyle = FaceFrameStyle.cornerBracket,
  });

  @override
  State<FaceTrackerView> createState() => _FaceTrackerViewState();
}

class _FaceTrackerViewState extends State<FaceTrackerView> {
  final CameraManager _cameraManager = CameraManager();
  final FaceDetectorService _faceDetectorService = FaceDetectorService();

  // Anti-Flicker (Debounce) variables
  int _noFaceFrameCount = 0;
  static const int _maxEmptyFramesTolerance =
      3; // Keep drawing for 3 frames if face is lost

  List<Face> _faces = [];
  Size _imageSize = Size.zero;

  // Start with a safe default value
  InputImageRotation _rotation = InputImageRotation.rotation270deg;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _cameraManager.initialize();
    await _cameraManager.startStream(_processCameraImage);

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _processCameraImage(CameraImage image) async {
    // Safety check
    if (_cameraManager.controller == null) return;

    final description = _cameraManager.controller!.description;
    final sensorOrientation = description.sensorOrientation;

    final detectedFaces = await _faceDetectorService.detectFacesFromImage(
      image,
      description,
      sensorOrientation,
    );

    if (!mounted) return;

    setState(() {
      // --- ANTI-FLICKER LOGIC ---
      if (detectedFaces.isNotEmpty) {
        // Face found: Update immediately and reset counter
        _faces = detectedFaces;
        _noFaceFrameCount = 0;
      } else {
        // No face found: Don't clear immediately!
        _noFaceFrameCount++;

        // Only clear if the tolerance limit is exceeded (e.g., 3 frames)
        if (_noFaceFrameCount > _maxEmptyFramesTolerance) {
          _faces = [];
        }
        // Otherwise, the old _faces list remains on screen (Ghost effect)
      }
      // --------------------------

      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      _rotation =
          InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation270deg;
    });
  }

  @override
  void dispose() {
    _cameraManager.stopStream();
    _cameraManager.dispose();
    _faceDetectorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraManager.controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    // --- ASPECT RATIO FIX ---
    // Get screen dimensions
    final size = MediaQuery.of(context).size;

    // Calculate scale to ensure the camera preview covers the entire screen
    // without distortion.
    var scale = size.aspectRatio * _cameraManager.controller!.value.aspectRatio;

    // If scale is less than 1, zoom in to fill the screen (BoxFit.cover logic)
    if (scale < 1) scale = 1 / scale;
    // ------------------------

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Camera Preview (Correctly Scaled)
        Transform.scale(
          scale: scale,
          child: Center(child: CameraPreview(_cameraManager.controller!)),
        ),

        // Layer 2: Face Tracking Overlay
        if (_imageSize != Size.zero)
          LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                painter: FacePainter(
                  faces: _faces,
                  absoluteImageSize: _imageSize,
                  rotation: _rotation,
                  activeColor: widget.activeColor,
                  style: widget.frameStyle,
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              );
            },
          ),
      ],
    );
  }
}

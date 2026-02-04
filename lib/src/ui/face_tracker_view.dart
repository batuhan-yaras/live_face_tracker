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

  // State to hold detected faces
  List<Face> _faces = [];

  // Details needed for the painter to scale coordinates correctly
  Size _imageSize = Size.zero;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. Setup Camera
    await _cameraManager.initialize();

    // 2. Start Listening to the stream
    await _cameraManager.startStream(_processCameraImage);

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  /// Processes each frame from the camera stream.
  void _processCameraImage(CameraImage image) async {
    // Need camera description to calculate rotation (assuming front camera for now)
    final description = _cameraManager.controller!.description;

    // Calculate rotation (Critical for mapping coordinates)
    final sensorOrientation = description.sensorOrientation;

    // Detect faces
    final faces = await _faceDetectorService.detectFacesFromImage(
      image,
      description,
      sensorOrientation,
    );

    if (!context.mounted) {
      return;
    }
    setState(() {
      _faces = faces;
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      // In a robust app, we'd calculate this dynamically based on device orientation
      _rotation =
          InputImageRotation
              .rotation270deg; // Common for portrait mode on Android
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
        child: CircularProgressIndicator(
          color: Colors.cyanAccent,
          strokeWidth: 2,
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: The Camera Feed
        CameraPreview(_cameraManager.controller!),

        // Layer 2: The Face Tracking Overlay
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

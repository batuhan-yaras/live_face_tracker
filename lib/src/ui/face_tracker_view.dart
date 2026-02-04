import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../camera/camera_manager.dart';
import '../face_detection/face_detector_service.dart';
import 'painters/face_painter.dart';

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

  int _noFaceFrameCount = 0;
  static const int _maxEmptyFramesTolerance = 3;

  /// The target rectangle for the face, used for animation interpolation.
  Rect? _targetFaceRect;

  Size _imageSize = Size.zero;
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
      if (detectedFaces.isNotEmpty) {
        /// Use the first detected face as the target for interpolation.
        _targetFaceRect = detectedFaces.first.boundingBox;
        _noFaceFrameCount = 0;
      } else {
        _noFaceFrameCount++;
        if (_noFaceFrameCount > _maxEmptyFramesTolerance) {
          _targetFaceRect = null; // Clear target to animate removal.
        }
      }

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

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _cameraManager.controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scale: scale,
          child: Center(child: CameraPreview(_cameraManager.controller!)),
        ),

        if (_imageSize != Size.zero)
          LayoutBuilder(
            builder: (context, constraints) {
              /// TweenAnimationBuilder interpolates the Rect values over time
              /// to provide smooth motion even if the face detection rate is low.
              return TweenAnimationBuilder<Rect?>(
                tween: RectTween(
                  begin: _targetFaceRect ?? Rect.zero,
                  end: _targetFaceRect,
                ),

                /// 150ms is short enough to be responsive but long enough to feel smooth.
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
                    ),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

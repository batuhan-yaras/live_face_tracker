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

  List<Face> _faces = [];
  Size _imageSize = Size.zero;
  // Başlangıçta güvenli bir varsayılan değer
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
    final description = _cameraManager.controller!.description;
    final sensorOrientation = description.sensorOrientation;

    final faces = await _faceDetectorService.detectFacesFromImage(
      image,
      description,
      sensorOrientation,
    );

    if (!mounted) return;

    setState(() {
      _faces = faces;
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      // Düzeltme: Sabit 270 yerine sensörün gerçek açısını kullanıyoruz.
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

    // --- DÜZELTME BAŞLIYOR: ASPECT RATIO FIX ---
    // Ekranın ve kameranın boyutlarını alıyoruz.
    final size = MediaQuery.of(context).size;

    // Kamera dikey modda olduğu için (Portrait), aspect ratio'yu ters çevirmemiz gerekebilir
    // Ancak controller.value.aspectRatio genellikle genişlik/yükseklik verir.
    // Dikey tutuşta ekran dar ve uzundur (örn: 0.5), kamera genelde 4:3 veya 16:9'dur.
    var scale = size.aspectRatio * _cameraManager.controller!.value.aspectRatio;

    // Eğer scale 1'den küçükse, görüntüyü yanlardan kırpmak yerine zoom yaparak doldurmalıyız.
    if (scale < 1) scale = 1 / scale;
    // --- DÜZELTME BİTİYOR ---

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

import 'package:camera/camera.dart';
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

  // Internal state for UI rendering
  int _noFaceFrameCount = 0;
  static const int _maxEmptyFramesTolerance = 3;
  Rect? _targetFaceRect;

  // Camera and Screen properties
  Size _imageSize = Size.zero;
  InputImageRotation _rotation = InputImageRotation.rotation270deg;
  bool _isInitialized = false; // <--- KRİTİK DEĞİŞKEN

  // Current widget size
  Size _widgetSize = Size.zero;

  // Internal controller fallback
  FaceTrackerController? _internalController;

  FaceTrackerController get _effectiveController =>
      widget.controller ?? (_internalController ??= FaceTrackerController());

  @override
  void initState() {
    super.initState();
    _initialize();

    // Controller'ı bağla
    _effectiveController.attach(
      takePicture: _cameraManager.takePicture,
      switchCamera: _onCameraSwitchRequest, // Handler burada bağlanıyor
    );
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

  // --- KRİTİK DÜZELTME BURADA ---
  Future<void> _onCameraSwitchRequest() async {
    // 1. UI'ı Yükleniyor moduna al ve TEMİZLİK YAP
    if (mounted) {
      setState(() {
        _isInitialized = false; // Loading spinner'ı aç
        _targetFaceRect = null; // Dahili çerçeveyi (yeşil kutu) sil
        _imageSize = Size.zero; // Eski resim boyutunu unut
      });

      // ⚠️ KRİTİK EKLEME: CUSTOM UI TEMİZLİĞİ
      // Kamera akışı durduğu için dedektör çalışmaz.
      // Bu yüzden "yüz yok" bilgisini manuel olarak biz göndermeliyiz.
      // Böylece ekrandaki Custom UI (Emoji, Maske vb.) donup kalmaz.
      if (widget.onFacesDetected != null) {
        widget.onFacesDetected!([]);
      }
    }

    // 2. Kamerayı değiştir
    final newCamera = await _cameraManager.switchCamera();

    // 3. Yeni kamera açıldıysa akışı tekrar başlat
    if (newCamera != null && mounted) {
      await _cameraManager.startStream(_processCameraImage);
      setState(() {
        _isInitialized = true;
      });
    }
  }
  // ------------------------------

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
        _targetFaceRect = detectedFaces.first.boundingBox;
        _noFaceFrameCount = 0;
      } else {
        _noFaceFrameCount++;
        if (_noFaceFrameCount > _maxEmptyFramesTolerance) {
          _targetFaceRect = null;
        }
      }

      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      _rotation =
          InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation270deg;

      if (_imageSize != Size.zero) {
        _effectiveController.updateFaceData(
          _targetFaceRect,
          _imageSize,
          _cameraManager.controller!.description,
        );
      }

      if (widget.onFacesDetected != null &&
          _widgetSize != Size.zero &&
          _imageSize != Size.zero) {
        final List<Rect> screenRects =
            detectedFaces.map((face) {
              return _mapFaceToScreenRect(
                face.boundingBox,
                _imageSize,
                _widgetSize,
                _rotation,
              );
            }).toList();

        widget.onFacesDetected!(screenRects);
      }
    });
  }

  Rect _mapFaceToScreenRect(
    Rect rawFace,
    Size imageSize,
    Size widgetSize,
    InputImageRotation rotation,
  ) {
    final bool isRotated =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;

    final double imageWidth = isRotated ? imageSize.height : imageSize.width;
    final double imageHeight = isRotated ? imageSize.width : imageSize.height;

    final double scaleX = widgetSize.width / imageWidth;
    final double scaleY = widgetSize.height / imageHeight;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    final double offsetX = (imageWidth * scale - widgetSize.width) / 2;
    final double offsetY = (imageHeight * scale - widgetSize.height) / 2;

    double left = (imageWidth - rawFace.right) * scale - offsetX;
    double top = rawFace.top * scale - offsetY;
    double right = (imageWidth - rawFace.left) * scale - offsetX;
    double bottom = rawFace.bottom * scale - offsetY;

    return Rect.fromLTRB(left, top, right, bottom);
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
    // _isInitialized FALSE ise Loading göster.
    // Bu, kamera değişirken hata almanı engeller.
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
            Transform.scale(
              scale: scale,
              child: Center(child: CameraPreview(_cameraManager.controller!)),
            ),

            if (widget.showFrame && _imageSize != Size.zero)
              TweenAnimationBuilder<Rect?>(
                tween: RectTween(
                  begin: _targetFaceRect ?? Rect.zero,
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
                    ),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  );
                },
              ),

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

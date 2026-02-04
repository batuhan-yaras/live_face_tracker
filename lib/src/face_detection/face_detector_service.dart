import 'dart:io'; // For platform checks
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      enableLandmarks: false,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15, // Detect smaller faces too
    ),
  );

  bool _isBusy = false;
  int _frameCounter = 0; // Counter to slow down logs

  Future<List<Face>> detectFacesFromImage(
    CameraImage image,
    CameraDescription description,
    int sensorOrientation,
  ) async {
    if (_isBusy) return [];
    _isBusy = true;

    try {
      final InputImage? inputImage = _inputImageFromCameraImage(
        image,
        description,
        sensorOrientation,
      );

      if (inputImage == null) return [];

      final faces = await _faceDetector.processImage(inputImage);

      // --- SMART LOGGING ---
      // Provide a status report every 60 frames (approx. 1-2 times per second)
      // ALWAYS log if a face is found.
      if (faces.isNotEmpty) {
        debugPrint(
          "✅ FACE FOUND: ${faces.length} detected! [Frame: $_frameCounter]",
        );
        debugPrint("   -> Coordinates: ${faces.first.boundingBox}");
      } else if (_frameCounter % 60 == 0) {
        debugPrint(
          "... searching ... (Processed Image: ${image.width}x${image.height})",
        );
      }

      _frameCounter++;
      // ----------------------

      return faces;
    } catch (e) {
      debugPrint("Error detecting faces: $e");
      return [];
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
    int sensorOrientation,
  ) {
    // 1. ROTATION CALCULATION
    final rotations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    // Default to portrait for now
    const deviceOrientation = DeviceOrientation.portraitUp;

    int rotationCompensation = 0;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation =
          (sensorOrientation + rotations[deviceOrientation]!) % 360;
    } else {
      rotationCompensation =
          (sensorOrientation - rotations[deviceOrientation]! + 360) % 360;
    }

    // 2. BYTE CONVERSION AND FORMAT
    // The distinction between Android and iOS is critical.

    InputImageFormat inputImageFormat = InputImageFormat.nv21; // Default

    // If Android and format is YUV420, force NV21
    if (Platform.isAndroid) {
      // On Android, CameraImage usually comes as YUV_420_888 (35).
      // Since we are manually merging planes, we must tell ML Kit this is NV21.
      inputImageFormat = InputImageFormat.nv21;
    } else {
      // iOS usually sends bgra8888
      final rawValue = image.format.raw;
      inputImageFormat =
          InputImageFormatValue.fromRawValue(rawValue) ?? InputImageFormat.nv21;
    }

    // Flatten plane data into a single byte array
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final InputImageMetadata metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation:
          InputImageRotationValue.fromRawValue(rotationCompensation) ??
          InputImageRotation.rotation0deg,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  void dispose() {
    _faceDetector.close();
  }
}

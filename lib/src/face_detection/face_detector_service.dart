import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:live_face_tracker/src/utils/input_image_converter.dart';

/// A service class responsible for detecting faces in a given camera image using Google ML Kit.
class FaceDetectorService {
  late final FaceDetector _faceDetector;

  /// Initializes the FaceDetector with specific options tailored for
  /// real-time video processing.
  FaceDetectorService() {
    final options = FaceDetectorOptions(
      // 'fast' mode is crucial for real-time video processing to maintain fps.
      performanceMode: FaceDetectorMode.fast,

      // We need contours/landmarks? Not for just a bounding box.
      // Keep it simple for performance.
      enableContours: false,
      enableLandmarks: false,

      // Identifying faces (ID tracking) helps in keeping the tracking stable across frames.
      enableTracking: true,
    );

    _faceDetector = FaceDetector(options: options);
  }

  /// Processes a single [CameraImage] and returns a list of detected [Face]s.
  ///
  /// Requires [cameraDescription] and [sensorOrientation] to correctly orient the image for the detector.
  Future<List<Face>> detectFacesFromImage(
    CameraImage image,
    CameraDescription cameraDescription,
    int sensorOrientation,
  ) async {
    // 1. Convert CameraImage to InputImage
    final InputImage? inputImage = InputImageConverter.processCameraImage(
      image,
      cameraDescription,
      sensorOrientation,
    );

    if (inputImage == null) return [];

    // 2. Pass the converted image to ML Kit
    try {
      return await _faceDetector.processImage(inputImage);
    } catch (e) {
      debugPrint('Face Detection Error: $e');
      return [];
    }
  }

  /// Releases resources used by the face detector.
  void dispose() {
    _faceDetector.close();
  }
}

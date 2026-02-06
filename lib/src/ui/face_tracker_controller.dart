import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'face_capture_result.dart';

class FaceTrackerController {
  // Handlers (View tarafından bağlanacak fonksiyonlar)
  Future<XFile?> Function()? _takePictureHandler;
  Future<void> Function()? _switchCameraHandler; // <--- YENİ EKLENDİ

  // State Data
  CameraDescription? _cameraDescription;
  Rect? _lastDetectedFaceRect;
  Size? _previewSize;

  /// Switches between front and back cameras.
  Future<void> switchCamera() async {
    if (_switchCameraHandler != null) {
      await _switchCameraHandler!();
    }
  }

  /// Captures a photo, optionally mirrors it if it's from the front camera,
  /// and performs face detection on the final processed image.
  Future<FaceCaptureResult?> capture() async {
    if (_takePictureHandler == null) {
      throw Exception("FaceTrackerController is not attached.");
    }

    // 1. Capture the raw image
    XFile? photoFile = await _takePictureHandler!();
    if (photoFile == null) return null;

    Rect? finalFaceRect;
    FaceDetector? tempDetector;

    try {
      // 2. Handle Mirroring Logic (Ön Kamera Aynalama Sorunu Çözümü)
      if (_cameraDescription?.lensDirection == CameraLensDirection.front) {
        final bytes = await photoFile.readAsBytes();
        img.Image? originalImage = img.decodeImage(bytes);

        if (originalImage != null) {
          // Resmi yatayda çevir (Ayna etkisi)
          img.Image mirroredImage = img.flipHorizontal(originalImage);

          // Çevrilmiş resmi tekrar dosyaya yaz (Üzerine yazıyoruz)
          final encodedBytes = img.encodeJpg(mirroredImage);
          final File fixedFile = File(photoFile.path);
          await fixedFile.writeAsBytes(encodedBytes);
        }
      }

      // 3. Create InputImage form the (possibly modified) file
      final inputImage = InputImage.fromFilePath(photoFile.path);

      // 4. Setup temporary FaceDetector
      final options = FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
        enableLandmarks: false,
        enableContours: false,
        enableClassification: false,
      );
      tempDetector = FaceDetector(options: options);

      // 5. Detect faces in the FINAL image
      final List<Face> faces = await tempDetector.processImage(inputImage);

      // 6. Select the primary face
      if (faces.isNotEmpty) {
        faces.sort((a, b) {
          double areaA = a.boundingBox.width * a.boundingBox.height;
          double areaB = b.boundingBox.width * b.boundingBox.height;
          return areaB.compareTo(areaA);
        });
        finalFaceRect = faces.first.boundingBox;
      }
    } catch (e) {
      print("Error during capture processing: $e");
    } finally {
      tempDetector?.close();
    }

    return FaceCaptureResult(image: photoFile, faceRect: finalFaceRect);
  }

  void updateFaceData(
    Rect? faceRect,
    Size previewSize,
    CameraDescription description,
  ) {
    _lastDetectedFaceRect = faceRect;
    _previewSize = previewSize;
    _cameraDescription = description;
  }

  /// Attaches logic handlers from the View to this Controller.
  void attach({
    required Future<XFile?> Function() takePicture,
    required Future<void> Function() switchCamera, // <--- Yeni
  }) {
    _takePictureHandler = takePicture;
    _switchCameraHandler = switchCamera; // <--- Bağla
  }

  void dispose() {
    _takePictureHandler = null;
    _switchCameraHandler = null;
    _lastDetectedFaceRect = null;
    _previewSize = null;
    _cameraDescription = null;
  }
}

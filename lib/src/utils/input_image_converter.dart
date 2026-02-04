import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Utility class to convert [CameraImage] from the camera package
/// into [InputImage] format required by Google ML Kit.
class InputImageConverter {
  /// Converts a [CameraImage] to an [InputImage].
  ///
  /// [camera] is the description of the camera being used (needed for rotation).
  /// [sensorOrientation] is the orientation of the device sensor.
  static InputImage? processCameraImage(
    CameraImage image,
    CameraDescription camera,
    int sensorOrientation,
  ) {
    final WriteBuffer allBytes = WriteBuffer();

    // Concatenate the planes of the image into a single byte buffer.
    // Android (NV21) and iOS (BGRA8888) handle planes differently.
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // Calculate the image size (width and height).
    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    // Calculate the rotation needed for the image to be upright.
    final InputImageRotation imageRotation = _rotationIntToImageRotation(
      sensorOrientation,
    );

    // Create the metadata required by ML Kit.
    final InputImageMetadata inputImageMetadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format:
          InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
  }

  /// Helper method to convert sensor orientation (int) to [InputImageRotation] enum.
  static InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      case 0:
      default:
        return InputImageRotation.rotation0deg;
    }
  }
}

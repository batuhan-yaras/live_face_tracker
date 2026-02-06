import 'dart:ui';
import 'package:camera/camera.dart';

/// A result class containing the captured image and the detected face's location.
///
/// This class serves as the single source of truth for the capture result.
/// The [faceRect] is already mapped to the [image]'s resolution and coordinate system,
/// meaning no further calculation or mapping is required by the consumer.
class FaceCaptureResult {
  /// The captured image file.
  final XFile image;

  /// The bounding box of the detected face, mapped to the [image]'s actual resolution.
  ///
  /// This [Rect] is in the coordinate space of the [image].
  /// If no face was detected at the moment of capture, this will be null.
  ///
  /// Logic applied:
  /// - Scaled from Preview Resolution -> Image Resolution.
  /// - Mirrored horizontally if the capture was from a front-facing camera.
  final Rect? faceRect;

  const FaceCaptureResult({required this.image, this.faceRect});

  @override
  String toString() =>
      'FaceCaptureResult(image: ${image.path}, faceRect: $faceRect)';
}

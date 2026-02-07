# live_face_tracker 📸

A high-performance Flutter package for **real-time face detection, tracking, and photography**. 

It leverages Google's ML Kit to detect faces and provides a smooth, jitter-free visual overlay. Beyond just display, it offers a complete camera solution with **coordinate mapping**, allowing you to capture high-res photos with perfectly aligned face bounding boxes—no manual math required.

[![Pub Version](https://img.shields.io/pub/v/live_face_tracker?color=blue)](https://pub.dev/packages/live_face_tracker)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)]()

---

## 🌟 Motivation

While developing my latest application, I realized that although Google's ML Kit is powerful for face detection, building a production-ready camera implementation around it is difficult.

Drawing a smooth tracking frame, handling aspect ratios, synchronizing screen coordinates with image coordinates, and managing front-camera mirroring requires significant engineering effort. 

I developed **live_face_tracker** to provide a "plug-and-play" solution. Whether you need a simple face tracking overlay or raw face data to build Snapchat-like filters, this package handles the heavy lifting.

---

## 🎬 Preview

<div align="center">
  <img src="assets/gifs/face_tracking.gif" width="300"/>
  
  <p>
    <i>Experience buttery smooth, real-time tracking. <br>
    Use the built-in customizable frames or go <b>Headless</b> to build your own custom AR overlays.</i>
  </p>
</div>

---

## ✨ Key Features

* 🚀 **Real-time Detection:** Powered by `google_mlkit_face_detection` for ultra-fast processing.
* 📸 **Smart Capture:** Built-in shutter button and controller support. Captures high-res photos and **automatically maps** face coordinates to the image resolution (handling scaling & mirroring for you).
* 🧠 **Headless Mode:** Disable the default UI (`showFrame: false`) and use the `onFacesDetected` stream to build your own custom UI using the raw face coordinates.
* 🌊 **Motion Interpolation:** Smooths out bounding box movements (150ms cubic easing) to eliminate jitter.
* 🛡️ **Anti-Flicker System:** Keeps the UI stable even if the detector misses a frame.
* 🔄 **Camera Switch:** Full support for toggling between Front and Back cameras.

---
<!-- 
## 📦 Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  live_face_tracker: ^latest_version
```

--- -->

## 🚀 Usage

### 1. Basic Usage (Plug & Play)
Simply add the widget. It handles the camera, permission, and tracking frame automatically.

```dart
FaceTrackerView(
  activeColor: Colors.greenAccent,
  frameStyle: FaceFrameStyle.cornerBracket,
)
```

### 2. Advanced Usage (Controller & Capture)
Use the `FaceTrackerController` to switch cameras or take photos programmatically. The result contains the image and the face coordinates mapped to that image.

```dart
final FaceTrackerController _controller = FaceTrackerController();

// ... inside your build method
FaceTrackerView(
  controller: _controller,
  showCaptureButton: true, // Shows built-in UI button
  onPhotoCaptured: (FaceCaptureResult result) {
    // result.image -> The captured XFile
    // result.faceRect -> The face coordinates mapped to the high-res image
    print("Face saved at: ${result.faceRect}");
  },
)

// ... Programmatic actions
_controller.switchCamera(); // Toggle Front/Back
_controller.capture();      // Take photo
```

### 3. Headless Mode (Custom UI)
Want to build your own filter or mask? Disable the built-in frame and use the real-time data stream.
* **⚠️ Performance Note:** The onFacesDetected stream returns raw coordinates directly from the detector (typically 15-30 FPS). To achieve a smooth 60 FPS experience like the built-in frame, you should implement your own interpolation (e.g., using TweenAnimationBuilder) in your custom UI.

```dart
FaceTrackerView(
  showFrame: false, // Hide the default bracket
  onFacesDetected: (List<Rect> faces) {
    // 'faces' contains the RAW screen coordinates.
    // Tip: Use TweenAnimationBuilder to smooth out the movement!
  },
)
```

---

## 🛠 API Reference

### FaceTrackerView
The primary widget. All parameters are optional except `key`.

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `controller` | `FaceTrackerController?` | `null` | Controls camera actions (capture, switch). |
| `activeColor` | `Color` | `Colors.cyanAccent` | Color of the default tracking frame. |
| `frameStyle` | `FaceFrameStyle` | `.cornerBracket` | Visual style (`cornerBracket`, `roundedBox`, `dottedLine`). |
| `showFrame` | `bool` | `true` | If false, hides the tracking overlay (useful for custom UIs). |
| `showCaptureButton` | `bool` | `true` | If true, shows a shutter button at the bottom. |
| `onFacesDetected` | `Function(List<Rect>)?` | `null` | Stream of raw face coordinates mapped to the screen. |
| `onPhotoCaptured` | `Function(FaceCaptureResult)?` | `null` | Callback containing the captured file and face data. |

---

### FaceTrackerController
Methods to control the camera programmatically.
* **capture():** Takes a photo and returns `Future<FaceCaptureResult?>`.
* **switchCamera():** Toggles between front and back lenses.
* **dispose():** Cleans up resources.

---

### FaceCaptureResult
The object returned after a capture.
* **`image (XFile):`** The captured image file.
* **`faceRect (Rect?):`** The bounding box of the face, already mapped to the image's actual resolution and orientation. You can use this directly to draw on the image (e.g., cropping the face or applying a blur).

---

## ⚡ Performance Optimizations

* **🧵 Isolate Computing:** Face coordinate mapping and scaling logic are executed in a background `Isolate`. This prevents frame drops (jank) on the UI thread, ensuring a buttery smooth experience even on older devices.
* **🌊 Adaptive Smoothing:** We use a dynamic low-pass filter logic. If the face is stationary, the jitter is filtered out. If the face moves quickly, the filter opens up to track instantly without lag.
* **📏 Smart Mapping:** The package handles the complex math of converting "Camera Sensor Coordinates" -> "Screen Coordinates" (for preview) and "Camera Sensor" -> "Image File Coordinates" (for capture), including handling mirroring for front/back cameras appropriately.

---

## 📱 Platform Support

* **Android:** Full support (min SDK 21).
* **iOS:** Full support (min iOS 11.0).

---

Developed with 💙 by **Batuhan Yaraş**.
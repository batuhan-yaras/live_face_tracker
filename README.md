# live_face_tracker 📸

A high-performance Flutter package for **real-time face detection and tracking**. It leverages Google's ML Kit to detect faces and provides a smooth, jitter-free visual overlay using custom motion interpolation and anti-flicker algorithms.

[![Pub Version](https://img.shields.io/pub/v/live_face_tracker?color=blue)](https://pub.dev/packages/live_face_tracker)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)]()

---

## 🌟 Motivation

While developing my latest application, I realized that although Google's ML Kit is powerful for face detection, drawing a smooth, responsive tracking frame around the face is surprisingly difficult and time-consuming. 

Managing camera streams, handling aspect ratios, and synchronizing coordinates between the image sensor and the screen requires significant engineering effort. I developed **live_face_tracker** to provide developers with an easy-to-use, "plug-and-play" solution for high-quality face tracking without the math headaches.

---

## 🎬 Previews

| **Dynamic Styling** | **Color Customization** | **Real-time Tracking** |
| :---: | :---: | :---: |
| ![Style Demo](YOUR_GIF_1_URL_HERE) | ![Color Demo](YOUR_GIF_2_URL_HERE) | ![Tracking Demo](YOUR_GIF_3_URL_HERE) |
| *Switching between Bracket, Box, and Dotted styles* | *Seamlessly changing the active tracking color* | *Butter-smooth motion with interpolation* |

---

## ✨ Key Features

* 🚀 **Real-time Detection:** Powered by `google_mlkit_face_detection` for ultra-fast processing.
* 🌊 **Motion Interpolation:** Uses `TweenAnimationBuilder` with cubic easing to smooth out bounding box movements (150ms smoothing), eliminating jitter and lag.
* 🛡️ **Anti-Flicker System:** Implements a "frame tolerance" mechanism (3 frames) to keep the UI stable during brief detection drops or lighting changes.
* 📏 **Auto-Scaling Preview:** Automatically handles camera aspect ratios and screen scaling to ensure perfect alignment on any device.
* 🎨 **Customizable UI:** Support for multiple frame styles via the `FaceFrameStyle` enum.

---

## 📦 Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  live_face_tracker: ^0.0.1
```

---

## 🚀 Usage

Implementing real-time face tracking is now as simple as adding a single widget:

```dart
import 'package:flutter/material.dart';
import 'package:live_face_tracker/live_face_tracker.dart';

void main() {
  runApp(const MaterialApp(home: FaceTrackerPage()));
}

class FaceTrackerPage extends StatelessWidget {
  const FaceTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FaceTrackerView(
        activeColor: Colors.greenAccent,
        frameStyle: FaceFrameStyle.cornerBracket,
      ),
    );
  }
}
```

---

## 🛠 API Reference

### FaceTrackerView
The primary widget that displays the camera feed and handles all tracking logic.

```dart
FaceTrackerView({
  Key? key,
  Color activeColor = Colors.cyanAccent,
  FaceFrameStyle frameStyle = FaceFrameStyle.cornerBracket,
})
```

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `activeColor` | `Color` | `Colors.cyanAccent` | The color of the tracking frame. |
| `frameStyle` | `FaceFrameStyle` | `.cornerBracket` | The visual style of the frame. |

---

### FaceFrameStyle(Enum)
* **.cornerBracket:** Tech-focused corner indicators for a futuristic look.
* **.roundedBox:** A clean, rounded rectangle surrounding the face.
* **.dottedLine:** A dashed outline providing a "scanning" effect.

---

## ⚡ Performance Optimizations

* 🚀 **Interpolation Engine:** Instead of jumping the bounding box instantly to new coordinates, we use `Curves.easeOutCubic` over 150ms. This masks the lower frame rate of detection compared to the UI frame rate, creating a fluid experience.
* 🚀 **Stability Logic:** The built-in `_maxEmptyFramesTolerance` ensures that the UI remains stable instead of flashing on and off when the detector misses a face for a split second (common in varying lighting conditions).
* 🚀 **Efficient Painting:** The `FacePainter` only repaints when the target rectangle, style, or color changes, minimizing CPU/GPU usage.

---

## 📱 Platform Support

* **Android:** Full support with specific YUV_420_888 to NV21 conversion logic.
* **iOS:** Full support with BGRA8888 handling.

---

Developed with 💙 by **Batuhan Yaraş**.


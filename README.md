# Live Face Tracker 📸

A high-performance Flutter package that detects faces using Google ML Kit on a live camera stream and tracks them with a dynamic UI frame.

## 🌟 Motivation

The seeds of this library were sown during my last project. I experienced firsthand how challenging, tedious, yet fascinating it is to build a live face tracking system from scratch without a dedicated external library.

Managing the camera stream, integrating image processing algorithms, and synchronizing coordinate systems (image space vs. screen space) required significant engineering effort.

Driven by that experience, I started developing `live_face_tracker` to make this technology accessible and to spare others from facing the same hurdles. My goal is not just to detect faces, but to provide a performance-first structure to developers.

## 🗺️ Roadmap

This library follows a "learning-by-doing" development principle. The current plan is:

- [ ] **Project Setup:** Establishing the basic package structure and CI/CD foundations.
- [ ] **Google ML Kit Integration:** Integrating the `google_mlkit_face_detection` package.
- [ ] **Camera Management:** Handling live image streams using the `camera` package.
- [ ] **Face Detection:** Processing incoming frames to extract face coordinates.
- [ ] **Coordinate Transformation (Painter):** Scaling raw face data to fit screen dimensions.
- [ ] **Tracking Mechanism (UI):** A UI component that aesthetically frames and tracks the face in sync with movement.

## 🛠️ Installation

*Development is ongoing. Instructions will be added upon the first stable release.*

## 🤝 Contributing

This project is open source and welcomes contributions. Please open an issue to discuss changes before submitting a Pull Request.

---
*Developed with 💙 by Batuhan Yaraş.*
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:live_face_tracker/live_face_tracker.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: TestLabPage()),
  );
}

class TestLabPage extends StatefulWidget {
  const TestLabPage({super.key});

  @override
  State<TestLabPage> createState() => _TestLabPageState();
}

class _TestLabPageState extends State<TestLabPage> {
  // --- 1. Customization State ---
  FaceFrameStyle _frameStyle = FaceFrameStyle.cornerBracket;
  Color _activeColor = Colors.cyanAccent;

  // --- 2. Toggles State ---
  bool _showFrame = true; // Show the package's built-in frame
  bool _showCaptureButton = true; // Show the package's built-in button
  bool _showCustomOverlay = false; // Show OUR custom "Devil" overlay
  bool _isPanelVisible = true; // Visibility of the bottom control panel
  bool _isLoading = false; // Global loading state (for switching/capturing)

  // --- 3. Data State (Anti-Flicker Logic) ---
  // We store the detected faces here to draw our custom UI.
  List<Rect> _detectedFaces = [];

  // Counter to handle brief moments where the detector loses the face.
  int _missedFrames = 0;
  static const int _frameTolerance =
      6; // Keep drawing the face for 6 frames even if lost.

  // --- 4. Controller ---
  // We instantiate the controller to trigger actions programmatically (like Switch Camera).
  final FaceTrackerController _controller = FaceTrackerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ------------------------------------------------
          // LAYER 1: The FaceTrackerView (The Package Core)
          // ------------------------------------------------
          FaceTrackerView(
            controller: _controller,
            frameStyle: _frameStyle,
            activeColor: _activeColor,
            showFrame: _showFrame,
            showCaptureButton: _showCaptureButton,

            // API: Real-time Face Coordinates
            // This callback gives us the mapped coordinates of the face on the screen.
            onFacesDetected: (faces) {
              if (_showCustomOverlay) {
                // Anti-Flicker Logic:
                // If the face is detected, update immediately.
                if (faces.isNotEmpty) {
                  _missedFrames = 0;
                  setState(() {
                    _detectedFaces = faces;
                  });
                } else {
                  // If face is lost, wait a few frames before clearing the UI.
                  // This prevents the emoji from blinking in and out.
                  _missedFrames++;
                  if (_missedFrames > _frameTolerance) {
                    setState(() {
                      _detectedFaces = [];
                    });
                  }
                }
              }
            },

            // API: Photo Capture Result
            // This returns the high-res image and the face coordinates mapped to it.
            onPhotoCaptured: (result) async {
              setState(() => _isLoading = true); // Show loading

              // Simulate a tiny delay for UX or processing
              await Future.delayed(const Duration(milliseconds: 100));

              setState(() => _isLoading = false); // Hide loading
              _showResultDialog(result);
            },
          ),

          // ------------------------------------------------
          // LAYER 2: Custom Developer Overlay (The Devil Emoji 😈)
          // ------------------------------------------------
          // Demonstrates how to build your own UI on top of the tracker.
          if (_showCustomOverlay)
            IgnorePointer(
              child: CustomPaint(
                painter: EmojiFacePainter(faces: _detectedFaces),
                size: Size.infinite,
              ),
            ),

          // ------------------------------------------------
          // LAYER 3: Top Controls (Switch Camera)
          // ------------------------------------------------
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Switch Camera Button
                _buildGlassButton(
                  icon: Icons.flip_camera_ios,
                  onTap: () async {
                    // Show loading spinner
                    setState(() => _isLoading = true);

                    // Trigger the switch in the package
                    await _controller.switchCamera();

                    // Hide loading spinner
                    setState(() => _isLoading = false);
                  },
                ),
                // Toggle Panel Button
                _buildGlassButton(
                  icon: _isPanelVisible ? Icons.close : Icons.tune,
                  onTap: () {
                    setState(() {
                      _isPanelVisible = !_isPanelVisible;
                    });
                  },
                ),
              ],
            ),
          ),

          // ------------------------------------------------
          // LAYER 4: The "Test Lab" Control Panel
          // ------------------------------------------------
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _isPanelVisible ? 0 : -350,
            left: 0,
            right: 0,
            child: _buildControlPanel(),
          ),

          // ------------------------------------------------
          // LAYER 5: Global Loading Indicator
          // ------------------------------------------------
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // --- UI Construction Helpers ---

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "🧪 Feature Test Lab",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isPanelVisible = false),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Toggles Row
          Row(
            children: [
              _buildSwitch(
                "Default Frame",
                _showFrame,
                (v) => setState(() => _showFrame = v),
              ),
              _buildSwitch(
                "Capture Btn",
                _showCaptureButton,
                (v) => setState(() => _showCaptureButton = v),
              ),
              _buildSwitch("Devil Mode 😈", _showCustomOverlay, (v) {
                setState(() {
                  _showCustomOverlay = v;
                  // Auto-hide the default frame if Custom UI is on for better visibility
                  if (v) {
                    _showFrame = false;
                  } else {
                    _showFrame = true;
                  }
                });
              }),
            ],
          ),
          const Divider(color: Colors.white12, height: 30),

          // Frame Styles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStyleIcon(FaceFrameStyle.cornerBracket, Icons.crop_free),
              _buildStyleIcon(
                FaceFrameStyle.roundedBox,
                Icons.check_box_outline_blank,
              ),
              _buildStyleIcon(FaceFrameStyle.dottedLine, Icons.more_horiz),
            ],
          ),
          const SizedBox(height: 20),

          // Colors
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildColorCircle(Colors.cyanAccent),
              const SizedBox(width: 15),
              _buildColorCircle(Colors.greenAccent),
              const SizedBox(width: 15),
              _buildColorCircle(Colors.redAccent),
              const SizedBox(width: 15),
              _buildColorCircle(Colors.purpleAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool val, Function(bool) onChanged) {
    return Expanded(
      child: Column(
        children: [
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: val,
              onChanged: onChanged,
              activeColor: _activeColor,
              trackColor: WidgetStateProperty.all(Colors.grey.shade800),
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStyleIcon(FaceFrameStyle style, IconData icon) {
    final isSelected = _frameStyle == style;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? _activeColor : Colors.grey,
        size: 28,
      ),
      onPressed: () => setState(() => _frameStyle = style),
    );
  }

  Widget _buildColorCircle(Color color) {
    final isSelected = _activeColor == color;
    return GestureDetector(
      onTap: () => setState(() => _activeColor = color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 34 : 26,
        height: isSelected ? 34 : 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow:
              isSelected
                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)]
                  : null,
        ),
      ),
    );
  }

  // --- Capture Result Popup ---
  void _showResultDialog(FaceCaptureResult result) async {
    final file = File(result.image.path);
    final bytes = await file.readAsBytes();
    final ui.Image decodedImage = await decodeImageFromList(bytes);

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display the Image
                Container(
                  constraints: const BoxConstraints(maxHeight: 500),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black,
                    border: Border.all(color: Colors.white24),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: AspectRatio(
                    aspectRatio: decodedImage.width / decodedImage.height,
                    child: CustomPaint(
                      // We use the ResultPainter to draw the photo AND the privacy blur
                      painter: ResultPainter(
                        image: decodedImage,
                        faceRect: result.faceRect,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Close Preview",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

// -----------------------------------------------------------------------------
// PAINTER 1: Result Painter (Draws Captured Photo + Privacy Blur)
// -----------------------------------------------------------------------------
class ResultPainter extends CustomPainter {
  final ui.Image image;
  final Rect? faceRect;

  ResultPainter({required this.image, required this.faceRect});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the full high-res image fitted to the dialog
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());

    // 2. If a face was found, apply effects
    if (faceRect != null) {
      // Calculate Scale Factor (Full Image -> Dialog Size)
      final double scaleX = size.width / image.width;
      final double scaleY = size.height / image.height;

      // Scale the face coordinates
      final Rect scaledRect = Rect.fromLTRB(
        faceRect!.left * scaleX,
        faceRect!.top * scaleY,
        faceRect!.right * scaleX,
        faceRect!.bottom * scaleY,
      );

      // A. Draw Privacy Blur
      final Paint blurPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.5)
            ..maskFilter = const MaskFilter.blur(
              BlurStyle.normal,
              20,
            ); // Stronger blur
      canvas.drawRect(scaledRect, blurPaint);

      // B. Draw Tech Border (Visual confirmation)
      final Paint borderPaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..color = Colors.greenAccent
            ..strokeWidth = 3;

      // Draw corners only (simplified for tech look) or full rect
      canvas.drawRect(scaledRect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// PAINTER 2: Emoji Face Painter (The "Devil" Overlay)
// -----------------------------------------------------------------------------
class EmojiFacePainter extends CustomPainter {
  final List<Rect> faces;

  EmojiFacePainter({required this.faces});

  @override
  void paint(Canvas canvas, Size size) {
    for (final face in faces) {
      // 1. Define the Emoji
      const icon = "😈"; // The Devil Emoji

      // 2. Prepare Text Painter
      // Scale font size based on the width of the detected face for a perfect fit
      final textStyle = TextStyle(
        fontSize: face.width * 1.2, // Make it slightly larger than the face box
      );

      final textSpan = TextSpan(text: icon, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();

      // 3. Calculate Center Position
      // Center the emoji on the face rect
      final offset = Offset(
        face.center.dx - (textPainter.width / 2),
        face.center.dy - (textPainter.height / 2),
      );

      // 4. Draw the Emoji
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(EmojiFacePainter oldDelegate) => true;
}

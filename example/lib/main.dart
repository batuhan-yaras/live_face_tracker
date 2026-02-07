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
  bool _showFrame = true;
  bool _showCaptureButton = true;
  bool _showCustomOverlay = false;
  bool _isPanelVisible = true;
  bool _isLoading = false;

  // --- 3. Data State ---
  // The data stream is already smoothed by the package.
  List<Rect> _detectedFaces = [];

  final FaceTrackerController _controller = FaceTrackerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ------------------------------------------------
          // LAYER 1: The FaceTrackerView
          // ------------------------------------------------
          FaceTrackerView(
            controller: _controller,
            frameStyle: _frameStyle,
            activeColor: _activeColor,
            showFrame: _showFrame,
            showCaptureButton: _showCaptureButton,

            // API: Real-time Face Coordinates Stream
            onFacesDetected: (faces) {
              if (_showCustomOverlay) {
                if (mounted) {
                  setState(() {
                    _detectedFaces = faces;
                  });
                }
              }
            },

            // API: Photo Capture Result
            onPhotoCaptured: (result) async {
              setState(() => _isLoading = true);
              await Future.delayed(const Duration(milliseconds: 100));
              if (mounted) {
                setState(() => _isLoading = false);
                _showResultDialog(result);
              }
            },
          ),

          // ------------------------------------------------
          // LAYER 2: Custom Developer Overlay
          // ------------------------------------------------
          if (_showCustomOverlay)
            IgnorePointer(
              // Using CustomPaint with Size.infinite ensures it covers the screen
              // even if no faces are detected initially.
              child: CustomPaint(
                painter: EmojiFacePainter(faces: _detectedFaces),
                size: Size.infinite,
              ),
            ),

          // ------------------------------------------------
          // LAYER 3: Top Controls
          // ------------------------------------------------
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassButton(
                  icon: Icons.flip_camera_ios,
                  onTap: () async {
                    setState(() {
                      _isLoading = true;
                      _detectedFaces = [];
                    });

                    await _controller.switchCamera();

                    if (mounted) setState(() => _isLoading = false);
                  },
                ),
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
          // LAYER 4: Control Panel
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
          // LAYER 5: Global Loading
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

  // --- UI Helpers ---

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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "🧪 Feature Test Lab",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
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
              _buildSwitch(
                "Devil Mode 😈",
                _showCustomOverlay,
                (v) => setState(() {
                  _showCustomOverlay = v;
                  _showFrame = !v;
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStyleIcon(FaceFrameStyle style, IconData icon) {
    return IconButton(
      icon: Icon(
        icon,
        color: _frameStyle == style ? _activeColor : Colors.grey,
        size: 28,
      ),
      onPressed: () => setState(() => _frameStyle = style),
    );
  }

  Widget _buildColorCircle(Color color) {
    return GestureDetector(
      onTap: () => setState(() => _activeColor = color),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border:
              _activeColor == color
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
        ),
      ),
    );
  }

  void _showResultDialog(FaceCaptureResult result) async {
    final file = File(result.image.path);
    final bytes = await file.readAsBytes();
    final ui.Image decodedImage = await decodeImageFromList(bytes);
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 500),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: AspectRatio(
                    aspectRatio: decodedImage.width / decodedImage.height,
                    child: CustomPaint(
                      painter: ResultPainter(
                        image: decodedImage,
                        faceRect: result.faceRect,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
    );
  }
}

class ResultPainter extends CustomPainter {
  final ui.Image image;
  final Rect? faceRect;
  ResultPainter({required this.image, required this.faceRect});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );
    if (faceRect != null) {
      final scaleX = size.width / image.width;
      final scaleY = size.height / image.height;
      final rect = Rect.fromLTRB(
        faceRect!.left * scaleX,
        faceRect!.top * scaleY,
        faceRect!.right * scaleX,
        faceRect!.bottom * scaleY,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.black54
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.greenAccent
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EmojiFacePainter extends CustomPainter {
  final List<Rect> faces;
  EmojiFacePainter({required this.faces});
  @override
  void paint(Canvas canvas, Size size) {
    for (final face in faces) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: "😈",
          style: TextStyle(fontSize: face.width * 1.2),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          face.center.dx - textPainter.width / 2,
          face.center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(EmojiFacePainter oldDelegate) => true;
}

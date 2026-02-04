import 'package:flutter/material.dart';
import 'package:live_face_tracker/live_face_tracker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Default style and color
  FaceFrameStyle _currentStyle = FaceFrameStyle.cornerBracket;
  Color _currentColor = Colors.cyanAccent;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            // 1. The Library Widget (Covers the full screen)
            FaceTrackerView(
              frameStyle: _currentStyle,
              activeColor: _currentColor,
            ),

            // 2. Control Panel (Overlay layer)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Face Tracker Control",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.white24),

                    // Style Selector Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStyleButton(
                          FaceFrameStyle.cornerBracket,
                          Icons.crop_free,
                          "Bracket",
                        ),
                        _buildStyleButton(
                          FaceFrameStyle.roundedBox,
                          Icons.check_box_outline_blank,
                          "Box",
                        ),
                        _buildStyleButton(
                          FaceFrameStyle.dottedLine,
                          Icons.more_horiz,
                          "Dotted",
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Color Selector (Simple toggle logic)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.color_lens),
                      label: const Text("Change Color"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentColor,
                        foregroundColor:
                            _currentColor == Colors.white
                                ? Colors.black
                                : Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          // Cycle through colors
                          if (_currentColor == Colors.cyanAccent) {
                            _currentColor = Colors.redAccent;
                          } else if (_currentColor == Colors.redAccent) {
                            _currentColor = Colors.greenAccent;
                          } else if (_currentColor == Colors.greenAccent) {
                            _currentColor = Colors.white;
                          } else {
                            _currentColor = Colors.cyanAccent;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for style buttons
  Widget _buildStyleButton(FaceFrameStyle style, IconData icon, String label) {
    final bool isSelected = _currentStyle == style;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentStyle = style;
        });
      },
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? _currentColor : Colors.white54,
            size: 30,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? _currentColor : Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

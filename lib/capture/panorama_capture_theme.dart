import 'package:flutter/material.dart';

/// Controls the visual style of [PanoramaCaptureScreen].
///
/// All fields are optional — defaults produce a dark, camera-style UI.
class PanoramaCaptureTheme {
  /// Background colour of the capture screen.
  final Color backgroundColor;

  /// Colour used for the progress arc and active UI elements.
  final Color accentColor;

  /// Colour of body text and secondary labels.
  final Color textColor;

  /// Colour of the primary action button (e.g. "Open camera").
  final Color buttonColor;

  /// Text colour on the primary action button.
  final Color buttonTextColor;

  const PanoramaCaptureTheme({
    this.backgroundColor = Colors.black,
    this.accentColor = const Color(0xFF00C4A0), // teal
    this.textColor = Colors.white70,
    this.buttonColor = const Color(0xFF00C4A0),
    this.buttonTextColor = Colors.black,
  });

  /// A light theme suitable for apps with a white background.
  static const light = PanoramaCaptureTheme(
    backgroundColor: Color(0xFFF5F5F5),
    accentColor: Color(0xFF0F6E56),
    textColor: Color(0xFF444441),
    buttonColor: Color(0xFF0F6E56),
    buttonTextColor: Colors.white,
  );
}

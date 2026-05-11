import 'package:flutter/widgets.dart';

/// Represents an interactive overlay pinned to a specific point in the panorama.
///
/// Longitude ranges from -180 (left edge) to 180 (right edge).
/// Latitude ranges from -90 (bottom) to 90 (top).
class PanoramaHotspot {
  /// Horizontal position in degrees (-180 … 180).
  final double longitude;

  /// Vertical position in degrees (-90 … 90).
  final double latitude;

  /// The widget rendered at this hotspot location.
  final Widget widget;

  /// Called when the user taps this hotspot.
  final VoidCallback? onTap;

  /// Optional label for accessibility / tooltips.
  final String? label;

  const PanoramaHotspot({
    required this.longitude,
    required this.latitude,
    required this.widget,
    this.onTap,
    this.label,
  });
}

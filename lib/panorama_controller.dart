import 'package:flutter/foundation.dart';

/// Exposes programmatic control over a [CustomPanoramaViewer].
///
/// Pass an instance to [CustomPanoramaViewer.controller], then call
/// [animateTo] or [setZoom] from buttons or other widgets.
class PanoramaController extends ChangeNotifier {
  double _longitude = 0;
  double _latitude = 0;
  double _zoom = 1.0;
  bool _autoRotate = false;

  double get longitude => _longitude;
  double get latitude => _latitude;
  double get zoom => _zoom;
  bool get autoRotate => _autoRotate;

  /// Smoothly move the camera to the given [longitude] / [latitude].
  void animateTo({required double longitude, required double latitude}) {
    _longitude = longitude;
    _latitude = latitude;
    notifyListeners();
  }

  /// Set the zoom level. Typical range is 1.0 (wide) to 5.0 (close).
  void setZoom(double zoom) {
    _zoom = zoom.clamp(0.5, 10.0);
    notifyListeners();
  }

  /// Toggle auto-rotation on or off.
  void setAutoRotate(bool value) {
    _autoRotate = value;
    notifyListeners();
  }

  /// Reset the view to its initial state.
  void reset() {
    _longitude = 0;
    _latitude = 0;
    _zoom = 1.0;
    _autoRotate = false;
    notifyListeners();
  }
}

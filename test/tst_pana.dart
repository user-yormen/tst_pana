/// A Flutter package for capturing and viewing interactive 360° panoramic images.
///
/// ## Viewer (unchanged)
/// ```dart
/// CustomPanoramaViewer(child: Image.file(media.file))
/// ```
///
/// ## Capture — gallery import
/// ```dart
/// final result = await PanoramaPicker.fromGallery();
/// ```
///
/// ## Capture — guided in-app flow
/// ```dart
/// final result = await PanoramaPicker.fromGuidedCapture(context);
/// ```
library tst_pana;

// ── Viewer (existing, unchanged) ──────────────────────────────────────────
export 'package:tst_pana/custom_panorama_viewer.dart';
export 'package:tst_pana/panorama_controller.dart';
export 'package:tst_pana/panorama_error_widget.dart';
export 'package:tst_pana/panorama_hotspot.dart';
export 'package:tst_pana/panorama_loader.dart';

// ── Capture (new) ─────────────────────────────────────────────────────────
export 'package:tst_pana/capture/panorama_media.dart';
export 'package:tst_pana/capture/panorama_picker.dart';
export 'package:tst_pana/capture/panorama_capture_screen.dart'
    show PanoramaCaptureScreen;
export 'package:tst_pana/capture/panorama_capture_theme.dart';

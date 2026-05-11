import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tst_pana/capture/panorama_capture_theme.dart';
import 'package:tst_pana/capture/panorama_media.dart';

import '../../panorama_error_widget.dart';
import 'panorama_capture_screen.dart';

/// The result of a pick attempt.
sealed class PanoramaPickResult {}

/// The user successfully selected or captured a panorama.
final class PanoramaPickSuccess extends PanoramaPickResult {
  final PanoramaMedia media;
  PanoramaPickSuccess(this.media);
}

/// The user cancelled without selecting anything.
final class PanoramaPickCancelled extends PanoramaPickResult {}

/// Something went wrong (permission denied, decode error, etc.).
final class PanoramaPickError extends PanoramaPickResult {
  final String message;
  PanoramaPickError(this.message);
}

/// Provides the two panorama acquisition paths:
///
/// - [fromGallery]  — opens the system image picker and returns the chosen
///   image. Works with panoramas already shot by the device's native camera
///   app (iOS Camera Panorama, Google Camera, etc.).
///
/// - [fromGuidedCapture] — pushes [PanoramaCaptureScreen] onto the navigator.
///   The user captures the panorama inside the app; the screen routes them to
///   the native camera for the actual shot, then picks the result from the
///   gallery. Returns the media when the screen pops.
///
/// Both paths return a [PanoramaPickResult] — match on [PanoramaPickSuccess],
/// [PanoramaPickCancelled], and [PanoramaPickError].
///
/// ```dart
/// final result = await PanoramaPicker.fromGallery();
/// switch (result) {
///   case PanoramaPickSuccess(:final media):
///     // hand media.file to CustomPanoramaViewer
///   case PanoramaPickCancelled():
///     break;
///   case PanoramaPickError(:final message):
///     // show error
/// }
/// ```
abstract final class PanoramaPicker {
  PanoramaPicker._();

  static final _picker = ImagePicker();

  // ── Gallery path ───────────────────────────────────────────────────────────

  /// Opens the system image picker. The user should select a pre-stitched
  /// equirectangular panorama (typically taken in the device's panorama mode).
  ///
  /// Optionally pass [warnIfNotPanorama] (default true) to surface a warning
  /// when the selected image's aspect ratio is outside the 1.8–2.2 range.
  /// The image is still returned — the caller decides whether to reject it.
  static Future<PanoramaPickResult> fromGallery({
    bool warnIfNotPanorama = true,
  }) async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        // No compression — we need the full resolution for the viewer.
        imageQuality: 100,
      );

      if (xFile == null) return PanoramaPickCancelled();

      final file = File(xFile.path);
      final decoded = await _decodeImageSize(file);

      return PanoramaPickSuccess(
        PanoramaMedia(
          file: file,
          source: PanoramaSource.gallery,
          width: decoded.$1,
          height: decoded.$2,
        ),
      );
    } catch (e) {
      return PanoramaPickError('Gallery picker failed: $e');
    }
  }

  // ── Guided-capture path ────────────────────────────────────────────────────

  /// Pushes [PanoramaCaptureScreen] onto the given [navigator] (or the root
  /// navigator if [useRootNavigator] is true).
  ///
  /// [PanoramaCaptureScreen] guides the user through pointing their phone's
  /// native camera at the desired scene, launching the native panorama mode,
  /// and then selecting the resulting image from the gallery.
  ///
  /// Returns [PanoramaPickCancelled] if the user dismisses the capture screen
  /// without completing the flow.
  static Future<PanoramaPickResult> fromGuidedCapture(
    BuildContext context, {
    bool useRootNavigator = false,
    PanoramaCaptureTheme? theme,
  }) async {
    final result = await Navigator.of(
      context,
      rootNavigator: useRootNavigator,
    ).push<PanoramaMedia>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PanoramaCaptureScreen(theme: theme),
      ),
    );

    if (result == null) return PanoramaPickCancelled();
    return PanoramaPickSuccess(result);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Decodes just enough of the image to read width × height without loading
  /// the full pixel buffer into memory.
  static Future<(int?, int?)> _decodeImageSize(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await instantiateImageCodecFromBuffer(
        await ImmutableBuffer.fromUint8List(bytes),
      );
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      frame.image.dispose();
      codec.dispose();
      return (w, h);
    } catch (_) {
      return (null, null);
    }
  }
}

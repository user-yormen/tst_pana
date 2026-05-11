import 'dart:io';

/// Where the panoramic image came from.
enum PanoramaSource {
  /// Picked from the device photo library (pre-stitched by the native camera app).
  gallery,

  /// Captured in-app via the guided sweep UI.
  /// Note: stitching is delegated to the native camera app; the plugin picks
  /// the resulting panorama from the gallery after capture.
  guided,
}

/// The result returned by [PanoramaPicker] once the user has selected or
/// captured a panoramic image.
///
/// Pass [file] directly to [CustomPanoramaViewer]:
/// ```dart
/// CustomPanoramaViewer(child: Image.file(media.file))
/// ```
class PanoramaMedia {
  /// The local image file on disk.
  final File file;

  /// How this media was obtained.
  final PanoramaSource source;

  /// Width in pixels (null if not yet decoded).
  final int? width;

  /// Height in pixels (null if not yet decoded).
  final int? height;

  /// Approximate aspect ratio (width / height). A valid equirectangular
  /// panorama is close to 2.0.
  double? get aspectRatio =>
      (width != null && height != null && height! > 0)
          ? width! / height!
          : null;

  /// Returns true when the image looks like a valid equirectangular panorama
  /// (aspect ratio between 1.8 and 2.2).
  bool get isValidPanorama {
    final ar = aspectRatio;
    return ar != null && ar >= 1.8 && ar <= 2.2;
  }

  const PanoramaMedia({
    required this.file,
    required this.source,
    this.width,
    this.height,
  });

  @override
  String toString() =>
      'PanoramaMedia(source: $source, '
      'size: ${width}x$height, '
      'ar: ${aspectRatio?.toStringAsFixed(2)})';
}

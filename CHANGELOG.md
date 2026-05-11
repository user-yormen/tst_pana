## 1.0.0

* Initial release.
* `CustomPanoramaViewer` widget wrapping `panorama_viewer ^2.0.7`.
* `PanoramaController` for programmatic camera and zoom control.
* `PanoramaHotspot` model for interactive overlays.
* Gyroscope / absolute-orientation sensor integration via `dchs_motion_sensors`.
* Built-in `PanoramaLoader` and `PanoramaErrorWidget` with retry support.
* Image pre-caching via `precacheImage`.
* Auto-rotate support controlled through `PanoramaController.setAutoRotate`.
* Five example demos: network image, hotspots, programmatic control,
  auto-rotate, side-by-side.

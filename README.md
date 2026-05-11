# tst_pana 

A customizable Flutter package for displaying interactive 360° panoramic images,
with gesture controls, gyroscope / orientation sensor support, and interactive
hotspots — all with a clean, type-safe API.

---

## Features

| Feature | Details |
|---|---|
| **Gallery import** | Pick a pre-stitched panorama from the device photo library |
| **Guided capture** | Step-by-step UI that walks users through shooting a panorama |
| **Equirectangular viewer** | Asset, network, or file image sources |
| **Gestures** | Swipe to pan, pinch to zoom |
| **Sensor look-around** | Gyroscope / absolute orientation via `dchs_motion_sensors` |
| **Hotspots** | Pin any widget to a lat/lon with tap callbacks |
| **Programmatic control** | `PanoramaController` for `animateTo`, `setZoom`, `reset` |
| **Auto-rotate** | Configurable `animSpeed` driven by the controller |
| **Aspect-ratio validation** | Warns when a picked image isn't a valid panorama |
| **Themeable capture UI** | Dark default; `PanoramaCaptureTheme.light` built in |
| **Loading / error states** | Built-in widgets; fully replaceable |


### Platform support

| Platform | Viewer | Capture |
|---|---|---|
| Android | ✅ | ✅ |
| iOS | ✅ | ✅ |
| Web | ⚠️ Set `sensorEnabled: false` | ❌ Camera / gallery unavailable |
| macOS / Linux / Windows | ⚠️ Same caveat | ❌ |

---
---

## Installation

Add either to your `pubspec.yaml`:

```yaml
dependencies:
  tst_pana: ^1.0.0
```

or

```yaml
dependencies:
  tst_pana:
    git:
      url: https://github.com/user-yormen/tst_pana.git
```

Then run:

```sh
flutter pub get
```

### Android permissions

In `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Gallery access (Android 13+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- Orientation sensor -->
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
```

### iOS permissions

In `ios/Runner/Info.plist`:

```xml
<!-- Gallery access -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Select a panorama to view in 360°.</string>

<!-- Orientation sensor -->
<key>NSMotionUsageDescription</key>
<string>Used for gyroscope-based panorama look-around.</string>
```

---

## Capture

### How it works

The plugin does not do stitching itself. Instead it relies on the **device's native camera app**, which already produces ready-to-use equirectangular JPEGs via its built-in panorama mode (iOS Camera, Google Camera, etc.). The plugin provides two ways to get that image into your app:

| Path | When to use |
|---|---|
| `PanoramaPicker.fromGallery()` | User already has a panorama in their library |
| `PanoramaPicker.fromGuidedCapture(context)` | User needs to shoot one now — the plugin walks them through it |

Both paths return a `PanoramaPickResult` sealed class. Pass the resulting `media.file` directly to `CustomPanoramaViewer`.

---

### Gallery import

```dart
import 'package:tst_pana/tst_pana.dart';

Future<void> pickAndView() async {
  final result = await PanoramaPicker.fromGallery();

  switch (result) {
    case PanoramaPickSuccess(:final media):
      if (!media.isValidPanorama) {
        // Aspect ratio is outside 1.8–2.2 — warn the user but still proceed.
      }
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CustomPanoramaViewer(
          child: Image.file(media.file),
        ),
      ));

    case PanoramaPickCancelled():
      break; // User dismissed the picker

    case PanoramaPickError(:final message):
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  }
}
```

---

### Guided capture

Pushes a full-screen step-by-step UI that:

1. Explains how to shoot a panorama on the device's native camera app.
2. Provides a button to open the camera.
3. On return, opens the gallery so the user selects the result.
4. Validates the aspect ratio and warns if the image doesn't look like a panorama.

```dart
Future<void> guidedCaptureAndView() async {
  final result = await PanoramaPicker.fromGuidedCapture(context);

  switch (result) {
    case PanoramaPickSuccess(:final media):
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CustomPanoramaViewer(
          child: Image.file(media.file),
        ),
      ));

    case PanoramaPickCancelled():
      break;

    case PanoramaPickError(:final message):
      debugPrint('Capture error: $message');
  }
}
```

#### Theming the capture screen

```dart
PanoramaPicker.fromGuidedCapture(
  context,
  theme: PanoramaCaptureTheme.light, // built-in light theme
);

// Or fully custom:
PanoramaPicker.fromGuidedCapture(
  context,
  theme: const PanoramaCaptureTheme(
    backgroundColor: Color(0xFF1A1A2E),
    accentColor: Color(0xFF4ECCA3),
    textColor: Colors.white70,
    buttonColor: Color(0xFF4ECCA3),
    buttonTextColor: Colors.black,
  ),
);
```

---

### `PanoramaMedia`

Returned inside `PanoramaPickSuccess`. Contains everything needed to display and validate the image.

| Property | Type | Description |
|---|---|---|
| `file` | `File` | Local image file — pass to `Image.file()` |
| `source` | `PanoramaSource` | `.gallery` or `.guided` |
| `width` | `int?` | Image width in pixels |
| `height` | `int?` | Image height in pixels |
| `aspectRatio` | `double?` | `width / height`; null if dimensions unavailable |
| `isValidPanorama` | `bool` | `true` when aspect ratio is 1.8 – 2.2 |

---

### `PanoramaCaptureTheme`

| Property | Type | Default |
|---|---|---|
| `backgroundColor` | `Color` | `Colors.black` |
| `accentColor` | `Color` | `Color(0xFF00C4A0)` |
| `textColor` | `Color` | `Colors.white70` |
| `buttonColor` | `Color` | `Color(0xFF00C4A0)` |
| `buttonTextColor` | `Color` | `Colors.black` |

Built-in presets: `PanoramaCaptureTheme()` (dark), `PanoramaCaptureTheme.light`.

---

## Viewer

### Basic usage

```dart
import 'package:tst_pana/tst_pana.dart';

// From a captured/picked file
CustomPanoramaViewer(
  child: Image.file(media.file),
)

// From an asset
CustomPanoramaViewer(
  child: Image.asset('assets/panorama.jpg'),
)

// From a URL
CustomPanoramaViewer(
  child: Image.network('https://example.com/panorama.jpg'),
  sensitivity: 2.5,
  onViewChanged: (lon, lat, tilt) => debugPrint('$lon, $lat'),
)
```

### Hotspots

```dart
CustomPanoramaViewer(
  child: Image.file(media.file),
  hotspots: [
    PanoramaHotspot(
      longitude: 45,
      latitude: 10,
      label: 'Info point',
      widget: const Icon(Icons.info, color: Colors.white, size: 32),
      onTap: () => showDialog(context: context, builder: (_) => /* ... */),
    ),
  ],
)
```

### Programmatic control

```dart
final _ctrl = PanoramaController();

// Dispose alongside your State:
// _ctrl.dispose();

CustomPanoramaViewer(
  controller: _ctrl,
  child: Image.file(media.file),
  sensorEnabled: false,
)

// Move the camera:
_ctrl.animateTo(longitude: 90, latitude: 0);
_ctrl.setZoom(2.0);
_ctrl.setAutoRotate(true);
_ctrl.reset();
```

### Auto-rotate

```dart
CustomPanoramaViewer(
  controller: _ctrl..setAutoRotate(true),
  animSpeed: 1.5, // degrees per second
  child: Image.file(media.file),
)
```

---

## Complete end-to-end example

```dart
import 'package:flutter/material.dart';
import 'package:tst_pana/tst_pana.dart';

class PanoramaPage extends StatelessWidget {
  const PanoramaPage({super.key});

  Future<void> _capture(BuildContext context) async {
    final result = await PanoramaPicker.fromGuidedCapture(context);
    if (!context.mounted) return;

    switch (result) {
      case PanoramaPickSuccess(:final media):
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('360° View')),
              body: CustomPanoramaViewer(
                child: Image.file(media.file),
                hotspots: const [],
              ),
            ),
          ),
        );
      case PanoramaPickCancelled():
        break;
      case PanoramaPickError(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _import(BuildContext context) async {
    final result = await PanoramaPicker.fromGallery();
    if (!context.mounted) return;

    switch (result) {
      case PanoramaPickSuccess(:final media):
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomPanoramaViewer(
              child: Image.file(media.file),
            ),
          ),
        );
      case PanoramaPickCancelled():
        break;
      case PanoramaPickError(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('tst_pana demo')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () => _capture(context),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Capture panorama'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _import(context),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Import from gallery'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## API reference

### `PanoramaPicker`

| Method | Returns | Description |
|---|---|---|
| `fromGallery({warnIfNotPanorama})` | `Future<PanoramaPickResult>` | Open system image picker |
| `fromGuidedCapture(context, {theme, useRootNavigator})` | `Future<PanoramaPickResult>` | Push guided capture screen |

### `PanoramaPickResult` (sealed)

| Subtype | Fields | Meaning |
|---|---|---|
| `PanoramaPickSuccess` | `media` | Image selected/captured successfully |
| `PanoramaPickCancelled` | — | User dismissed without selecting |
| `PanoramaPickError` | `message` | Permission denied, decode error, etc. |

### `CustomPanoramaViewer`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `child` | `Image` | **required** | Equirectangular panorama image |
| `controller` | `PanoramaController?` | `null` | Programmatic control |
| `hotspots` | `List<PanoramaHotspot>` | `[]` | Interactive overlays |
| `sensitivity` | `double` | `1.0` | Touch/drag multiplier |
| `initialLongitude` | `double` | `0.0` | Starting horizontal angle |
| `initialLatitude` | `double` | `0.0` | Starting vertical angle |
| `initialZoom` | `double` | `1.0` | Starting zoom level |
| `animSpeed` | `double` | `0.0` | Auto-rotate speed (°/s) |
| `zoomEnabled` | `bool` | `true` | Enable pinch-to-zoom |
| `sensorEnabled` | `bool` | `true` | Enable gyroscope look-around |
| `sensorSensitivity` | `double` | `1.0` | Gyroscope multiplier |
| `onViewChanged` | `ViewChangedCallback?` | `null` | Called on every camera update |
| `onTap` | `(double, double) → void?` | `null` | Tap position callback |
| `loadingWidget` | `Widget?` | `PanoramaLoader` | Custom loading state |
| `errorWidget` | `Widget?` | `PanoramaErrorWidget` | Custom error state |

### `PanoramaController`

| Method | Description |
|---|---|
| `animateTo({longitude, latitude})` | Move camera to coordinates |
| `setZoom(double)` | Set zoom level (clamped 0.5 – 10.0) |
| `setAutoRotate(bool)` | Toggle auto-rotation |
| `reset()` | Restore all values to defaults |

### `PanoramaHotspot`

| Property | Type | Description |
|---|---|---|
| `longitude` | `double` | Horizontal position (–180 … 180) |
| `latitude` | `double` | Vertical position (–90 … 90) |
| `widget` | `Widget` | Widget rendered at this point |
| `onTap` | `VoidCallback?` | Tap handler |
| `label` | `String?` | Accessibility label |

---

## Image guidelines

- Format: JPEG or PNG
- Aspect ratio: **2:1** (e.g. 4096 × 2048 px) — `isValidPanorama` checks 1.8–2.2
- Projection: equirectangular
- Free test images: [Polyhaven](https://polyhaven.com/hdris)

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -am 'Add feature'`
4. Push: `git push origin feature/my-feature`
5. Open a pull request

---

## License

Apache-2.0 — see [LICENSE](LICENSE).

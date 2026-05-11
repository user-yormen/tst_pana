# panorama_viewer_custom

A customizable Flutter package for displaying interactive 360° panoramic images,
with gesture controls, gyroscope / orientation sensor support, and interactive
hotspots — all with a clean, type-safe API.

---

## Features

| Feature | Details |
|---|---|
| **Equirectangular images** | Asset, network, or file sources |
| **Gestures** | Swipe to pan, pinch to zoom |
| **Sensor look-around** | Gyroscope / absolute orientation via `dchs_motion_sensors` |
| **Hotspots** | Pin any widget to a lat/lon with tap callbacks |
| **Programmatic control** | `PanoramaController` for `animateTo`, `setZoom`, `reset` |
| **Auto-rotate** | Configurable `animSpeed` driven by the controller |
| **Loading / error states** | Built-in widgets; fully replaceable |
| **Image pre-caching** | Automatic via `precacheImage` |
| **Side-by-side** | Multiple viewers in one layout |

### Platform Support

| Platform | Supported |
|---|---|
| Android | ✅ |
| iOS | ✅ |
| Web | ⚠️ Sensors unavailable — set `sensorEnabled: false` |
| macOS / Linux / Windows | ⚠️ Same caveat |

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  panorama_viewer_custom: ^1.0.0
```

Then run:

```sh
flutter pub get
```

### Android permissions (orientation sensor)

In `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
```

### iOS permissions

In `ios/Runner/Info.plist`:

```xml
<key>NSMotionUsageDescription</key>
<string>Used for gyroscope-based panorama look-around.</string>
```

---

## Basic Usage

```dart
import 'package:panorama_viewer_custom/panorama_viewer_custom.dart';

// Asset image
CustomPanoramaViewer(
  child: Image.asset('assets/panorama.jpg'),
)

// Network image  
CustomPanoramaViewer(
  child: Image.network('https://example.com/panorama.jpg'),
  sensitivity: 2.5,
  onViewChanged: (lon, lat, tilt) => debugPrint('$lon, $lat'),
)
```

---

## Hotspots

```dart
CustomPanoramaViewer(
  child: Image.asset('assets/panorama.jpg'),
  hotspots: [
    PanoramaHotspot(
      longitude: 45,
      latitude: 10,
      label: 'Info point',
      widget: const Icon(Icons.info, color: Colors.white, size: 32),
      onTap: () => showDialog(/* ... */),
    ),
  ],
)
```

---

## Programmatic Control

```dart
final _ctrl = PanoramaController();

// In your State.dispose():
// _ctrl.dispose();

CustomPanoramaViewer(
  controller: _ctrl,
  child: Image.asset('assets/panorama.jpg'),
  sensorEnabled: false,    // Disable sensor so sliders work clearly
)

// Elsewhere:
_ctrl.animateTo(longitude: 90, latitude: 0);
_ctrl.setZoom(2.0);
_ctrl.setAutoRotate(true);
_ctrl.reset();
```

---

## Auto-Rotate

```dart
CustomPanoramaViewer(
  controller: _ctrl..setAutoRotate(true),
  animSpeed: 1.5,          // Degrees per second
  child: Image.asset('assets/panorama.jpg'),
)
```

---

## API Reference

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
| `sensorEnabled` | `bool` | `true` | Enable gyroscope |
| `sensorSensitivity` | `double` | `1.0` | Gyroscope multiplier |
| `onViewChanged` | `ViewChangedCallback?` | `null` | Camera update callback |
| `onTap` | `(double, double) → void?` | `null` | Tap position callback |
| `loadingWidget` | `Widget?` | `PanoramaLoader` | Custom loading state |
| `errorWidget` | `Widget?` | `PanoramaErrorWidget` | Custom error state |

### `PanoramaController`

| Method | Description |
|---|---|
| `animateTo({longitude, latitude})` | Move camera to given coordinates |
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

## Image Guidelines

- Format: JPEG or PNG
- Aspect ratio: **2:1** (e.g. 4096 × 2048 px)
- Projection: **Equirectangular**
- Free test images: [Polyhaven](https://polyhaven.com/hdris)

---

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -am 'Add feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

---

## License

Apache-2.0 — see [LICENSE](LICENSE).

import 'dart:async';
import 'dart:math' show pi;

import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart' as pv;

import 'panorama_controller.dart';
import 'panorama_error_widget.dart';
import 'panorama_hotspot.dart';
import 'panorama_loader.dart';

/// Called whenever the user pans or zooms the panorama.
///
/// [longitude] and [latitude] are in degrees; [tilt] is the camera tilt.
typedef ViewChangedCallback = void Function(
    double longitude, double latitude, double tilt);

/// A customizable, full-featured 360° panorama viewer.
///
/// ## Basic usage
/// ```dart
/// CustomPanoramaViewer(
///   child: Image.asset('assets/panorama.jpg'),
///   sensitivity: 2.5,
///   onViewChanged: (lon, lat, tilt) => debugPrint('$lon $lat $tilt'),
/// )
/// ```
///
/// ## With hotspots and programmatic control
/// ```dart
/// final _ctrl = PanoramaController();
///
/// CustomPanoramaViewer(
///   controller: _ctrl,
///   child: Image.network('https://example.com/pano.jpg'),
///   hotspots: [
///     PanoramaHotspot(
///       longitude: 45,
///       latitude: 10,
///       widget: const Icon(Icons.location_pin, color: Colors.red, size: 32),
///       onTap: () => debugPrint('Hotspot tapped!'),
///     ),
///   ],
/// )
/// ```
class CustomPanoramaViewer extends StatefulWidget {
  // ── Required ──────────────────────────────────────────────────────────────

  /// The equirectangular panoramic image.
  ///
  /// Use [Image.asset], [Image.network], or [Image.file].
  /// The image should have an aspect ratio of approximately 2:1.
  final Image child;

  // ── Optional configuration ────────────────────────────────────────────────

  /// Programmatic controller. If omitted, an internal one is used.
  final PanoramaController? controller;

  /// List of interactive overlays pinned to specific lat/lon coordinates.
  final List<PanoramaHotspot> hotspots;

  /// Touch / drag sensitivity multiplier. Default is **1.0**.
  final double sensitivity;

  /// Initial longitude offset in degrees (horizontal start position).
  final double initialLongitude;

  /// Initial latitude offset in degrees (vertical start position).
  final double initialLatitude;

  /// Initial field-of-view zoom. 1.0 = normal; higher = zoomed in.
  final double initialZoom;

  /// Degrees per second for automatic rotation when idle.
  /// Set to **0** to disable. Default is **0**.
  final double animSpeed;

  /// Whether the package's built-in pinch-to-zoom is enabled.
  final bool zoomEnabled;

  /// Whether to use the device gyroscope / orientation sensor for look-around.
  final bool sensorEnabled;

  /// Sensitivity multiplier for gyroscope input. Default is **1.0**.
  final double sensorSensitivity;

  // ── Callbacks ─────────────────────────────────────────────────────────────

  /// Fired whenever the camera orientation changes.
  final ViewChangedCallback? onViewChanged;

  /// Fired when the user taps a point in the panorama (not a hotspot).
  ///
  /// Receives the tapped [longitude] and [latitude] in degrees.
  final void Function(double longitude, double latitude)? onTap;

  /// Optional custom widget shown while the image is loading.
  final Widget? loadingWidget;

  /// Optional custom widget shown when the image fails to load.
  final Widget? errorWidget;

  const CustomPanoramaViewer({
    super.key,
    required this.child,
    this.controller,
    this.hotspots = const [],
    this.sensitivity = 1.0,
    this.initialLongitude = 0.0,
    this.initialLatitude = 0.0,
    this.initialZoom = 1.0,
    this.animSpeed = 0.0,
    this.zoomEnabled = true,
    this.sensorEnabled = true,
    this.sensorSensitivity = 1.0,
    this.onViewChanged,
    this.onTap,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<CustomPanoramaViewer> createState() => _CustomPanoramaViewerState();
}

class _CustomPanoramaViewerState extends State<CustomPanoramaViewer> {
  late PanoramaController _ctrl;
  bool _isExternalCtrl = false;

  // Image loading state
  bool _imageReady = false;
  bool _imageError = false;

  // Sensor stream
  StreamSubscription<AbsoluteOrientationEvent>? _sensorSub;
  double _sensorLon = 0;
  double _sensorLat = 0;

  @override
  void initState() {
    super.initState();

    _ctrl = widget.controller ?? PanoramaController();
    _isExternalCtrl = widget.controller != null;
    _ctrl.addListener(_onControllerUpdate);

    // Pre-warm the image in Flutter's image cache so the panorama starts fast.
    _precacheImage();

    if (widget.sensorEnabled) {
      _startSensor();
    }
  }

  @override
  void didUpdateWidget(CustomPanoramaViewer old) {
    super.didUpdateWidget(old);

    // Swap controller if the caller provides a new one.
    if (old.controller != widget.controller) {
      _ctrl.removeListener(_onControllerUpdate);
      _ctrl = widget.controller ?? PanoramaController();
      _isExternalCtrl = widget.controller != null;
      _ctrl.addListener(_onControllerUpdate);
    }

    // Start / stop sensor based on prop change.
    if (old.sensorEnabled != widget.sensorEnabled) {
      if (widget.sensorEnabled) {
        _startSensor();
      } else {
        _stopSensor();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerUpdate);
    if (!_isExternalCtrl) _ctrl.dispose();
    _stopSensor();
    super.dispose();
  }

  // ── Controller ────────────────────────────────────────────────────────────

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  // ── Image pre-cache ───────────────────────────────────────────────────────

  Future<void> _precacheImage() async {
    final provider = widget.child.image;
    try {
      await precacheImage(provider, context);
      if (mounted) setState(() => _imageReady = true);
    } catch (_) {
      if (mounted) setState(() => _imageError = true);
    }
  }

  // ── Sensor ────────────────────────────────────────────────────────────────

  void _startSensor() {
    try {
      motionSensors.absoluteOrientationUpdateInterval =
          Duration.microsecondsPerSecond ~/ 60;

      _sensorSub = motionSensors.absoluteOrientation.listen((event) {
        if (!mounted) return;
        setState(() {
          _sensorLon = (event.yaw * 180 / pi) * widget.sensorSensitivity;
          _sensorLat = (event.pitch * 180 / pi) * widget.sensorSensitivity;
        });
      });
    } catch (_) {
      // Sensors not available on this device/platform — degrade gracefully.
    }
  }

  void _stopSensor() {
    _sensorSub?.cancel();
    _sensorSub = null;
  }

  // ── Hotspot builder ───────────────────────────────────────────────────────

  List<pv.Hotspot> _buildHotspots() {
    return widget.hotspots.map((h) {
      return pv.Hotspot(
        longitude: h.longitude,
        latitude: h.latitude,
        width: 60.0,
        height: 60.0,
        widget: Semantics(
          label: h.label,
          button: h.onTap != null,
          child: GestureDetector(
            onTap: h.onTap,
            child: h.widget,
          ),
        ),
      );
    }).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_imageError) {
      return widget.errorWidget ??
          PanoramaErrorWidget(
            message: 'Could not load the panorama image.\n'
                'Ensure the image exists and is a valid equirectangular (2:1) JPEG/PNG.',
            onRetry: () {
              setState(() {
                _imageError = false;
                _imageReady = false;
              });
              _precacheImage();
            },
          );
    }

    if (!_imageReady) {
      return widget.loadingWidget ?? const PanoramaLoader();
    }

    // Merge sensor offsets with controller position.
    final effectiveLon = _ctrl.longitude +
        (widget.sensorEnabled ? _sensorLon : 0) +
        widget.initialLongitude;
    final effectiveLat = _ctrl.latitude +
        (widget.sensorEnabled ? _sensorLat : 0) +
        widget.initialLatitude;

    return pv.PanoramaViewer(
      sensitivity: widget.sensitivity,
      animSpeed: _ctrl.autoRotate ? widget.animSpeed.clamp(0.5, 5.0) : 0.0,
      zoom: widget.zoomEnabled ? _ctrl.zoom : 1.0,
      longitude: effectiveLon,
      latitude: effectiveLat,
      sensorControl: widget.sensorEnabled
          ? pv.SensorControl.orientation
          : pv.SensorControl.none,
      hotspots: _buildHotspots(),
      onViewChanged: widget.onViewChanged != null
          ? (lon, lat, tilt) => widget.onViewChanged!(lon, lat, tilt)
          : null,
      onTap: widget.onTap != null ? (lon, lat, o) => widget.onTap!(lon!, lat!) : null,
      child: widget.child,
    );
  }
}
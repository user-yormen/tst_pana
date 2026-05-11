// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tst_pana/capture/panorama_capture_screen.dart';
import 'package:tst_pana/capture/panorama_capture_theme.dart';
import 'package:tst_pana/capture/panorama_media.dart';
import 'package:tst_pana/custom_panorama_viewer.dart';
import 'package:tst_pana/panorama_controller.dart';
import 'package:tst_pana/panorama_error_widget.dart';
import 'package:tst_pana/panorama_hotspot.dart';
import 'package:tst_pana/panorama_loader.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test helpers
// ─────────────────────────────────────────────────────────────────────────────

/// An [ImageProvider] whose completer never resolves.
/// Keeps [_imageReady] and [_imageError] permanently false so the
/// loading widget stays on screen regardless of how many frames are pumped.
class _NeverResolvingImageProvider
    extends ImageProvider<_NeverResolvingImageProvider> {
  const _NeverResolvingImageProvider();

  @override
  Future<_NeverResolvingImageProvider> obtainKey(
          ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _NeverResolvingImageProvider key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}

Image _hangingImage() => Image(image: const _NeverResolvingImageProvider());
Image _failingNetworkImage() =>
    Image.network('https://example.invalid/pano.jpg');

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // PanoramaController
  // ══════════════════════════════════════════════════════════════════════════
  group('PanoramaController', () {
    late PanoramaController ctrl;
    setUp(() => ctrl = PanoramaController());
    tearDown(() => ctrl.dispose());

    test('has correct initial values', () {
      expect(ctrl.longitude, 0.0);
      expect(ctrl.latitude, 0.0);
      expect(ctrl.zoom, 1.0);
      expect(ctrl.autoRotate, false);
    });

    test('animateTo stores longitude and latitude', () {
      ctrl.animateTo(longitude: 45.0, latitude: -20.0);
      expect(ctrl.longitude, 45.0);
      expect(ctrl.latitude, -20.0);
    });

    test('animateTo accepts zero values', () {
      ctrl.animateTo(longitude: 0.0, latitude: 0.0);
      expect(ctrl.longitude, 0.0);
      expect(ctrl.latitude, 0.0);
    });

    test('animateTo accepts boundary values', () {
      ctrl.animateTo(longitude: 180.0, latitude: 90.0);
      expect(ctrl.longitude, 180.0);
      expect(ctrl.latitude, 90.0);
      ctrl.animateTo(longitude: -180.0, latitude: -90.0);
      expect(ctrl.longitude, -180.0);
      expect(ctrl.latitude, -90.0);
    });

    test('animateTo notifies listeners exactly once', () {
      int calls = 0;
      ctrl.addListener(() => calls++);
      ctrl.animateTo(longitude: 10.0, latitude: 5.0);
      expect(calls, 1);
    });

    test('setZoom stores value within range', () {
      ctrl.setZoom(2.5);
      expect(ctrl.zoom, 2.5);
    });

    test('setZoom clamps below 0.5', () {
      ctrl.setZoom(0.1);
      expect(ctrl.zoom, 0.5);
    });

    test('setZoom clamps above 10.0', () {
      ctrl.setZoom(99.0);
      expect(ctrl.zoom, 10.0);
    });

    test('setZoom accepts exact boundaries', () {
      ctrl.setZoom(0.5);
      expect(ctrl.zoom, 0.5);
      ctrl.setZoom(10.0);
      expect(ctrl.zoom, 10.0);
    });

    test('setZoom notifies listeners', () {
      int calls = 0;
      ctrl.addListener(() => calls++);
      ctrl.setZoom(3.0);
      expect(calls, 1);
    });

    test('setAutoRotate enables rotation', () {
      ctrl.setAutoRotate(true);
      expect(ctrl.autoRotate, true);
    });

    test('setAutoRotate disables rotation', () {
      ctrl.setAutoRotate(true);
      ctrl.setAutoRotate(false);
      expect(ctrl.autoRotate, false);
    });

    test('setAutoRotate notifies listeners', () {
      int calls = 0;
      ctrl.addListener(() => calls++);
      ctrl.setAutoRotate(true);
      expect(calls, 1);
    });

    test('reset restores all defaults', () {
      ctrl.animateTo(longitude: 90.0, latitude: 45.0);
      ctrl.setZoom(3.0);
      ctrl.setAutoRotate(true);
      ctrl.reset();
      expect(ctrl.longitude, 0.0);
      expect(ctrl.latitude, 0.0);
      expect(ctrl.zoom, 1.0);
      expect(ctrl.autoRotate, false);
    });

    test('reset notifies listeners', () {
      int calls = 0;
      ctrl.addListener(() => calls++);
      ctrl.reset();
      expect(calls, 1);
    });

    test('four mutations fire four notifications', () {
      int calls = 0;
      ctrl.addListener(() => calls++);
      ctrl.animateTo(longitude: 1.0, latitude: 0.0);
      ctrl.setZoom(2.0);
      ctrl.setAutoRotate(true);
      ctrl.reset();
      expect(calls, 4);
    });

    test('removed listener is not called', () {
      int calls = 0;
      void listener() => calls++;
      ctrl.addListener(listener);
      ctrl.animateTo(longitude: 10.0, latitude: 0.0);
      expect(calls, 1);
      ctrl.removeListener(listener);
      ctrl.animateTo(longitude: 20.0, latitude: 0.0);
      expect(calls, 1);
    });

    test('multiple listeners all receive notifications', () {
      int a = 0, b = 0;
      ctrl.addListener(() => a++);
      ctrl.addListener(() => b++);
      ctrl.setZoom(2.0);
      expect(a, 1);
      expect(b, 1);
    });

    test('two controllers maintain independent state', () {
      final ctrl2 = PanoramaController();
      addTearDown(ctrl2.dispose);
      ctrl.animateTo(longitude: 60.0, latitude: 30.0);
      expect(ctrl2.longitude, 0.0);
      expect(ctrl2.latitude, 0.0);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PanoramaHotspot
  // ══════════════════════════════════════════════════════════════════════════
  group('PanoramaHotspot', () {
    test('stores all fields', () {
      final hs = PanoramaHotspot(
        longitude: 30.0,
        latitude: -15.0,
        label: 'My hotspot',
        widget: const SizedBox(),
      );
      expect(hs.longitude, 30.0);
      expect(hs.latitude, -15.0);
      expect(hs.label, 'My hotspot');
      expect(hs.widget, isA<SizedBox>());
    });

    test('onTap fires', () {
      bool tapped = false;
      final hs = PanoramaHotspot(
        longitude: 0.0, latitude: 0.0,
        widget: const SizedBox(),
        onTap: () => tapped = true,
      );
      hs.onTap?.call();
      expect(tapped, true);
    });

    test('onTap defaults to null', () {
      final hs = PanoramaHotspot(
          longitude: 0.0, latitude: 0.0, widget: const SizedBox());
      expect(hs.onTap, isNull);
    });

    test('label defaults to null', () {
      final hs = PanoramaHotspot(
          longitude: 0.0, latitude: 0.0, widget: const SizedBox());
      expect(hs.label, isNull);
    });

    test('accepts boundary coordinates', () {
      final hs = PanoramaHotspot(
          longitude: -180.0, latitude: -90.0, widget: const SizedBox());
      expect(hs.longitude, -180.0);
      expect(hs.latitude, -90.0);
    });

    test('onTap can be called multiple times', () {
      int count = 0;
      final hs = PanoramaHotspot(
        longitude: 0.0, latitude: 0.0,
        widget: const SizedBox(),
        onTap: () => count++,
      );
      hs.onTap?.call();
      hs.onTap?.call();
      hs.onTap?.call();
      expect(count, 3);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PanoramaLoader
  // ══════════════════════════════════════════════════════════════════════════
  group('PanoramaLoader', () {
    testWidgets('renders CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: PanoramaLoader())));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays loading text', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: PanoramaLoader())));
      expect(find.text('Loading panorama…'), findsOneWidget);
    });

    testWidgets('applies custom backgroundColor', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: PanoramaLoader(backgroundColor: Colors.blue))));
      final box =
          tester.widget<ColoredBox>(find.byType(ColoredBox).first);
      expect(box.color, Colors.blue);
    });

    testWidgets('applies custom indicatorColor', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home:
              Scaffold(body: PanoramaLoader(indicatorColor: Colors.green))));
      final indicator = tester
          .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator));
      expect(indicator.color, Colors.green);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PanoramaErrorWidget
  // ══════════════════════════════════════════════════════════════════════════
  group('PanoramaErrorWidget', () {
    testWidgets('shows default message', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: PanoramaErrorWidget())));
      expect(find.text('Failed to load panorama image.'), findsOneWidget);
    });

    testWidgets('shows custom message', (tester) async {
      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(
              body: PanoramaErrorWidget(message: 'Custom error text'))));
      expect(find.text('Custom error text'), findsOneWidget);
    });

    testWidgets('renders broken_image_outlined icon', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: PanoramaErrorWidget())));
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });

    testWidgets('Retry button absent when onRetry is null', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: PanoramaErrorWidget())));
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('Retry button present when onRetry is provided',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: PanoramaErrorWidget(onRetry: () {}))));
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('tapping Retry fires callback', (tester) async {
      bool retried = false;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: PanoramaErrorWidget(
                  onRetry: () => retried = true))));
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, true);
    });

    testWidgets('uses black background', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: PanoramaErrorWidget())));
      final box =
          tester.widget<ColoredBox>(find.byType(ColoredBox).first);
      expect(box.color, Colors.black);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // CustomPanoramaViewer – loading state
  // ══════════════════════════════════════════════════════════════════════════
  group('CustomPanoramaViewer – loading state', () {
    testWidgets('shows PanoramaLoader while provider never resolves',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: CustomPanoramaViewer(
                  sensorEnabled: false, child: _hangingImage()))));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(PanoramaLoader), findsOneWidget);
      expect(find.byType(PanoramaErrorWidget), findsNothing);
    });

    testWidgets('shows custom loadingWidget instead of PanoramaLoader',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: CustomPanoramaViewer(
                  sensorEnabled: false,
                  loadingWidget: const Text('custom-loading'),
                  child: _hangingImage()))));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('custom-loading'), findsOneWidget);
      expect(find.byType(PanoramaLoader), findsNothing);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // CustomPanoramaViewer – error state
  // ══════════════════════════════════════════════════════════════════════════
  group('CustomPanoramaViewer – error state', () {
    testWidgets('shows PanoramaErrorWidget after image failure',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: CustomPanoramaViewer(
                  sensorEnabled: false, child: _failingNetworkImage()))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PanoramaErrorWidget), findsOneWidget);
      expect(find.byType(PanoramaLoader), findsNothing);
    });

    testWidgets('shows custom errorWidget instead of default', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: CustomPanoramaViewer(
                  sensorEnabled: false,
                  errorWidget: const Text('custom-error'),
                  child: _failingNetworkImage()))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('custom-error'), findsOneWidget);
      expect(find.byType(PanoramaErrorWidget), findsNothing);
    });

    testWidgets('does not throw during image failure', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: CustomPanoramaViewer(
                  sensorEnabled: false, child: _failingNetworkImage()))));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // CustomPanoramaViewer – parameter acceptance
  // ══════════════════════════════════════════════════════════════════════════
  group('CustomPanoramaViewer – parameter acceptance', () {
    Widget build({
      PanoramaController? controller,
      List<PanoramaHotspot> hotspots = const [],
      double sensitivity = 1.0,
      double initialLongitude = 0.0,
      double initialLatitude = 0.0,
      double animSpeed = 0.0,
      bool zoomEnabled = true,
      bool sensorEnabled = false,
      ViewChangedCallback? onViewChanged,
      void Function(double, double)? onTap,
    }) =>
        MaterialApp(
          home: Scaffold(
            body: CustomPanoramaViewer(
              controller: controller,
              hotspots: hotspots,
              sensitivity: sensitivity,
              initialLongitude: initialLongitude,
              initialLatitude: initialLatitude,
              animSpeed: animSpeed,
              zoomEnabled: zoomEnabled,
              sensorEnabled: sensorEnabled,
              onViewChanged: onViewChanged,
              onTap: onTap,
              child: _hangingImage(),
            ),
          ),
        );

    testWidgets('accepts all defaults', (tester) async {
      await tester.pumpWidget(build());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts external PanoramaController', (tester) async {
      final ctrl = PanoramaController();
      addTearDown(ctrl.dispose);
      await tester.pumpWidget(build(controller: ctrl));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts non-empty hotspots list', (tester) async {
      await tester.pumpWidget(build(hotspots: [
        PanoramaHotspot(
            longitude: 0, latitude: 0, widget: const Icon(Icons.place)),
      ]));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts non-zero initial position', (tester) async {
      await tester.pumpWidget(
          build(initialLongitude: 45.0, initialLatitude: -20.0));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts zoomEnabled: false', (tester) async {
      await tester.pumpWidget(build(zoomEnabled: false));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('controller mutations do not throw in loading state',
        (tester) async {
      final ctrl = PanoramaController();
      addTearDown(ctrl.dispose);
      await tester.pumpWidget(build(controller: ctrl));
      await tester.pump();
      ctrl.animateTo(longitude: 90, latitude: 30);
      ctrl.setZoom(2.0);
      ctrl.setAutoRotate(true);
      ctrl.reset();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('replacing controller via didUpdateWidget does not throw',
        (tester) async {
      final ctrl1 = PanoramaController();
      final ctrl2 = PanoramaController();
      addTearDown(ctrl1.dispose);
      addTearDown(ctrl2.dispose);
      await tester.pumpWidget(build(controller: ctrl1));
      await tester.pump();
      await tester.pumpWidget(build(controller: ctrl2));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PanoramaMedia – unit tests
  // ══════════════════════════════════════════════════════════════════════════
  group('PanoramaMedia', () {
    test('aspectRatio is null when dimensions are null', () {
      final m = PanoramaMedia(
          file: File('/tmp/test.jpg'), source: PanoramaSource.gallery);
      expect(m.aspectRatio, isNull);
      expect(m.isValidPanorama, false);
    });

    test('aspectRatio is null when height is zero', () {
      final m = PanoramaMedia(
          file: File('/tmp/test.jpg'),
          source: PanoramaSource.gallery,
          width: 4096,
          height: 0);
      expect(m.aspectRatio, isNull);
    });

    test('computes aspectRatio correctly', () {
      final m = PanoramaMedia(
          file: File('/tmp/test.jpg'),
          source: PanoramaSource.gallery,
          width: 4096,
          height: 2048);
      expect(m.aspectRatio, closeTo(2.0, 0.001));
    });

    test('isValidPanorama true for 2:1 image', () {
      final m = PanoramaMedia(
          file: File('/tmp/test.jpg'),
          source: PanoramaSource.gallery,
          width: 4096,
          height: 2048);
      expect(m.isValidPanorama, true);
    });

    test('isValidPanorama true at lower boundary (1.8:1)', () {
      final m = PanoramaMedia(
          file: File('/tmp/test.jpg'),
          source: PanoramaSource.gallery,
          width: 1800,
          height: 1000);
      expect(m.isValidPanorama, true);
    });

    test('isValidPanorama true at upper boundary (2.2:1)', () {
      final m = PanoramaMedia(
          file: File('/tmp/test.jpg'),
          source: PanoramaSource.gallery,
          width: 2200,
          height: 1000);
      expect(m.isValidPanorama, true);
    });

    test('isValidPanorama false for standard photo (4:3)', () {
      final m = PanoramaMedia(
          file: File('/tmp/test.jpg'),
          source: PanoramaSource.gallery,
          width: 4000,
          height: 3000);
      expect(m.isValidPanorama, false);
    });

    test('isValidPanorama false for square image', () {
      final m = PanoramaMedia(
          file: File('/tmp/test.jpg'),
          source: PanoramaSource.gallery,
          width: 1000,
          height: 1000);
      expect(m.isValidPanorama, false);
    });

    test('isValidPanorama false for portrait image', () {
      final m = PanoramaMedia(
          file: File('/tmp/test.jpg'),
          source: PanoramaSource.gallery,
          width: 1000,
          height: 2000);
      expect(m.isValidPanorama, false);
    });

    test('source is stored correctly for gallery', () {
      final m = PanoramaMedia(
          file: File('/tmp/test.jpg'), source: PanoramaSource.gallery);
      expect(m.source, PanoramaSource.gallery);
    });

    test('source is stored correctly for guided', () {
      final m = PanoramaMedia(
          file: File('/tmp/test.jpg'), source: PanoramaSource.guided);
      expect(m.source, PanoramaSource.guided);
    });

    test('toString includes source and dimensions', () {
      final m = PanoramaMedia(
          file: File('/tmp/test.jpg'),
          source: PanoramaSource.gallery,
          width: 4096,
          height: 2048);
      final s = m.toString();
      expect(s, contains('gallery'));
      expect(s, contains('4096'));
      expect(s, contains('2048'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PanoramaCaptureTheme – unit tests
  // ══════════════════════════════════════════════════════════════════════════
  group('PanoramaCaptureTheme', () {
    test('default theme has black background', () {
      const t = PanoramaCaptureTheme();
      expect(t.backgroundColor, Colors.black);
    });

    test('default theme has teal accent', () {
      const t = PanoramaCaptureTheme();
      expect(t.accentColor, const Color(0xFF00C4A0));
    });

    test('light theme has non-black background', () {
      expect(PanoramaCaptureTheme.light.backgroundColor,
          isNot(Colors.black));
    });

    test('custom values are stored', () {
      const t = PanoramaCaptureTheme(
        backgroundColor: Colors.white,
        accentColor: Colors.purple,
        textColor: Colors.black,
        buttonColor: Colors.purple,
        buttonTextColor: Colors.white,
      );
      expect(t.backgroundColor, Colors.white);
      expect(t.accentColor, Colors.purple);
      expect(t.buttonColor, Colors.purple);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PanoramaCaptureScreen – widget tests
  // ══════════════════════════════════════════════════════════════════════════
  group('PanoramaCaptureScreen', () {
    Widget buildScreen({PanoramaCaptureTheme? theme}) => MaterialApp(
          home: PanoramaCaptureScreen(theme: theme),
        );

    testWidgets('renders instructions step on first open', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.text('How to shoot a 360° panorama'), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.text('Capture panorama'), findsOneWidget);
    });

    testWidgets('shows all four instruction steps', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('shows Open camera app button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.text('Open camera app'), findsOneWidget);
    });

    testWidgets('shows sweep arc animation widget', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.byType(CustomPaint), findsAtLeast(1));
    });

    testWidgets('close button pops screen with null', (tester) async {
      PanoramaMedia? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) => ElevatedButton(
          onPressed: () async {
            result = await Navigator.push<PanoramaMedia>(
              ctx,
              MaterialPageRoute(
                builder: (_) => const PanoramaCaptureScreen(),
              ),
            );
          },
          child: const Text('open'),
        )),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('tapping Open camera app advances to waiting step',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.text('Open camera app'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Either waiting step or pick step is shown (platform channel
      // returns immediately in test env, advancing straight to pick).
      final onWaiting = find.text('Take your panorama');
      final onPick = find.text('Select your panorama');
      expect(
        onWaiting.evaluate().isNotEmpty || onPick.evaluate().isNotEmpty,
        true,
      );
    });

    testWidgets('accepts custom theme without crash', (tester) async {
      await tester.pumpWidget(buildScreen(theme: PanoramaCaptureTheme.light));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not throw on pump', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Arithmetic helpers (pure unit, no widget needed)
  // ══════════════════════════════════════════════════════════════════════════
  group('Position arithmetic', () {
    double effectiveLon(double ctrlLon, bool sensorEnabled,
            double sensorLon, double initialLon) =>
        ctrlLon + (sensorEnabled ? sensorLon : 0) + initialLon;

    double effectiveLat(double ctrlLat, bool sensorEnabled,
            double sensorLat, double initialLat) =>
        ctrlLat + (sensorEnabled ? sensorLat : 0) + initialLat;

    test('sensor offsets added when enabled', () {
      expect(effectiveLon(10, true, 3, 15), 28.0);
      expect(effectiveLat(5, true, 2, 8), 15.0);
    });

    test('sensor offsets ignored when disabled', () {
      expect(effectiveLon(10, false, 3, 15), 25.0);
      expect(effectiveLat(5, false, 2, 8), 13.0);
    });

    test('zero offsets return ctrl position only', () {
      expect(effectiveLon(42, true, 0, 0), 42.0);
      expect(effectiveLat(-7, true, 0, 0), -7.0);
    });
  });

  group('AnimSpeed clamping', () {
    double eff(bool autoRotate, double speed) =>
        autoRotate ? speed.clamp(0.5, 5.0) : 0.0;

    test('mid-range passes through', () => expect(eff(true, 1.5), 1.5));
    test('clamps low to 0.5', () => expect(eff(true, 0.0), 0.5));
    test('clamps high to 5.0', () => expect(eff(true, 9.0), 5.0));
    test('returns 0.0 when autoRotate off', () {
      expect(eff(false, 3.0), 0.0);
      expect(eff(false, 0.0), 0.0);
    });
  });

  group('Zoom passthrough', () {
    double eff(bool enabled, double zoom) => enabled ? zoom : 1.0;

    test('passes through when enabled', () {
      expect(eff(true, 3.0), 3.0);
      expect(eff(true, 0.5), 0.5);
    });
    test('forced to 1.0 when disabled', () {
      expect(eff(false, 3.0), 1.0);
      expect(eff(false, 10.0), 1.0);
    });
  });
}

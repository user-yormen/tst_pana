// import 'package:flutter/cupertino.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:tst_pana/panorama_controller.dart';
// import 'package:tst_pana/panorama_hotspot.dart';
//
// void main() {
//   // ── PanoramaController ───────────────────────────────────────────────────
//   group('PanoramaController', () {
//     late PanoramaController ctrl;
//
//     setUp(() => ctrl = PanoramaController());
//     tearDown(() => ctrl.dispose());
//
//     test('initial values are zero / defaults', () {
//       expect(ctrl.longitude, 0.0);
//       expect(ctrl.latitude, 0.0);
//       expect(ctrl.zoom, 1.0);
//       expect(ctrl.autoRotate, false);
//     });
//
//     test('animateTo updates longitude and latitude', () {
//       ctrl.animateTo(longitude: 45, latitude: -20);
//       expect(ctrl.longitude, 45.0);
//       expect(ctrl.latitude, -20.0);
//     });
//
//     test('setZoom clamps to [0.5, 10.0]', () {
//       ctrl.setZoom(0.1);
//       expect(ctrl.zoom, 0.5);
//
//       ctrl.setZoom(99);
//       expect(ctrl.zoom, 10.0);
//
//       ctrl.setZoom(2.5);
//       expect(ctrl.zoom, 2.5);
//     });
//
//     test('setAutoRotate toggles the flag', () {
//       ctrl.setAutoRotate(true);
//       expect(ctrl.autoRotate, true);
//
//       ctrl.setAutoRotate(false);
//       expect(ctrl.autoRotate, false);
//     });
//
//     test('reset restores defaults', () {
//       ctrl.animateTo(longitude: 90, latitude: 45);
//       ctrl.setZoom(3.0);
//       ctrl.setAutoRotate(true);
//
//       ctrl.reset();
//
//       expect(ctrl.longitude, 0.0);
//       expect(ctrl.latitude, 0.0);
//       expect(ctrl.zoom, 1.0);
//       expect(ctrl.autoRotate, false);
//     });
//
//     test('notifyListeners is called on each mutation', () {
//       int callCount = 0;
//       ctrl.addListener(() => callCount++);
//
//       ctrl.animateTo(longitude: 1, latitude: 0);
//       ctrl.setZoom(2);
//       ctrl.setAutoRotate(true);
//       ctrl.reset();
//
//       expect(callCount, 4);
//     });
//   });
//
//   // ── PanoramaHotspot ──────────────────────────────────────────────────────
//   group('PanoramaHotspot', () {
//     test('stores all properties correctly', () {
//       bool tapped = false;
//       final hs = PanoramaHotspot(
//         longitude: 30,
//         latitude: -15,
//         widget: const SizedBox(),
//         onTap: () => tapped = true,
//         label: 'My hotspot',
//       );
//
//       expect(hs.longitude, 30.0);
//       expect(hs.latitude, -15.0);
//       expect(hs.label, 'My hotspot');
//
//       hs.onTap?.call();
//       expect(tapped, true);
//     });
//
//     test('optional onTap defaults to null', () {
//       final hs = PanoramaHotspot(
//         longitude: 0,
//         latitude: 0,
//         widget: SizedBox(),
//       );
//       expect(hs.onTap, isNull);
//     });
//   });
// }

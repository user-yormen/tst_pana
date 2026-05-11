import 'package:flutter/material.dart';
import 'package:tst_pana/custom_panorama_viewer.dart';
import 'package:tst_pana/panorama_controller.dart';
import 'package:tst_pana/panorama_hotspot.dart';

void main() => runApp(const PanoramaExampleApp());

class PanoramaExampleApp extends StatelessWidget {
  const PanoramaExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panorama Viewer Demo',
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home – choose a demo
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = [
      _Demo('Network Image', Icons.cloud_download, () => const NetworkDemo()),
      _Demo('With Hotspots', Icons.location_pin, () => const HotspotDemo()),
      _Demo('Programmatic Control', Icons.gamepad, () => const ControlDemo()),
      _Demo('Auto-rotate', Icons.rotate_right, () => const AutoRotateDemo()),
      _Demo('Side-by-Side', Icons.view_column, () => const SideBySideDemo()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Panorama Viewer Demos')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final d = demos[i];
          return ListTile(
            leading: Icon(d.icon, size: 28),
            title: Text(d.title),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            tileColor: Theme.of(ctx).colorScheme.surfaceVariant,
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => d.builder()),
            ),
          );
        },
      ),
    );
  }
}

class _Demo {
  final String title;
  final IconData icon;
  final Widget Function() builder;
  _Demo(this.title, this.icon, this.builder);
}

// ─────────────────────────────────────────────────────────────────────────────
// Demo 1 – Network image
// ─────────────────────────────────────────────────────────────────────────────

class NetworkDemo extends StatelessWidget {
  const NetworkDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Panorama')),
      body: CustomPanoramaViewer(
        // Replace with a real 2:1 equirectangular image URL.
        child: Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/'
          'Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg/'
          '2560px-Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg',
          fit: BoxFit.cover,
        ),
        sensitivity: 2.0,
        onViewChanged: (lon, lat, tilt) {
          debugPrint('lon=$lon lat=$lat tilt=$tilt');
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Demo 2 – Hotspots
// ─────────────────────────────────────────────────────────────────────────────

class HotspotDemo extends StatelessWidget {
  const HotspotDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hotspot Demo')),
      body: CustomPanoramaViewer(
        child: Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/'
          'Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg/'
          '2560px-Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg',
          fit: BoxFit.cover,
        ),
        hotspots: [
          PanoramaHotspot(
            longitude: 0,
            latitude: 0,
            label: 'Center hotspot',
            widget: _PinWidget(color: Colors.redAccent, label: 'Center'),
            onTap: () => _showSnack(context, 'Center hotspot tapped!'),
          ),
          PanoramaHotspot(
            longitude: 90,
            latitude: 10,
            label: 'East hotspot',
            widget: _PinWidget(color: Colors.blueAccent, label: 'East'),
            onTap: () => _showSnack(context, 'East hotspot tapped!'),
          ),
          PanoramaHotspot(
            longitude: -90,
            latitude: -10,
            label: 'West hotspot',
            widget: _PinWidget(color: Colors.green, label: 'West'),
            onTap: () => _showSnack(context, 'West hotspot tapped!'),
          ),
        ],
        onTap: (lon, lat) => _showSnack(context, 'Tapped at $lon°, $lat°'),
      ),
    );
  }

  void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _PinWidget extends StatelessWidget {
  final Color color;
  final String label;
  const _PinWidget({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_pin, color: color, size: 36),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 10)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Demo 3 – Programmatic Control
// ─────────────────────────────────────────────────────────────────────────────

class ControlDemo extends StatefulWidget {
  const ControlDemo({super.key});

  @override
  State<ControlDemo> createState() => _ControlDemoState();
}

class _ControlDemoState extends State<ControlDemo> {
  final PanoramaController _ctrl = PanoramaController();
  double _lonSlider = 0;
  double _latSlider = 0;
  double _zoomSlider = 1;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programmatic Control')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: CustomPanoramaViewer(
              controller: _ctrl,
              sensorEnabled: false,
              child: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/'
                'Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg/'
                '2560px-Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SliderRow(
                    label: 'Longitude',
                    value: _lonSlider,
                    min: -180,
                    max: 180,
                    onChanged: (v) {
                      setState(() => _lonSlider = v);
                      _ctrl.animateTo(
                          longitude: v, latitude: _latSlider);
                    },
                  ),
                  _SliderRow(
                    label: 'Latitude',
                    value: _latSlider,
                    min: -90,
                    max: 90,
                    onChanged: (v) {
                      setState(() => _latSlider = v);
                      _ctrl.animateTo(
                          longitude: _lonSlider, latitude: v);
                    },
                  ),
                  _SliderRow(
                    label: 'Zoom',
                    value: _zoomSlider,
                    min: 0.5,
                    max: 5,
                    onChanged: (v) {
                      setState(() => _zoomSlider = v);
                      _ctrl.setZoom(v);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _lonSlider = 0;
                            _latSlider = 0;
                            _zoomSlider = 1;
                          });
                          _ctrl.reset();
                        },
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => _ctrl.animateTo(
                            longitude: 45, latitude: 20),
                        child: const Text('Jump to 45°, 20°'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
            child: Slider(value: value, min: min, max: max, onChanged: onChanged)),
        SizedBox(
            width: 48,
            child: Text(value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Demo 4 – Auto-rotate
// ─────────────────────────────────────────────────────────────────────────────

class AutoRotateDemo extends StatefulWidget {
  const AutoRotateDemo({super.key});

  @override
  State<AutoRotateDemo> createState() => _AutoRotateDemoState();
}

class _AutoRotateDemoState extends State<AutoRotateDemo> {
  final _ctrl = PanoramaController();
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _ctrl.setAutoRotate(true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-rotate'),
        actions: [
          IconButton(
            icon: Icon(_ctrl.autoRotate ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() => _ctrl.setAutoRotate(!_ctrl.autoRotate));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomPanoramaViewer(
              controller: _ctrl,
              animSpeed: _speed,
              sensorEnabled: false,
              child: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/'
                'Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg/'
                '2560px-Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Speed'),
                Expanded(
                  child: Slider(
                    value: _speed,
                    min: 0.1,
                    max: 5,
                    onChanged: (v) => setState(() => _speed = v),
                  ),
                ),
                Text(_speed.toStringAsFixed(1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Demo 5 – Side-by-Side
// ─────────────────────────────────────────────────────────────────────────────

class SideBySideDemo extends StatelessWidget {
  const SideBySideDemo({super.key});

  static const _url =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/'
      'Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg/'
      '2560px-Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Side-by-Side')),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Viewer A', style: TextStyle(fontSize: 12)),
                ),
                Expanded(
                  child: CustomPanoramaViewer(
                    initialLongitude: -45,
                    sensorEnabled: false,
                    child: Image.network(_url, fit: BoxFit.cover),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Viewer B', style: TextStyle(fontSize: 12)),
                ),
                Expanded(
                  child: CustomPanoramaViewer(
                    initialLongitude: 45,
                    sensorEnabled: false,
                    child: Image.network(_url, fit: BoxFit.cover),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

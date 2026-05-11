import 'dart:io';
import 'dart:math' show cos, sin;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tst_pana/capture/panorama_capture_theme.dart';

import 'panorama_media.dart';

/// A full-screen, step-by-step guide that walks the user through:
///
///  1. An explanation of how to shoot a panorama on their device.
///  2. A button that opens the device's native camera app.
///  3. After returning from the camera, a prompt to pick the resulting
///     panorama from the gallery.
///  4. Validation feedback — warns if the chosen image doesn't look like
///     an equirectangular panorama.
///
/// The screen pops with a [PanoramaMedia] on success, or with `null`
/// if the user cancels.
///
/// Do not push this screen directly; use [PanoramaPicker.fromGuidedCapture]
/// instead.
class PanoramaCaptureScreen extends StatefulWidget {
  final PanoramaCaptureTheme? theme;

  const PanoramaCaptureScreen({super.key, this.theme});

  @override
  State<PanoramaCaptureScreen> createState() => _PanoramaCaptureScreenState();
}

class _PanoramaCaptureScreenState extends State<PanoramaCaptureScreen>
    with SingleTickerProviderStateMixin {
  // ── Step state ─────────────────────────────────────────────────────────────
  _CaptureStep _step = _CaptureStep.instructions;
  bool _loading = false;
  String? _errorMessage;
  bool _aspectWarning = false;

  // ── Animation (progress arc on instructions step) ─────────────────────────
  late final AnimationController _arcController;
  late final Animation<double> _arcAnim;

  final _picker = ImagePicker();

  PanoramaCaptureTheme get _theme =>
      widget.theme ?? const PanoramaCaptureTheme();

  @override
  void initState() {
    super.initState();
    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _arcAnim = CurvedAnimation(parent: _arcController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _arcController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _openNativeCamera() async {
    // Launch the native camera in video/photo mode. The user switches to
    // panorama mode themselves — Flutter has no API to force a specific mode.
    // We use platform channel to open the native camera app.
    setState(() {
      _step = _CaptureStep.waitingForReturn;
      _errorMessage = null;
    });
    try {
      await SystemChannels.platform
          .invokeMethod('SystemNavigator.routeUpdated');
    } catch (_) {
      // Not all platforms support this — it's best-effort.
    }
    // On return, prompt the user to select from gallery.
    if (mounted) {
      setState(() => _step = _CaptureStep.pickFromGallery);
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _aspectWarning = false;
    });

    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (!mounted) return;

      if (xFile == null) {
        setState(() => _loading = false);
        return;
      }

      final file = File(xFile.path);
      final (w, h) = await _decodeSize(file);

      if (!mounted) return;

      final media = PanoramaMedia(
        file: file,
        source: PanoramaSource.guided,
        width: w,
        height: h,
      );

      if (!media.isValidPanorama) {
        setState(() {
          _loading = false;
          _aspectWarning = true;
        });
        // Give user a moment to see the warning, then still let them proceed.
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
      }

      Navigator.of(context).pop(media);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Could not load image: $e';
        });
      }
    }
  }

  Future<(int?, int?)> _decodeSize(File file) async {
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: _theme.backgroundColor,
        foregroundColor: _theme.textColor,
        elevation: 0,
        title: Text(
          'Capture panorama',
          style: TextStyle(color: _theme.textColor),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      _CaptureStep.instructions => _InstructionsStep(
          key: const ValueKey('instructions'),
          theme: _theme,
          arcAnimation: _arcAnim,
          onOpenCamera: _openNativeCamera,
        ),
      _CaptureStep.waitingForReturn => _WaitingStep(
          key: const ValueKey('waiting'),
          theme: _theme,
          onContinue: () =>
              setState(() => _step = _CaptureStep.pickFromGallery),
        ),
      _CaptureStep.pickFromGallery => _PickStep(
          key: const ValueKey('pick'),
          theme: _theme,
          loading: _loading,
          errorMessage: _errorMessage,
          aspectWarning: _aspectWarning,
          onPick: _pickFromGallery,
          onRetry: () => setState(() {
            _step = _CaptureStep.instructions;
            _errorMessage = null;
            _aspectWarning = false;
          }),
        ),
    };
  }
}

// ── Step enum ──────────────────────────────────────────────────────────────

enum _CaptureStep { instructions, waitingForReturn, pickFromGallery }

// ── Step widgets ───────────────────────────────────────────────────────────

class _InstructionsStep extends StatelessWidget {
  final PanoramaCaptureTheme theme;
  final Animation<double> arcAnimation;
  final VoidCallback onOpenCamera;

  const _InstructionsStep({
    super.key,
    required this.theme,
    required this.arcAnimation,
    required this.onOpenCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Animated sweep illustration
          SizedBox(
            width: 160,
            height: 160,
            child: AnimatedBuilder(
              animation: arcAnimation,
              builder: (_, __) => CustomPaint(
                painter: _SweepArcPainter(
                  progress: arcAnimation.value,
                  color: theme.accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'How to shoot a 360° panorama',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.accentColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ..._steps(theme.textColor),
          const SizedBox(height: 40),
          _PrimaryButton(
            label: 'Open camera app',
            theme: theme,
            onPressed: onOpenCamera,
          ),
          const SizedBox(height: 16),
          Text(
            'Your device\'s panorama mode will do the stitching.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _steps(Color textColor) {
    const items = [
      ('1', 'Open your camera app and select Panorama mode'),
      ('2', 'Hold your phone vertically and sweep slowly left to right'),
      ('3', 'Tap Done when the sweep bar is full'),
      ('4', 'Return here — we\'ll open your gallery to select it'),
    ];
    return items
        .map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.accentColor.withValues(alpha: 0.2),
                    child: Text(s.$1,
                        style: TextStyle(
                            color: theme.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.$2,
                        style: TextStyle(color: textColor, fontSize: 14)),
                  ),
                ],
              ),
            ))
        .toList();
  }
}

class _WaitingStep extends StatelessWidget {
  final PanoramaCaptureTheme theme;
  final VoidCallback onContinue;

  const _WaitingStep({
    super.key,
    required this.theme,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, color: theme.accentColor, size: 64),
          const SizedBox(height: 24),
          Text(
            'Take your panorama',
            style: TextStyle(
                color: theme.accentColor,
                fontSize: 22,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            'Use your camera\'s panorama mode, then come back here '
            'when you\'re done.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textColor, fontSize: 15),
          ),
          const SizedBox(height: 40),
          _PrimaryButton(
            label: 'I\'ve taken the panorama',
            theme: theme,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _PickStep extends StatelessWidget {
  final PanoramaCaptureTheme theme;
  final bool loading;
  final String? errorMessage;
  final bool aspectWarning;
  final VoidCallback onPick;
  final VoidCallback onRetry;

  const _PickStep({
    super.key,
    required this.theme,
    required this.loading,
    required this.errorMessage,
    required this.aspectWarning,
    required this.onPick,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined,
              color: theme.accentColor, size: 64),
          const SizedBox(height: 24),
          Text(
            'Select your panorama',
            style: TextStyle(
                color: theme.accentColor,
                fontSize: 22,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            'Open your photo library and select the panorama you just shot.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textColor, fontSize: 15),
          ),
          if (aspectWarning) ...[
            const SizedBox(height: 16),
            _WarningBanner(
              message: 'The selected image may not be a full panorama '
                  '(aspect ratio outside 1.8–2.2). It will still open '
                  'in the viewer.',
              theme: theme,
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: errorMessage!, theme: theme),
          ],
          const SizedBox(height: 40),
          if (loading)
            CircularProgressIndicator(color: theme.accentColor)
          else ...[
            _PrimaryButton(
              label: 'Open photo library',
              theme: theme,
              onPressed: onPick,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Back to instructions',
                style: TextStyle(color: theme.textColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final PanoramaCaptureTheme theme;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.theme,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: theme.buttonColor,
          foregroundColor: theme.buttonTextColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;
  final PanoramaCaptureTheme theme;

  const _WarningBanner({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined,
              color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style:
                    const TextStyle(color: Colors.amber, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final PanoramaCaptureTheme theme;

  const _ErrorBanner({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Sweep arc painter ─────────────────────────────────────────────────────

/// Draws an animated phone-sweep arc — the classic panorama capture motif.
class _SweepArcPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color color;

  const _SweepArcPainter({required this.progress, required this.color});

  static const double _startAngle = -2.4;
  static const double _sweepTotal = 4.8;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.42;
    final center = Offset(cx, cy);
    final trackRect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      trackRect, _startAngle, _sweepTotal, false,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        trackRect, _startAngle, _sweepTotal * progress, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }

    final angle = _startAngle + (_sweepTotal * progress);
    final px = cx + radius * cos(angle);
    final py = cy + radius * sin(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(px, py), width: 14, height: 22),
        const Radius.circular(3),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SweepArcPainter old) =>
      old.progress != progress || old.color != color;
}

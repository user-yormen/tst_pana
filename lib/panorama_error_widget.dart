import 'package:flutter/material.dart';

/// Shown when the panorama image fails to load or has an invalid aspect ratio.
class PanoramaErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const PanoramaErrorWidget({
    super.key,
    this.message = 'Failed to load panorama image.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined,
                  color: Colors.white54, size: 56),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

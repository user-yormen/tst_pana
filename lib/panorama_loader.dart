import 'package:flutter/material.dart';

/// Shown while the panorama image is being fetched / decoded.
class PanoramaLoader extends StatelessWidget {
  final Color backgroundColor;
  final Color indicatorColor;

  const PanoramaLoader({
    super.key,
    this.backgroundColor = Colors.black,
    this.indicatorColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: indicatorColor),
            const SizedBox(height: 16),
            Text(
              'Loading panorama…',
              style: TextStyle(color: indicatorColor.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/vyra_theme.dart';

/// Real-time filter widget that applies filters to camera preview
class CameraFilterWidget extends StatelessWidget {
  final Widget child;
  final String filterName;
  final double intensity;

  const CameraFilterWidget({
    super.key,
    required this.child,
    required this.filterName,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (filterName == 'None') {
      return child;
    }

    return ColorFiltered(
      colorFilter: _getColorFilter(filterName, intensity),
      child: child,
    );
  }

  ColorFilter _getColorFilter(String filterName, double intensity) {
    switch (filterName) {
      case 'Vintage':
        return ColorFilter.matrix([
          0.9 * intensity, 0.5 * intensity, 0.1 * intensity, 0, 0,
          0.3 * intensity, 0.8 * intensity, 0.1 * intensity, 0, 0,
          0.2 * intensity, 0.3 * intensity, 0.5 * intensity, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Black & White':
        return ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Sepia':
        return ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Warm':
        return ColorFilter.matrix([
          1.1 * intensity, 0.1 * intensity, 0, 0, 0,
          0.1 * intensity, 1.0 * intensity, 0, 0, 0,
          0, 0, 0.9 * intensity, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Cool':
        return ColorFilter.matrix([
          0.9 * intensity, 0, 0.1 * intensity, 0, 0,
          0, 1.0 * intensity, 0.1 * intensity, 0, 0,
          0.1 * intensity, 0.1 * intensity, 1.1 * intensity, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Dramatic':
        return ColorFilter.matrix([
          1.2 * intensity, 0, 0, 0, 0,
          0, 1.1 * intensity, 0, 0, 0,
          0, 0, 0.9 * intensity, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Bright':
        return ColorFilter.matrix([
          1.2 * intensity, 0, 0, 0, 20 * intensity,
          0, 1.2 * intensity, 0, 0, 20 * intensity,
          0, 0, 1.2 * intensity, 0, 20 * intensity,
          0, 0, 0, 1, 0,
        ]);
      case 'Contrast':
        return ColorFilter.matrix([
          1.3 * intensity, 0, 0, 0, -20 * intensity,
          0, 1.3 * intensity, 0, 0, -20 * intensity,
          0, 0, 1.3 * intensity, 0, -20 * intensity,
          0, 0, 0, 1, 0,
        ]);
      case 'Saturated':
        return ColorFilter.matrix([
          1.5 * intensity, 0, 0, 0, 0,
          0, 1.3 * intensity, 0, 0, 0,
          0, 0, 1.1 * intensity, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Beauty':
        return ColorFilter.matrix([
          1.1 * intensity, 0.05 * intensity, 0.05 * intensity, 0, 5 * intensity,
          0.05 * intensity, 1.1 * intensity, 0.05 * intensity, 0, 5 * intensity,
          0.05 * intensity, 0.05 * intensity, 1.1 * intensity, 0, 5 * intensity,
          0, 0, 0, 1, 0,
        ]);
      case 'Noir':
        return ColorFilter.matrix([
          0.3, 0.6, 0.1, 0, 0,
          0.3, 0.6, 0.1, 0, 0,
          0.3, 0.6, 0.1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Chrome':
        return ColorFilter.matrix([
          0.5, 0.5, 0.5, 0, 0,
          0.5, 0.5, 0.5, 0, 0,
          0.5, 0.5, 0.5, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Fade':
        return ColorFilter.matrix([
          0.8, 0.2, 0, 0, 0,
          0.2, 0.8, 0, 0, 0,
          0, 0.2, 0.8, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Process':
        return ColorFilter.matrix([
          1.1, 0, 0, 0, 0,
          0, 0.9, 0, 0, 0,
          0, 0, 1.0, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Transfer':
        return ColorFilter.matrix([
          0.9, 0.1, 0, 0, 0,
          0, 0.9, 0.1, 0, 0,
          0.1, 0, 0.9, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Tonal':
        return ColorFilter.matrix([
          0.6, 0.4, 0, 0, 0,
          0.4, 0.6, 0, 0, 0,
          0, 0.4, 0.6, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      default:
        return const ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
  }
}

/// Sticker overlay widget
class StickerOverlay extends StatelessWidget {
  final String stickerType;
  final Offset position;
  final double scale;
  final double rotation;

  const StickerOverlay({
    super.key,
    required this.stickerType,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Transform.scale(
        scale: scale,
        child: Transform.rotate(
          angle: rotation,
          child: _buildSticker(stickerType),
        ),
      ),
    );
  }

  Widget _buildSticker(String type) {
    switch (type) {
      case 'heart':
        return const Icon(Icons.favorite, color: Colors.red, size: 40);
      case 'star':
        return const Icon(Icons.star, color: Colors.yellow, size: 40);
      case 'fire':
        return const Icon(Icons.local_fire_department, color: Colors.orange, size: 40);
      case 'crown':
        return const Icon(Icons.workspace_premium, color: Colors.amber, size: 40);
      case 'emoji':
        return const Text('😎', style: TextStyle(fontSize: 40));
      default:
        return Container();
    }
  }
}


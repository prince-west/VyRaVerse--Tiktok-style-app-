import 'package:flutter/material.dart';
import '../theme/vyra_theme.dart';

class GlowIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final bool glow;

  const GlowIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? VyRaTheme.primaryCyan;
    
    if (glow) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: VyRaTheme.neonGlow,
        ),
        child: Icon(icon, size: size, color: iconColor),
      );
    }
    
    return Icon(icon, size: size, color: iconColor);
  }
}


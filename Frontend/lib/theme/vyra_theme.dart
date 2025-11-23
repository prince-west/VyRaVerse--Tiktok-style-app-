import 'package:flutter/material.dart';

class VyRaTheme {
  // Primary Colors - Black & Cyan Gradient
  static const Color primaryBlack = Color(0xFF000000);
  static const Color primaryCyan = Color(0xFF00FFFF);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color darkGrey = Color(0xFF1A1A1A);
  static const Color mediumGrey = Color(0xFF2A2A2A);
  static const Color lightGrey = Color(0xFF3A3A3A);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFAAAAAA);

  // Gradient Background
  static LinearGradient get backgroundGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryBlack, darkGrey, primaryBlack],
        stops: [0.0, 0.5, 1.0],
      );

  // Neon Glow Effect
  static List<BoxShadow> get neonGlow => [
        BoxShadow(
          color: primaryCyan.withOpacity(0.5),
          blurRadius: 10,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: primaryCyan.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 4,
        ),
      ];

  // Text Styles
  static TextStyle get appTitle => const TextStyle(
        color: primaryCyan,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      );

  static TextStyle get heading => const TextStyle(
        color: textWhite,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get bodyText => const TextStyle(
        color: textWhite,
        fontSize: 14,
      );

  static TextStyle get captionText => TextStyle(
        color: textGrey,
        fontSize: 12,
      );

  // Button Styles
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: primaryCyan,
        foregroundColor: primaryBlack,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 4,
      );

  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: primaryCyan,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: const BorderSide(color: primaryCyan, width: 2),
        ),
      );

  // Reusable widget builders (consolidated from multiple screens)
  static Widget buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final widget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? primaryCyan).withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: (iconColor ?? primaryCyan).withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (iconColor ?? primaryCyan).withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: iconColor ?? primaryCyan,
            size: 22,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            color: textWhite,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: textGrey.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    return onTap != null
        ? GestureDetector(onTap: onTap, child: widget)
        : widget;
  }
}


import 'package:flutter/material.dart';

/// Extensions for Duration formatting
extension DurationExtensions on Duration {
  /// Format duration as MM:SS
  String get formattedMMSS {
    final minutes = inMinutes;
    final seconds = this.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format duration as HH:MM:SS
  String get formattedHHMMSS {
    final hours = inHours;
    final minutes = inMinutes % 60;
    final seconds = this.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return formattedMMSS;
  }

  /// Format duration as human readable (e.g., "2 minutes")
  String get formattedHuman {
    if (inDays > 0) {
      return '$inDays day${inDays > 1 ? 's' : ''}';
    }
    if (inHours > 0) {
      return '$inHours hour${inHours > 1 ? 's' : ''}';
    }
    if (inMinutes > 0) {
      return '$inMinutes minute${inMinutes > 1 ? 's' : ''}';
    }
    return '$inSeconds second${inSeconds != 1 ? 's' : ''}';
  }
}


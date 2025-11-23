/// Extensions for file size formatting
extension FileSizeExtensions on int {
  /// Format bytes as human readable (e.g., "12.5 MB")
  String get formattedFileSize {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) {
      return '${(this / 1024).toStringAsFixed(1)} KB';
    }
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Format bytes as MB
  String get formattedMB {
    return '${(this / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}


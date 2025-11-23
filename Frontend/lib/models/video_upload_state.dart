/// Video upload state model for tracking upload progress
class VideoUploadState {
  final String? videoId;
  final double progress; // 0.0 to 1.0
  final UploadStatus status;
  final String? errorMessage;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int bytesUploaded;
  final int totalBytes;

  const VideoUploadState({
    this.videoId,
    this.progress = 0.0,
    this.status = UploadStatus.idle,
    this.errorMessage,
    this.videoUrl,
    this.thumbnailUrl,
    this.bytesUploaded = 0,
    this.totalBytes = 0,
  });

  VideoUploadState copyWith({
    String? videoId,
    double? progress,
    UploadStatus? status,
    String? errorMessage,
    String? videoUrl,
    String? thumbnailUrl,
    int? bytesUploaded,
    int? totalBytes,
  }) {
    return VideoUploadState(
      videoId: videoId ?? this.videoId,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      bytesUploaded: bytesUploaded ?? this.bytesUploaded,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }

  bool get isUploading => status == UploadStatus.uploading;
  bool get isCompleted => status == UploadStatus.completed;
  bool get hasError => status == UploadStatus.error;
}

enum UploadStatus {
  idle,
  compressing,
  generatingThumbnail,
  uploading,
  completed,
  error,
  cancelled,
}


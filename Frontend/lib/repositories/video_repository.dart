import '../services/api_service.dart';
import '../models/video_item.dart';

/// Repository for video data operations
class VideoRepository {
  final ApiService _apiService = ApiService();

  /// Get all videos
  Future<List<VideoItem>> getVideos({
    String? username,
    String? privacy,
    int? limit,
    int? offset,
  }) async {
    try {
      return await _apiService.getVideos();
    } catch (e) {
      return [];
    }
  }

  /// Get recommended videos
  Future<List<VideoItem>> getRecommendedVideos() async {
    try {
      return await _apiService.getRecommendedVideos();
    } catch (e) {
      return [];
    }
  }

  /// Get video by ID
  Future<VideoItem?> getVideoById(String videoId) async {
    try {
      final videos = await _apiService.getVideos();
      return videos.firstWhere((v) => v.id == videoId);
    } catch (e) {
      return null;
    }
  }

  /// Search videos
  Future<List<VideoItem>> searchVideos(String query) async {
    try {
      return await _apiService.searchVideos(query);
    } catch (e) {
      return [];
    }
  }

  /// Like video
  Future<bool> likeVideo(String videoId) async {
    try {
      await _apiService.likeVideo(videoId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Comment on video
  Future<bool> commentVideo(String videoId, String comment) async {
    try {
      // Implement when comment API is available
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Share video
  Future<bool> shareVideo(String videoId) async {
    try {
      await _apiService.shareVideo(videoId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Buzz video
  Future<bool> buzzVideo(String videoId) async {
    try {
      return await _apiService.buzzVideo(videoId);
    } catch (e) {
      return false;
    }
  }

  /// Save video to favorites
  Future<bool> saveVideo(String videoId) async {
    try {
      await _apiService.saveVideo(videoId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Report video
  Future<bool> reportVideo(String videoId, String reason) async {
    try {
      // Implement when report API is available
      return true;
    } catch (e) {
      return false;
    }
  }
}


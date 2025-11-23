import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/vyra_theme.dart';
import '../widgets/neon_appbar.dart';
import '../models/video_item.dart' show VideoFilter, FilterType, VideoUploadState, UploadStatus;

// ============================================================================
// VIDEO UPLOAD SCREENS - Preview, caption, progress, edit
// ============================================================================

/// Screen for previewing recorded/selected video before upload
class VideoPreviewScreen extends StatefulWidget {
  final String videoPath;
  final File? thumbnailFile;

  const VideoPreviewScreen({
    super.key,
    required this.videoPath,
    this.thumbnailFile,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = File(widget.videoPath);
      if (await file.exists()) {
        _controller = VideoPlayerController.file(file);
        await _controller!.initialize();
        _controller!.setLooping(true);
        _controller!.play();
        
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      appBar: NeonAppBar(
        title: 'Preview Video',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'USE',
              style: TextStyle(
                color: VyRaTheme.primaryCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isInitialized && _controller != null
          ? Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(color: VyRaTheme.primaryCyan),
            ),
    );
  }
}

/// Screen for adding caption, hashtags, and other video details
class VideoCaptionScreen extends StatefulWidget {
  final String videoPath;
  final File? thumbnailFile;
  final Function(String description, List<String> hashtags, String? location, String privacy) onNext;

  const VideoCaptionScreen({
    super.key,
    required this.videoPath,
    this.thumbnailFile,
    required this.onNext,
  });

  @override
  State<VideoCaptionScreen> createState() => _VideoCaptionScreenState();
}

class _VideoCaptionScreenState extends State<VideoCaptionScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _privacy = 'Public';
  final List<String> _hashtags = [];
  final List<String> _suggestedHashtags = [
    'fyp', 'viral', 'trending', 'fun', 'dance', 'comedy',
    'music', 'art', 'food', 'fashion', 'lifestyle', 'fitness',
  ];

  @override
  void dispose() {
    _captionController.dispose();
    _hashtagController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _addHashtag(String hashtag) {
    if (!_hashtags.contains(hashtag)) {
      setState(() {
        _hashtags.add(hashtag);
      });
    }
  }

  void _removeHashtag(String hashtag) {
    setState(() {
      _hashtags.remove(hashtag);
    });
  }

  void _handleNext() {
    widget.onNext(
      _captionController.text,
      _hashtags,
      _locationController.text.isEmpty ? null : _locationController.text,
      _privacy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      appBar: NeonAppBar(
        title: 'Add Details',
        actions: [
          TextButton(
            onPressed: _handleNext,
            child: const Text(
              'POST',
              style: TextStyle(
                color: VyRaTheme.primaryCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caption
            TextField(
              controller: _captionController,
              maxLines: 5,
              style: const TextStyle(color: VyRaTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'Write a caption...',
                hintStyle: const TextStyle(color: VyRaTheme.textGrey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VyRaTheme.darkGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VyRaTheme.primaryCyan),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Hashtags
            const Text(
              'Hashtags',
              style: TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hashtags.map((tag) => Chip(
                label: Text('#$tag'),
                onDeleted: () => _removeHashtag(tag),
                backgroundColor: VyRaTheme.darkGrey,
                deleteIconColor: VyRaTheme.primaryCyan,
              )).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hashtagController,
              style: const TextStyle(color: VyRaTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'Add hashtag...',
                hintStyle: const TextStyle(color: VyRaTheme.textGrey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VyRaTheme.darkGrey),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, color: VyRaTheme.primaryCyan),
                  onPressed: () {
                    final tag = _hashtagController.text.trim().replaceAll('#', '');
                    if (tag.isNotEmpty) {
                      _addHashtag(tag);
                      _hashtagController.clear();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Suggested',
              style: TextStyle(color: VyRaTheme.textGrey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestedHashtags
                  .where((tag) => !_hashtags.contains(tag))
                  .map((tag) => ActionChip(
                        label: Text('#$tag'),
                        onPressed: () => _addHashtag(tag),
                        backgroundColor: VyRaTheme.darkGrey,
                        labelStyle: const TextStyle(color: VyRaTheme.textWhite),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            
            // Location
            TextField(
              controller: _locationController,
              style: const TextStyle(color: VyRaTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'Add location (optional)',
                hintStyle: const TextStyle(color: VyRaTheme.textGrey),
                prefixIcon: const Icon(Icons.location_on, color: VyRaTheme.primaryCyan),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VyRaTheme.darkGrey),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Privacy
            const Text(
              'Privacy',
              style: TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...['Public', 'Friends', 'Private'].map((option) => RadioListTile<String>(
              title: Text(option, style: const TextStyle(color: VyRaTheme.textWhite)),
              value: option,
              groupValue: _privacy,
              onChanged: (value) => setState(() => _privacy = value!),
              activeColor: VyRaTheme.primaryCyan,
            )),
          ],
        ),
      ),
    );
  }
}

/// Screen showing video upload progress
class VideoUploadProgressScreen extends StatelessWidget {
  final VideoUploadState uploadState;
  final VoidCallback? onCancel;

  const VideoUploadProgressScreen({
    super.key,
    required this.uploadState,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      appBar: NeonAppBar(
        title: _getTitle(),
        actions: uploadState.isUploading
            ? [
                TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Progress indicator
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: uploadState.progress,
                      strokeWidth: 8,
                      color: VyRaTheme.primaryCyan,
                      backgroundColor: VyRaTheme.darkGrey,
                    ),
                    Text(
                      '${(uploadState.progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: VyRaTheme.textWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Status text
              Text(
                _getStatusText(),
                style: const TextStyle(
                  color: VyRaTheme.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Status message
              if (uploadState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    uploadState.errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Progress bar
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: uploadState.progress,
                  minHeight: 8,
                  backgroundColor: VyRaTheme.darkGrey,
                  valueColor: const AlwaysStoppedAnimation<Color>(VyRaTheme.primaryCyan),
                ),
              ),
              
              // Upload stats
              if (uploadState.totalBytes > 0) ...[
                const SizedBox(height: 24),
                Text(
                  '${(uploadState.bytesUploaded / (1024 * 1024)).toStringAsFixed(2)} MB / ${(uploadState.totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
                  style: const TextStyle(
                    color: VyRaTheme.textGrey,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (uploadState.status) {
      case UploadStatus.compressing:
        return 'Compressing';
      case UploadStatus.generatingThumbnail:
        return 'Generating Thumbnail';
      case UploadStatus.uploading:
        return 'Uploading';
      case UploadStatus.completed:
        return 'Upload Complete';
      case UploadStatus.error:
        return 'Upload Failed';
      default:
        return 'Upload';
    }
  }

  String _getStatusText() {
    switch (uploadState.status) {
      case UploadStatus.compressing:
        return 'Compressing your video...';
      case UploadStatus.generatingThumbnail:
        return 'Creating thumbnail...';
      case UploadStatus.uploading:
        return 'Uploading your video...';
      case UploadStatus.completed:
        return 'Your video has been uploaded!';
      case UploadStatus.error:
        return 'Upload failed. Please try again.';
      default:
        return 'Preparing upload...';
    }
  }
}

/// Screen for editing video (trim, filters, effects)
class VideoEditScreen extends StatefulWidget {
  final String videoPath;
  final Function(String editedPath)? onSave;

  const VideoEditScreen({
    super.key,
    required this.videoPath,
    this.onSave,
  });

  @override
  State<VideoEditScreen> createState() => _VideoEditScreenState();
}

class _VideoEditScreenState extends State<VideoEditScreen> {
  VideoPlayerController? _controller;
  VideoFilter _selectedFilter = VideoFilter.defaultFilters.first;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = File(widget.videoPath);
      if (await file.exists()) {
        _controller = VideoPlayerController.file(file);
        await _controller!.initialize();
        _controller!.setLooping(true);
        _controller!.play();
        
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _applyFilter(VideoFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
    // Filter application would be implemented with video processing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      appBar: NeonAppBar(
        title: 'Edit Video',
        actions: [
          TextButton(
            onPressed: () {
              widget.onSave?.call(widget.videoPath);
              Navigator.pop(context);
            },
            child: const Text(
              'DONE',
              style: TextStyle(
                color: VyRaTheme.primaryCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Video preview
          Expanded(
            child: _isInitialized && _controller != null
                ? Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: VyRaTheme.primaryCyan),
                  ),
          ),
          
          // Filters carousel
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: VideoFilter.defaultFilters.length,
              itemBuilder: (context, index) {
                final filter = VideoFilter.defaultFilters[index];
                final isSelected = filter.id == _selectedFilter.id;
                
                return GestureDetector(
                  onTap: () => _applyFilter(filter),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? VyRaTheme.primaryCyan : VyRaTheme.darkGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? VyRaTheme.primaryCyan : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter,
                          color: isSelected ? VyRaTheme.primaryBlack : VyRaTheme.textWhite,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          filter.displayName,
                          style: TextStyle(
                            color: isSelected ? VyRaTheme.primaryBlack : VyRaTheme.textWhite,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


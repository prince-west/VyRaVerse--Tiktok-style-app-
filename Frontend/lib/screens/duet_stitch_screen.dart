import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:camera/camera.dart';
import '../theme/vyra_theme.dart';
import '../models/video_item.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import '../services/video_compression_service.dart';
import '../services/video_helper_services.dart' show ThumbnailGeneratorService, VideoPermissionService;
import '../widgets/duet_layout_widget.dart';

/// Duet and Stitch screen for creating collaborative videos
/// Duet: Split-screen recording with original video
/// Stitch: Use clip from original video
class DuetStitchScreen extends StatefulWidget {
  final VideoItem originalVideo;
  final String mode; // 'duet' or 'stitch'

  const DuetStitchScreen({
    super.key,
    required this.originalVideo,
    required this.mode,
  });

  @override
  State<DuetStitchScreen> createState() => _DuetStitchScreenState();
}

class _DuetStitchScreenState extends State<DuetStitchScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  VideoPlayerController? _originalVideoController;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  File? _recordedVideo;
  File? _finalVideo;
  File? _thumbnail;
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  static const int maxVideoDuration = 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeOriginalVideo();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _cameraController?.dispose();
    _originalVideoController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeOriginalVideo() async {
    if (widget.originalVideo.videoUrl == null) return;

    try {
      _originalVideoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.originalVideo.videoUrl!),
      );
      await _originalVideoController!.initialize();
      _originalVideoController!.setLooping(true);
      _originalVideoController!.play();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading original video: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Check permissions using service
      final hasPermissions = await VideoPermissionService.hasVideoPermissions();
      if (!hasPermissions) {
        final granted = await VideoPermissionService.requestVideoPermissions();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera and microphone permissions are required'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pop(context);
          }
          return;
        }
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startRecording() async {
    if (_isRecording || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final path = (await getTemporaryDirectory()).path;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$path/duet_${widget.mode}_$timestamp.mp4';

      await _cameraController!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration = Duration(seconds: timer.tick);
          });

          if (_recordingDuration.inSeconds >= maxVideoDuration) {
            _stopRecording();
          }
        }
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _cameraController == null) return;

    _recordingTimer?.cancel();

    try {
      final file = await _cameraController!.stopVideoRecording();

      setState(() {
        _isRecording = false;
        _recordedVideo = File(file.path);
      });

      await _processVideo();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processVideo() async {
    if (_recordedVideo == null) return;

    setState(() {
      _isProcessing = true;
      _processingProgress = 0.0;
    });

    try {
      // Use compression service
      final compressionResult = await VideoCompressionService.compressVideo(
        videoPath: _recordedVideo!.path,
        targetSizeBytes: 20 * 1024 * 1024, // 20MB
      );

      if (compressionResult == null || !compressionResult.success) {
        throw Exception(compressionResult?.errorMessage ?? 'Video compression failed');
      }

      setState(() {
        _processingProgress = 0.5;
      });

      // Generate thumbnail using service
      final thumbnailFile = await ThumbnailGeneratorService.generateThumbnail(
        videoPath: compressionResult.path,
        timeMs: 3000,
        quality: 75,
      );

      setState(() {
        _finalVideo = compressionResult.compressedFile;
        _thumbnail = thumbnailFile;
        _isProcessing = false;
        _processingProgress = 1.0;
      });

      // Navigate to upload screen with the video
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/upload',
          arguments: {
            'videoFile': compressionResult.compressedFile,
            'thumbnailFile': thumbnailFile,
            'collabType': widget.mode,
            'originalVideoId': widget.originalVideo.id,
          },
        );
      }
    } catch (e) {
      debugPrint('Error processing video: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleCamera() {
    if (_cameras.length < 2) return;

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });

    _cameraController?.dispose();
    _initializeCamera();
  }

  void _cancel() {
    _recordingTimer?.cancel();
    if (_isRecording) {
      _cameraController?.stopVideoRecording();
    }
    Navigator.pop(context);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(
            color: VyRaTheme.primaryCyan,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Duet layout: Split screen
          if (widget.mode == 'duet')
            Row(
              children: [
                // Original video (left side)
                Expanded(
                  child: _originalVideoController != null &&
                          _originalVideoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _originalVideoController!.value.aspectRatio,
                          child: VideoPlayer(_originalVideoController!),
                        )
                      : Container(
                          color: VyRaTheme.primaryBlack,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: VyRaTheme.primaryCyan,
                            ),
                          ),
                        ),
                ),
                // Divider
                Container(width: 2, color: Colors.white),
                // Camera preview (right side)
                Expanded(
                  child: CameraPreview(_cameraController!),
                ),
              ],
            )
          // Stitch layout: Full screen camera with original video overlay
          else
            Stack(
              children: [
                // Camera preview (full screen)
                SizedBox.expand(
                  child: CameraPreview(_cameraController!),
                ),
                // Original video overlay (small preview)
                if (_originalVideoController != null &&
                    _originalVideoController!.value.isInitialized)
                  Positioned(
                    top: 60,
                    right: 16,
                    child: Container(
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: VyRaTheme.primaryCyan, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: _originalVideoController!.value.aspectRatio,
                          child: VideoPlayer(_originalVideoController!),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          // Recording timer
          if (_isRecording)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatDuration(_recordingDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top actions
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _cancel,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                  Text(
                    widget.mode == 'duet' ? 'Duet' : 'Stitch',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 40), // Balance
                ],
              ),
            ),
          ),

          // Bottom actions
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Camera flip button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _toggleCamera,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flip_camera_ios,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Record button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (!_isRecording) {
                            _startRecording();
                          } else {
                            _stopRecording();
                          }
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording ? Colors.red : Colors.white,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: _isRecording
                              ? const Icon(Icons.stop, color: Colors.white, size: 32)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Progress indicator
                  if (_isRecording)
                    Container(
                      width: double.infinity,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _recordingDuration.inSeconds / maxVideoDuration,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: VyRaTheme.primaryCyan,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Processing video...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _processingProgress,
                      backgroundColor: Colors.grey,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        VyRaTheme.primaryCyan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

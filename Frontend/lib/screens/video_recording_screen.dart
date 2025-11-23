import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
// Removed direct imports - using services instead
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/vyra_theme.dart';
import '../services/video_cache_service.dart';
import '../services/video_helper_services.dart' show VideoPermissionService, ThumbnailGeneratorService;
import '../services/video_compression_service.dart';
import '../widgets/video_recording_controls.dart';

/// Enhanced video recording screen with standard camera package
/// Features: 60s limit, pause/resume, front/back camera, compression
class VideoRecordingScreen extends StatefulWidget {
  final Function(File videoFile, File? thumbnailFile)? onVideoRecorded;

  const VideoRecordingScreen({
    super.key,
    this.onVideoRecorded,
  });

  @override
  State<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  bool _flashEnabled = false;
  File? _finalVideo;
  File? _thumbnail;
  bool _isCompressing = false;
  double _compressionProgress = 0.0;
  static const int maxVideoDuration = 60; // 60 seconds max

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
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

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Initialize camera controller
      _controller = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

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
        Navigator.pop(context);
      }
    }
  }

  void _startRecording() async {
    if (_isRecording || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final path = (await getTemporaryDirectory()).path;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$path/video_$timestamp.mp4';

      await _controller!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _isPaused = false;
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
    if (!_isRecording || _controller == null) return;

    _recordingTimer?.cancel();

    try {
      final file = await _controller!.stopVideoRecording();

      setState(() {
        _isRecording = false;
        _isPaused = false;
        _finalVideo = File(file.path);
      });

      // Compress video and generate thumbnail
      await _compressAndGenerateThumbnail(_finalVideo!);
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

  Future<void> _compressAndGenerateThumbnail(File videoFile) async {
    setState(() {
      _isCompressing = true;
      _compressionProgress = 0.0;
    });

    try {
      // Use compression service
      final compressionResult = await VideoCompressionService.compressVideo(
        videoPath: videoFile.path,
        targetSizeBytes: 20 * 1024 * 1024, // 20MB
      );

      if (compressionResult == null || !compressionResult.success) {
        throw Exception(compressionResult?.errorMessage ?? 'Video compression failed');
      }

      setState(() {
        _compressionProgress = 0.5;
      });

      // Generate thumbnail using service
      final thumbnailFile = await ThumbnailGeneratorService.generateThumbnail(
        videoPath: compressionResult.path,
        timeMs: 3000, // 3 seconds
        quality: 75,
      );

      setState(() {
        _finalVideo = compressionResult.compressedFile;
        _thumbnail = thumbnailFile;
        _isCompressing = false;
        _compressionProgress = 1.0;
      });

      // Return to upload screen with video and thumbnail
      if (mounted && widget.onVideoRecorded != null) {
        widget.onVideoRecorded!(compressionResult.compressedFile, thumbnailFile);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error compressing video: $e');
      if (mounted) {
        setState(() => _isCompressing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleFlash() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _flashEnabled = !_flashEnabled;
    });

    _controller!.setFlashMode(
      _flashEnabled ? FlashMode.torch : FlashMode.off,
    );
  }

  void _toggleCamera() {
    if (_cameras.length < 2) return;

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });

    _controller?.dispose();
    _initializeCamera();
  }

  void _cancelRecording() {
    _recordingTimer?.cancel();
    if (_isRecording) {
      _controller?.stopVideoRecording();
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
    if (_controller == null || !_controller!.value.isInitialized) {
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
          // Camera preview
          SizedBox.expand(
            child: CameraPreview(_controller!),
          ),

          // Recording timer overlay
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
                  // Close button
                  GestureDetector(
                    onTap: _cancelRecording,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // Flash toggle
                  GestureDetector(
                    onTap: _toggleFlash,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _flashEnabled ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
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
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
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

          // Compression progress overlay
          if (_isCompressing)
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
                      'Compressing video...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _compressionProgress,
                      backgroundColor: Colors.grey,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        VyRaTheme.primaryCyan,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(_compressionProgress * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white),
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

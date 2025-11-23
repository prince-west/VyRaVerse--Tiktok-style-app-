import 'package:flutter/material.dart';
import '../theme/vyra_theme.dart';

/// Recording controls widget (record button, timer, flip camera)
class VideoRecordingControls extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final Duration recordingDuration;
  final VoidCallback? onRecord;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onFlipCamera;
  final VoidCallback? onFlashToggle;
  final bool flashEnabled;

  const VideoRecordingControls({
    super.key,
    required this.isRecording,
    this.isPaused = false,
    required this.recordingDuration,
    this.onRecord,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onFlipCamera,
    this.onFlashToggle,
    this.flashEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer
        if (isRecording)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(recordingDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        
        // Control buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Flip camera
            if (onFlipCamera != null)
              _buildControlButton(
                icon: Icons.flip_camera_ios,
                onTap: onFlipCamera,
              ),
            
            // Record/Stop button
            GestureDetector(
              onTap: isRecording ? onStop : onRecord,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording ? Colors.red : Colors.white,
                  border: Border.all(
                    color: isRecording ? Colors.red : Colors.white,
                    width: 4,
                  ),
                ),
                child: isRecording
                    ? const Icon(Icons.stop, color: Colors.white, size: 32)
                    : const Icon(Icons.fiber_manual_record, color: Colors.red, size: 32),
              ),
            ),
            
            // Flash toggle
            if (onFlashToggle != null)
              _buildControlButton(
                icon: flashEnabled ? Icons.flash_on : Icons.flash_off,
                onTap: onFlashToggle,
              ),
          ],
        ),
        
        // Pause/Resume button
        if (isRecording) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: isPaused ? onResume : onPause,
            icon: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              color: VyRaTheme.primaryCyan,
            ),
            label: Text(
              isPaused ? 'Resume' : 'Pause',
              style: const TextStyle(color: VyRaTheme.primaryCyan),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}


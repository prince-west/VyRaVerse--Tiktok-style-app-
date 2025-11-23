import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/vyra_theme.dart';

/// Split-screen layout widget for duet videos
class DuetLayoutWidget extends StatelessWidget {
  final VideoPlayerController? originalVideoController;
  final Widget? recordingPreview;
  final bool isRecording;

  const DuetLayoutWidget({
    super.key,
    this.originalVideoController,
    this.recordingPreview,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Original video (left side)
        Expanded(
          child: Container(
            color: VyRaTheme.primaryBlack,
            child: originalVideoController != null &&
                    originalVideoController!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: originalVideoController!.value.aspectRatio,
                    child: VideoPlayer(originalVideoController!),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      color: VyRaTheme.primaryCyan,
                    ),
                  ),
          ),
        ),
        
        // Divider
        Container(
          width: 2,
          color: VyRaTheme.darkGrey,
        ),
        
        // Recording preview (right side)
        Expanded(
          child: Container(
            color: VyRaTheme.primaryBlack,
            child: recordingPreview ??
                (isRecording
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: VyRaTheme.primaryCyan,
                        ),
                      )
                    : Container(
                        color: VyRaTheme.darkGrey,
                        child: const Center(
                          child: Icon(
                            Icons.videocam,
                            color: VyRaTheme.textGrey,
                            size: 48,
                          ),
                        ),
                      )),
          ),
        ),
      ],
    );
  }
}


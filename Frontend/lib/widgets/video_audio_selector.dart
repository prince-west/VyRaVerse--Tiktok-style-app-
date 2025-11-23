import 'package:flutter/material.dart';
import '../theme/vyra_theme.dart';
import '../models/audio_track.dart';

/// Widget for selecting background music/audio
class VideoAudioSelector extends StatelessWidget {
  final List<AudioTrack> audioTracks;
  final AudioTrack? selectedTrack;
  final Function(AudioTrack) onTrackSelected;
  final Function(AudioTrack)? onPreview;

  const VideoAudioSelector({
    super.key,
    required this.audioTracks,
    this.selectedTrack,
    required this.onTrackSelected,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: VyRaTheme.darkGrey,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: VyRaTheme.textGrey.withOpacity(0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Sound',
                  style: TextStyle(
                    color: VyRaTheme.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: VyRaTheme.textWhite),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Audio tracks list
          Expanded(
            child: ListView.builder(
              itemCount: audioTracks.length,
              itemBuilder: (context, index) {
                final track = audioTracks[index];
                final isSelected = selectedTrack?.id == track.id;
                
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: VyRaTheme.primaryBlack,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: track.coverImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              track.coverImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.music_note,
                            color: VyRaTheme.primaryCyan,
                          ),
                  ),
                  title: Text(
                    track.title,
                    style: TextStyle(
                      color: isSelected ? VyRaTheme.primaryCyan : VyRaTheme.textWhite,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    track.artist ?? 'Unknown Artist',
                    style: const TextStyle(color: VyRaTheme.textGrey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onPreview != null)
                        IconButton(
                          icon: const Icon(Icons.play_arrow, color: VyRaTheme.primaryCyan),
                          onPressed: () => onPreview!(track),
                        ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: VyRaTheme.primaryCyan,
                        ),
                    ],
                  ),
                  onTap: () => onTrackSelected(track),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


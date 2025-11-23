import 'package:flutter/material.dart';
import '../theme/vyra_theme.dart';
import '../models/video_item.dart' show VideoFilter, FilterType;

/// Carousel widget for video filters
class VideoFiltersCarousel extends StatelessWidget {
  final VideoFilter selectedFilter;
  final Function(VideoFilter) onFilterSelected;
  final List<VideoFilter> filters;

  const VideoFiltersCarousel({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.filters = VideoFilter.defaultFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter.id == selectedFilter.id;

          return GestureDetector(
            onTap: () => onFilterSelected(filter),
            child: Container(
              width: 70,
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
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    filter.displayName,
                    style: TextStyle(
                      color: isSelected ? VyRaTheme.primaryBlack : VyRaTheme.textWhite,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


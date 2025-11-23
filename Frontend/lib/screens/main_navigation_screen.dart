import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_feed_screen.dart';
import 'vyra_mart_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'upload_screen.dart';
import 'search_screen.dart';
import '../theme/vyra_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey<State<HomeFeedScreen>> _homeScreenKey = GlobalKey<State<HomeFeedScreen>>();

  late final List<Widget> _screens = [
    HomeFeedScreen(key: _homeScreenKey),      // 0: Feed
    const VyRaMartScreen(),       // 1: VyRaMart
    const ChatScreen(),          // 2: Chat
    const ProfileScreen(),       // 3: Profile
  ];

  void _onTabTapped(int index) {
    // Pause videos when navigating away from home (index 0)
    if (index != 0 && _currentIndex == 0) {
      final homeState = _homeScreenKey.currentState;
      if (homeState != null && homeState.mounted) {
        try {
          (homeState as dynamic).pauseAllVideos();
        } catch (e) {
          debugPrint('Error pausing videos on tab tap: $e');
        }
      }
    }
    
    if (index == 2) {
      Navigator.pushNamed(context, '/upload').then((uploaded) {
        // Refresh home screen if video was uploaded
        if (uploaded == true) {
          final state = _homeScreenKey.currentState;
          if (state != null && state.mounted) {
            // Call loadVideos using dynamic dispatch
            (state as dynamic).loadVideos();
          }
        }
      });
    } else {
      final screenIndex = index > 2 ? index - 1 : index;
      if (screenIndex >= 0 && screenIndex < _screens.length) {
        setState(() {
          _currentIndex = index;
        });
        _pageController.jumpToPage(screenIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          final navIndex = index >= 2 ? index + 1 : index;
          setState(() {
            _currentIndex = navIndex;
          });
          // Pause all videos when navigating away from home screen (index 0)
          if (index != 0) {
            final homeState = _homeScreenKey.currentState;
            if (homeState != null && homeState.mounted) {
              try {
                (homeState as dynamic).pauseAllVideos();
              } catch (e) {
                debugPrint('Error pausing videos: $e');
              }
            }
          }
        },
        children: _screens,
      ),
      bottomNavigationBar: VyRaBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}


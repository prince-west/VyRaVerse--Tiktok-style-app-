import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'splash_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'screens/upload_screen.dart' show UploadScreen, SoundsLibraryScreen;
import 'screens/chat_screen.dart';
import 'screens/vyra_mart_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/followers_screen.dart';
import 'screens/clubs_screen.dart';
import 'screens/challenges_screen.dart';
import 'screens/universe_map_screen.dart';
import 'screens/find_friends_screen.dart';
import 'screens/home_feed_screen.dart';
import 'screens/business_page_screen.dart';
import 'theme/vyra_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const VyRaVerseApp());
}

class VyRaVerseApp extends StatelessWidget {
  const VyRaVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VyRaVerse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: VyRaTheme.primaryCyan,
        scaffoldBackgroundColor: VyRaTheme.primaryBlack,
        colorScheme: const ColorScheme.dark(
          primary: VyRaTheme.primaryCyan,
          secondary: VyRaTheme.accentCyan,
          surface: VyRaTheme.darkGrey,
          background: VyRaTheme.primaryBlack,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: VyRaTheme.primaryBlack,
          elevation: 0,
          iconTheme: IconThemeData(color: VyRaTheme.textWhite),
          titleTextStyle: TextStyle(
            color: VyRaTheme.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: VyRaTheme.primaryBlack,
          selectedItemColor: VyRaTheme.primaryCyan,
          unselectedItemColor: VyRaTheme.textGrey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainNavigationScreen(),
        '/profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return ProfileScreen(
            username: args?['username'] as String?,
            userId: args?['userId'] as String?,
            isViewingOther: args?['isViewingOther'] as bool? ?? false,
          );
        },
        '/search': (context) => const SearchScreen(),
        '/upload': (context) => const UploadScreen(),
        '/chat': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return ChatScreen(
            userId: args?['userId'] as String?,
            username: args?['username'] as String?,
          );
        },
        '/battles': (context) => const HomeFeedScreen(), // Swipe right from feed to access battles
        '/mart': (context) => const VyRaMartScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/followers': (context) => const FollowersScreen(),
        '/clubs': (context) => const ClubsScreen(),
        '/club-feed': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return ClubFeedScreen(
            clubId: args?['clubId'] as String? ?? '',
            clubName: args?['clubName'] as String? ?? 'Club Feed',
          );
        },
        '/challenges': (context) => const ChallengesScreen(),
        '/universe-map': (context) => const UniverseMapScreen(),
        '/sounds': (context) => SoundsLibraryScreen(),
        '/find-friends': (context) => const FindFriendsScreen(),
        '/business-page': (context) => const BusinessPageScreen(),
      },
    );
  }
}


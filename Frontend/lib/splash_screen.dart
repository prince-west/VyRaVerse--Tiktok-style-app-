import 'package:flutter/material.dart';
import 'screen_helper.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    final isLoggedIn = await _authService.isLoggedIn();
    
    if (mounted) {
      if (!hasSeenOnboarding) {
        await prefs.setBool('has_seen_onboarding', true);
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        Navigator.pushReplacementNamed(
          context,
          isLoggedIn ? '/home' : '/signin',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = ScreenHelper.screenWidth(context);
    final height = ScreenHelper.screenHeight(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: Center(
        child: Image.asset(
          'assets/images/splashh.jpg', // make sure this image exists
          width: width * 0.8,
          height: height * 0.4,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

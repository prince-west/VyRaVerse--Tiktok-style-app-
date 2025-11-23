import 'package:flutter/material.dart';
import '../theme/vyra_theme.dart';

class VyRaBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const VyRaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VyRaTheme.primaryBlack,
        border: const Border(
          top: BorderSide(color: VyRaTheme.lightGrey, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: VyRaTheme.primaryCyan.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          selectedItemColor: VyRaTheme.primaryCyan,
          unselectedItemColor: VyRaTheme.textGrey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: _buildGlowIcon(Icons.home, currentIndex == 0),
              activeIcon: _buildGlowIcon(Icons.home, true),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: _buildGlowIcon(Icons.shopping_bag, currentIndex == 1),
              activeIcon: _buildGlowIcon(Icons.shopping_bag, true),
              label: 'VyRaMart',
            ),
            BottomNavigationBarItem(
              icon: _buildGlowIcon(Icons.add_circle_outline, currentIndex == 2),
              activeIcon: _buildGlowIcon(Icons.add_circle, true),
              label: 'Add',
            ),
            BottomNavigationBarItem(
              icon: _buildGlowIcon(Icons.chat_bubble_outline, currentIndex == 3),
              activeIcon: _buildGlowIcon(Icons.chat_bubble_outline, true),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: _buildGlowIcon(Icons.person, currentIndex == 4),
              activeIcon: _buildGlowIcon(Icons.person, true),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowIcon(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: isActive
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: VyRaTheme.neonGlow,
            )
          : null,
      child: Icon(icon, size: 24),
    );
  }
}


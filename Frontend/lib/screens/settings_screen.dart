import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vyra_theme.dart';
import '../services/auth_service.dart';
import '../services/local_storage.dart';
import 'signin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final LocalStorageService _storage = LocalStorageService();
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedTheme = 'Black-Cyan';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: VyRaTheme.primaryBlack,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: VyRaTheme.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: VyRaTheme.darkGrey,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: VyRaTheme.textWhite, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionHeader('Account'),
            _buildSettingTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: 'Update your profile information',
              onTap: () {
                // Navigate to edit profile
              },
            ),
            _buildSettingTile(
              icon: Icons.lock_outline,
              title: 'Privacy & Security',
              subtitle: 'Manage your privacy settings',
              onTap: () {
                // Navigate to privacy settings
              },
            ),
            _buildSettingTile(
              icon: Icons.block,
              title: 'Blocked Users',
              subtitle: 'Manage blocked accounts',
              onTap: () {
                // Navigate to blocked users
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Notifications'),
            _buildSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications',
              subtitle: 'Receive push notifications',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
            ),
            _buildSwitchTile(
              icon: Icons.volume_up_outlined,
              title: 'Sound',
              subtitle: 'Play sounds for notifications',
              value: _soundEnabled,
              onChanged: (value) {
                setState(() => _soundEnabled = value);
              },
            ),
            _buildSwitchTile(
              icon: Icons.vibration,
              title: 'Vibration',
              subtitle: 'Vibrate for notifications',
              value: _vibrationEnabled,
              onChanged: (value) {
                setState(() => _vibrationEnabled = value);
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Appearance'),
            _buildSettingTile(
              icon: Icons.palette_outlined,
              title: 'Theme',
              subtitle: _selectedTheme,
              trailing: const Icon(
                Icons.chevron_right,
                color: VyRaTheme.textGrey,
              ),
              onTap: () {
                _showThemeSelector();
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('About'),
            _buildSettingTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.0',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () {
                // Navigate to help
              },
            ),
            _buildSettingTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'Read our terms and conditions',
              onTap: () {
                // Navigate to terms
              },
            ),
            _buildSettingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () {
                // Navigate to privacy policy
              },
            ),
            const SizedBox(height: 32),
            _buildLogoutButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: VyRaTheme.primaryCyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(
          begin: -0.1,
          end: 0,
          duration: 300.ms,
        );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: VyRaTheme.darkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: VyRaTheme.primaryCyan.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: VyRaTheme.primaryCyan.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: VyRaTheme.primaryCyan, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: VyRaTheme.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  color: VyRaTheme.textGrey,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing ??
            const Icon(
              Icons.chevron_right,
              color: VyRaTheme.textGrey,
            ),
        onTap: onTap,
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(
          begin: 0.1,
          end: 0,
          duration: 300.ms,
        );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: VyRaTheme.darkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: VyRaTheme.primaryCyan.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: VyRaTheme.primaryCyan.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: VyRaTheme.primaryCyan, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: VyRaTheme.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  color: VyRaTheme.textGrey,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: VyRaTheme.primaryCyan,
          activeTrackColor: VyRaTheme.primaryCyan.withOpacity(0.5),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(
          begin: 0.1,
          end: 0,
          duration: 300.ms,
        );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 400.ms,
        );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VyRaTheme.darkGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: VyRaTheme.primaryCyan,
            width: 2,
          ),
        ),
        title: const Text(
          'Log Out',
          style: TextStyle(color: VyRaTheme.textWhite),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: VyRaTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: VyRaTheme.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/signin',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VyRaTheme.darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Theme',
              style: TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildThemeOption('Black-Cyan', 'Default neon theme'),
            _buildThemeOption('Dark Purple', 'Purple gradient theme'),
            _buildThemeOption('Dark Blue', 'Blue gradient theme'),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String theme, String description) {
    final isSelected = _selectedTheme == theme;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTheme = theme);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? VyRaTheme.primaryCyan.withOpacity(0.2)
              : VyRaTheme.primaryBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? VyRaTheme.primaryCyan
                : VyRaTheme.lightGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme,
                    style: TextStyle(
                      color: isSelected
                          ? VyRaTheme.primaryCyan
                          : VyRaTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: VyRaTheme.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: VyRaTheme.primaryCyan,
              ),
          ],
        ),
      ),
    );
  }
}


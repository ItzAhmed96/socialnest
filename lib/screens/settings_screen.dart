import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firebase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  bool _studyReminders = false;
  String _selectedLanguage = 'English';
  String _privacySetting = 'Public';

  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];
  final List<String> _privacyOptions = ['Public', 'Friends Only', 'Private'];

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF7C3AED),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<FirebaseService>(context, listen: false).signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Account deletion feature coming soon!');
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsCard(
            children: [
              _buildSettingsItem(
                icon: Icons.person_rounded,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () {
                  _showSnackBar('Navigate to Edit Profile');
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.email_rounded,
                title: 'Change Email',
                subtitle: 'Update your email address',
                onTap: () {
                  _showChangeEmailDialog();
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.lock_rounded,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () {
                  _showChangePasswordDialog();
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Preferences Section
          _buildSectionHeader('Preferences'),
          _buildSettingsCard(
            children: [
              _buildSwitchSetting(
                icon: Icons.notifications_rounded,
                title: 'Push Notifications',
                subtitle: 'Receive app notifications',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _showSnackBar(value ? 'Notifications enabled' : 'Notifications disabled');
                },
              ),
              _buildDivider(),
              _buildSwitchSetting(
                icon: Icons.dark_mode_rounded,
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() => _darkModeEnabled = value);
                  _showSnackBar(value ? 'Dark mode enabled' : 'Dark mode disabled');
                },
              ),
              _buildDivider(),
              _buildSwitchSetting(
                icon: Icons.school_rounded,
                title: 'Study Reminders',
                subtitle: 'Daily study reminders',
                value: _studyReminders,
                onChanged: (value) {
                  setState(() => _studyReminders = value);
                  _showSnackBar(value ? 'Study reminders enabled' : 'Study reminders disabled');
                },
              ),
              _buildDivider(),
              _buildDropdownSetting(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'App language',
                value: _selectedLanguage,
                items: _languages,
                onChanged: (value) {
                  setState(() => _selectedLanguage = value!);
                  _showSnackBar('Language changed to $value');
                },
              ),
              _buildDivider(),
              _buildDropdownSetting(
                icon: Icons.visibility_rounded,
                title: 'Privacy',
                subtitle: 'Profile visibility',
                value: _privacySetting,
                items: _privacyOptions,
                onChanged: (value) {
                  setState(() => _privacySetting = value!);
                  _showSnackBar('Privacy set to $value');
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingsCard(
            children: [
              _buildSettingsItem(
                icon: Icons.help_rounded,
                title: 'Help & Support',
                subtitle: 'Get help using SocialNest',
                onTap: () {
                  _showSnackBar('Help & Support');
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.description_rounded,
                title: 'Terms of Service',
                subtitle: 'View our terms and conditions',
                onTap: () {
                  _showSnackBar('Terms of Service');
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.security_rounded,
                title: 'Privacy Policy',
                subtitle: 'Learn about our privacy practices',
                onTap: () {
                  _showSnackBar('Privacy Policy');
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.bug_report_rounded,
                title: 'Report a Bug',
                subtitle: 'Found an issue? Let us know',
                onTap: () {
                  _showReportBugDialog();
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildSettingsCard(
            children: [
              _buildSettingsItem(
                icon: Icons.info_rounded,
                title: 'About SocialNest',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  _showAboutDialog();
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Danger Zone
          _buildSectionHeader('Danger Zone'),
          _buildSettingsCard(
            children: [
              _buildDangerItem(
                icon: Icons.logout_rounded,
                title: 'Log Out',
                subtitle: 'Sign out of your account',
                onTap: _showLogoutDialog,
              ),
              _buildDivider(),
              _buildDangerItem(
                icon: Icons.delete_forever_rounded,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                onTap: _showDeleteAccountDialog,
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }

  Widget _buildDangerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.red, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
      onTap: onTap,
    );
  }

  Widget _buildSwitchSetting({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF7C3AED),
      ),
    );
  }

  Widget _buildDropdownSetting({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF1E293B),
        style: const TextStyle(color: Colors.white),
        underline: const SizedBox(),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  // Dialog Methods
  void _showChangeEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Email',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'New Email',
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF94A3B8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSnackBar('Email change request sent!');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                      child: const Text('Update'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF94A3B8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSnackBar('Password updated successfully!');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                      child: const Text('Update'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportBugDialog() {
    final TextEditingController bugController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Report a Bug',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: bugController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Describe the issue',
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF94A3B8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (bugController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          _showSnackBar('Bug report submitted! Thank you.');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'SocialNest',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'A social learning platform for students to connect, share knowledge, and grow together.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
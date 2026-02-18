import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/app_models.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance'),
          
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark theme'),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),

          const Divider(),

          // Account Section
          _buildSectionHeader('Account'),

          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.appUser;
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person, color: AppTheme.primaryColor),
                    title: const Text('Full Name'),
                    subtitle: Text(user?.fullName ?? 'Not available'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email, color: AppTheme.primaryColor),
                    title: const Text('Email'),
                    subtitle: Text(user?.email ?? 'Not available'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.badge, color: AppTheme.primaryColor),
                    title: const Text('Role'),
                    subtitle: Text(user?.role.value ?? 'Not available'),
                  ),
                ],
              );
            },
          ),

          const Divider(),

          // About Section
          _buildSectionHeader('About'),

          ListTile(
            leading: const Icon(Icons.info, color: AppTheme.primaryColor),
            title: const Text('App Version'),
            subtitle: const Text('1.1.0'),
          ),

          ListTile(
            leading: const Icon(Icons.favorite, color: AppTheme.primaryColor),
            title: const Text('Manhajul Ihsan Foundation'),
            subtitle: const Text('Every Life Matters'),
          ),

          const SizedBox(height: 32),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close settings
              context.read<ChatProvider>().clearAllData();
              context.read<AuthProvider>().signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

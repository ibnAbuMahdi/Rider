import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rider = ref.watch(currentRiderProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: AppColors.error),
                    const SizedBox(width: 8),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context, ref);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    rider?.displayName.substring(0, 1).toUpperCase() ?? 'R',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  rider?.displayName ?? 'Rider',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  rider?.phoneNumber ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Profile options
          Expanded(
            child: ListView(
              children: [
                _buildProfileOption(
                  context,
                  'Personal Information',
                  Icons.person,
                  () {},
                ),
                _buildProfileOption(
                  context,
                  'Bank Details',
                  Icons.account_balance,
                  () {},
                ),
                _buildProfileOption(
                  context,
                  'Notifications',
                  Icons.notifications,
                  () {},
                ),
                _buildProfileOption(
                  context,
                  'Help & Support',
                  Icons.help,
                  () {},
                ),
                _buildProfileOption(
                  context,
                  'Terms & Conditions',
                  Icons.description,
                  () {},
                ),
                _buildProfileOption(
                  context,
                  'Privacy Policy',
                  Icons.privacy_tip,
                  () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
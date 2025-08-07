import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/fleet_provider.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rider = ref.watch(currentRiderProvider);
    final fleetStatus = ref.watch(fleetStatusProvider);
    final fleetActions = ref.watch(fleetActionsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Logout'),
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
          
          // Fleet Status Card
          _buildFleetStatusCard(context, ref, fleetActions),
          
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
                _buildFleetOption(
                  context,
                  ref,
                  fleetActions,
                ),
                _buildProfileOption(
                  context,
                  'Bank Details',
                  Icons.account_balance,
                  () => context.push('/bank-accounts'),
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

  Widget _buildFleetStatusCard(BuildContext context, WidgetRef ref, FleetActions fleetActions) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    fleetActions.isInFleet ? Icons.business : Icons.person,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fleet Status',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fleetActions.statusDisplay,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: fleetActions.isInFleet ? Colors.green[100] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      fleetActions.isInFleet ? 'Fleet Member' : 'Independent',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: fleetActions.isInFleet ? Colors.green[800] : Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
              if (fleetActions.isInFleet) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Commission Rate:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${fleetActions.commissionRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFleetOption(BuildContext context, WidgetRef ref, FleetActions fleetActions) {
    if (fleetActions.isInFleet) {
      return _buildProfileOption(
        context,
        'Fleet Management',
        Icons.business,
        () => context.push('/fleet-management'),
      );
    } else {
      return _buildProfileOption(
        context,
        'Join Fleet',
        Icons.group_add,
        () => context.push('/join-fleet'),
      );
    }
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
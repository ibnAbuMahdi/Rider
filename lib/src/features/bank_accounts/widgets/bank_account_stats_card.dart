import 'package:flutter/material.dart';
import '../../../core/models/bank_account.dart';

class BankAccountStatsCard extends StatelessWidget {
  final BankAccountStats stats;

  const BankAccountStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Account Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                ),
                if (stats.hasPrimaryAccount)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Setup Complete',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Accounts',
                    stats.totalAccounts.toString(),
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Verified',
                    stats.verifiedAccounts.toString(),
                    Icons.verified,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Pending',
                    stats.pendingAccounts.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Failed',
                    stats.failedAccounts.toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ),
              ],
            ),
            
            // Verification Progress
            if (stats.totalAccounts > 0) ...[
              const SizedBox(height: 16),
              _buildVerificationProgress(context),
            ],
            
            // Primary Account Info
            if (stats.primaryAccount != null) ...[
              const SizedBox(height: 16),
              _buildPrimaryAccountInfo(context),
            ],
            
            // Recommendations
            if (stats.totalAccounts == 0 || !stats.hasPrimaryAccount) ...[
              const SizedBox(height: 16),
              _buildRecommendations(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    MaterialColor color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color[600],
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationProgress(BuildContext context) {
    final progress = stats.verificationRate;
    final progressPercentage = (progress * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verification Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$progressPercentage%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(progress),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(progress),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getProgressMessage(progress),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAccountInfo(BuildContext context) {
    final primaryAccount = stats.primaryAccount!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star,
              color: Colors.green[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Primary Account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${primaryAccount.bankName} - ${primaryAccount.maskedAccountNumber}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              primaryAccount.statusDisplay,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    List<Widget> recommendations = [];
    
    if (stats.totalAccounts == 0) {
      recommendations.add(_buildRecommendationItem(
        Icons.add_card,
        'Add your first bank account',
        'Start receiving payments by adding a bank account',
        Colors.blue,
      ));
    } else if (!stats.hasPrimaryAccount) {
      recommendations.add(_buildRecommendationItem(
        Icons.star,
        'Set a primary account',
        'Choose which account should receive payments',
        Colors.orange,
      ));
    }
    
    if (stats.pendingAccounts > 0) {
      recommendations.add(_buildRecommendationItem(
        Icons.pending,
        'Complete verification',
        '${stats.pendingAccounts} account${stats.pendingAccounts == 1 ? '' : 's'} pending verification',
        Colors.amber,
      ));
    }
    
    if (recommendations.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Colors.amber[800],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.amber[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations,
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    IconData icon,
    String title,
    String description,
    MaterialColor color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: color[600],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: color[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: color[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.5) {
      return Colors.red[400]!;
    } else if (progress < 0.8) {
      return Colors.orange[400]!;
    } else {
      return Colors.green[400]!;
    }
  }

  String _getProgressMessage(double progress) {
    if (progress == 1.0) {
      return 'All accounts are verified!';
    } else if (progress >= 0.8) {
      return 'Most accounts are verified';
    } else if (progress >= 0.5) {
      return 'Some accounts need verification';
    } else {
      return 'Complete verification to receive payments';
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/bank_account_provider.dart';
import '../../../core/models/bank_account.dart';
import '../widgets/bank_account_card.dart';
import '../widgets/bank_account_stats_card.dart';

class BankAccountsScreen extends ConsumerStatefulWidget {
  const BankAccountsScreen({super.key});

  @override
  ConsumerState<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends ConsumerState<BankAccountsScreen> {
  @override
  void initState() {
    super.initState();
    // Load data on screen initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bankAccountsProvider.notifier).refreshAccounts();
      ref.read(bankAccountStatsProvider.notifier).refreshStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bankAccountsState = ref.watch(bankAccountsProvider);
    final statsState = ref.watch(bankAccountStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Accounts'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/bank-accounts/verification-logs'),
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Statistics Card
              statsState.when(
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => const SizedBox.shrink(),
                data: (stats) => stats != null
                    ? BankAccountStatsCard(stats: stats)
                    : const SizedBox.shrink(),
              ),
              
              const SizedBox(height: 16),
              
              // Header with Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Bank Accounts',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/bank-accounts/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Bank Accounts List
              bankAccountsState.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => _buildErrorState(error),
                data: (accounts) => _buildAccountsList(accounts),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsList(List<BankAccount> accounts) {
    if (accounts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ...accounts.map((account) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: BankAccountCard(
            account: account,
            onTap: () => context.push('/bank-accounts/${account.id}'),
            onSetPrimary: account.isPrimary ? null : () => _setPrimaryAccount(account.id),
            onResendVerification: account.canRetryVerification
                ? () => _resendVerification(account.id)
                : null,
            onDelete: accounts.length > 1 ? () => _showDeleteDialog(account) : null,
          ),
        )),
        
        const SizedBox(height: 24),
        
        // Help Section
        _buildHelpSection(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.account_balance,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Bank Accounts',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first bank account to start receiving payments for your campaigns.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/bank-accounts/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Bank Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Accounts',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bank Account Help',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildHelpItem('• Verification typically takes 1-2 minutes'),
            _buildHelpItem('• Ensure account name matches exactly'),
            _buildHelpItem('• BVN is required for verification'),
            _buildHelpItem('• You can have multiple accounts but only one primary'),
            _buildHelpItem('• Primary account is used for all payments'),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    await Future.wait([
      ref.read(bankAccountsProvider.notifier).refreshAccounts(),
      ref.read(bankAccountStatsProvider.notifier).refreshStats(),
    ]);
  }

  Future<void> _setPrimaryAccount(int accountId) async {
    try {
      final success = await ref.read(bankAccountsProvider.notifier).setPrimaryAccount(accountId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primary account updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh stats to reflect changes
        ref.read(bankAccountStatsProvider.notifier).refreshStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set primary account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resendVerification(int accountId) async {
    try {
      final success = await ref.read(bankAccountsProvider.notifier).resendVerification(accountId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification resent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend verification: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BankAccount account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bank Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this bank account?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.bankName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(account.maskedAccountNumber),
                  Text(account.accountName),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount(account.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(int accountId) async {
    try {
      final success = await ref.read(bankAccountsProvider.notifier).deleteAccount(accountId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh stats to reflect changes
        ref.read(bankAccountStatsProvider.notifier).refreshStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
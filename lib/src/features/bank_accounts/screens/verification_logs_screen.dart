import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/bank_account_provider.dart';
import '../../../core/models/bank_account.dart';

class VerificationLogsScreen extends ConsumerStatefulWidget {
  const VerificationLogsScreen({super.key});

  @override
  ConsumerState<VerificationLogsScreen> createState() => _VerificationLogsScreenState();
}

class _VerificationLogsScreenState extends ConsumerState<VerificationLogsScreen> {
  @override
  void initState() {
    super.initState();
    // Load verification logs on screen initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(verificationLogsProvider.notifier).refreshLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final logsState = ref.watch(verificationLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Logs'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(verificationLogsProvider.notifier).refreshLogs();
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(verificationLogsProvider.notifier).refreshLogs();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Verification History',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track all your bank account verification attempts and their outcomes.',
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Logs List
              logsState.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => _buildErrorState(error),
                data: (logs) => _buildLogsList(logs),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogsList(List<BankVerificationLog> logs) {
    if (logs.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: logs.map((log) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: _buildLogCard(log),
      )).toList(),
    );
  }

  Widget _buildLogCard(BankVerificationLog log) {
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
            // Header with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(log.result).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(log.result),
                    color: _getStatusColor(log.result),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.bankAccountDisplay,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(log.processedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(log.result).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusDisplay(log.result),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(log.result),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Verification details
            if (log.notes != null || log.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (log.externalReference != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.settings,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Reference: ${log.externalReference}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (log.errorMessage != null || log.notes != null)
                      Text(
                        log.errorMessage ?? log.notes ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            
            // Duration if available
            if (log.processingTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Processing Time: ${log.processingTime ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Verification History',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your bank account verification attempts will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
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
              'Error Loading Logs',
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
              onPressed: () {
                ref.read(verificationLogsProvider.notifier).refreshLogs();
              },
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'verified':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'verified':
        return Icons.check_circle;
      case 'pending':
      case 'processing':
        return Icons.pending;
      case 'failed':
      case 'error':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return 'Success';
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Failed';
      case 'error':
        return 'Error';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
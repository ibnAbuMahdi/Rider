import 'package:flutter/material.dart';
import '../../../core/models/bank_account.dart';

class BankAccountCard extends StatelessWidget {
  final BankAccount account;
  final VoidCallback? onTap;
  final VoidCallback? onSetPrimary;
  final VoidCallback? onResendVerification;
  final VoidCallback? onDelete;

  const BankAccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.onSetPrimary,
    this.onResendVerification,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.bankName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          account.maskedAccountNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (account.isPrimary)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'PRIMARY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'set_primary':
                            onSetPrimary?.call();
                            break;
                          case 'resend_verification':
                            onResendVerification?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (onSetPrimary != null)
                          const PopupMenuItem(
                            value: 'set_primary',
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 20),
                                SizedBox(width: 8),
                                Text('Set as Primary'),
                              ],
                            ),
                          ),
                        if (onResendVerification != null)
                          const PopupMenuItem(
                            value: 'resend_verification',
                            child: Row(
                              children: [
                                Icon(Icons.refresh, size: 20),
                                SizedBox(width: 8),
                                Text('Resend Verification'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red[600]),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Account Details
              Text(
                account.accountName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Status and Progress
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStatusChip(),
                            const SizedBox(width: 8),
                            Text(
                              account.accountTypeDisplay,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        
                        if (account.verificationProgress < 100) ...[
                          const SizedBox(height: 8),
                          _buildVerificationProgress(),
                        ],
                      ],
                    ),
                  ),
                  
                  // Action Buttons
                  if (!account.isPrimary && onSetPrimary != null)
                    TextButton(
                      onPressed: onSetPrimary,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text(
                        'Set Primary',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              
              // Payment Statistics (if available)
              if (account.totalPaymentsReceived > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Received',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '₦${account.totalPaymentsReceived.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Payments',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${account.paymentCount}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (account.verificationStatus) {
      case 'verified':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        text = 'Verified';
        icon = Icons.verified;
        break;
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        text = 'Pending';
        icon = Icons.pending;
        break;
      case 'failed':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        text = 'Failed';
        icon = Icons.error;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        text = 'Not Verified';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationProgress() {
    final progress = account.verificationProgress / 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Verification Progress',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${account.verificationProgress}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress < 0.5
                  ? Colors.red[400]!
                  : progress < 0.8
                      ? Colors.orange[400]!
                      : Colors.green[400]!,
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
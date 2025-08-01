import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/rider.dart';
import '../../../core/theme/app_colors.dart';
import 'plate_number_activation_dialog.dart';

class RiderStatusCard extends ConsumerWidget {
  final Rider rider;
  final VoidCallback? onActivationSuccess;

  const RiderStatusCard({
    super.key,
    required this.rider,
    this.onActivationSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rider.statusDisplay,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Status description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor().withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusMessageIcon(),
                    size: 16,
                    color: _getStatusColor(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getStatusMessage(),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Verification status if relevant
            if (rider.verificationStatus != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _getVerificationIcon(),
                    size: 16,
                    color: _getVerificationColor(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Verification: ${rider.verificationStatusDisplay}',
                    style: TextStyle(
                      fontSize: 14,
                      color: _getVerificationColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            
            // Action button for pending riders
            if (_canActivate()) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showActivationDialog(context),
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(
                    'Activate Account',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData iconData;
    Color iconColor;

    switch (rider.status?.toLowerCase()) {
      case 'pending':
        iconData = Icons.pending;
        iconColor = Colors.orange;
        break;
      case 'active':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'inactive':
        iconData = Icons.pause_circle;
        iconColor = Colors.grey;
        break;
      case 'suspended':
        iconData = Icons.block;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.help_outline;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Color _getStatusColor() {
    switch (rider.status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusMessageIcon() {
    switch (rider.status?.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'active':
        return Icons.check;
      case 'inactive':
        return Icons.pause;
      case 'suspended':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  String _getStatusMessage() {
    switch (rider.status?.toLowerCase()) {
      case 'pending':
        return 'Your account is pending activation. Click below to activate with your tricycle plate number.';
      case 'active':
        return 'Your account is active and ready for campaigns!';
      case 'inactive':
        return 'Your account is currently inactive. Contact support for assistance.';
      case 'suspended':
        return 'Your account has been suspended. Please contact support.';
      default:
        return 'Account status unknown. Please refresh or contact support.';
    }
  }

  IconData _getVerificationIcon() {
    switch (rider.verificationStatus?.toLowerCase()) {
      case 'unverified':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      case 'verified':
        return Icons.verified;
      case 'rejected':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _getVerificationColor() {
    switch (rider.verificationStatus?.toLowerCase()) {
      case 'unverified':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _canActivate() {
    return rider.status?.toLowerCase() == 'pending';
  }

  void _showActivationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PlateNumberActivationDialog(
        onActivationSuccess: onActivationSuccess,
      ),
    );
  }
}
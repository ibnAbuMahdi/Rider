import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/campaign.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/campaign_provider.dart';
import '../../shared/widgets/loading_button.dart';

class GeofenceInfoCard extends ConsumerWidget {
  final Geofence geofence;
  final VoidCallback? onJoinGeofence;

  const GeofenceInfoCard({
    super.key,
    required this.geofence,
    this.onJoinGeofence,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kDebugMode) {
      print('📍 GEOFENCE CARD: Building info card for ${geofence.name}');
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: geofence.isHighPriority ? AppColors.warning : AppColors.border,
          width: geofence.isHighPriority ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with name and status
            _buildHeader(context),
            
            const SizedBox(height: 12),
            
            // Key metrics row
            _buildMetricsRow(),
            
            const SizedBox(height: 12),
            
            // Earnings highlight
            _buildEarningsHighlight(),
            
            const SizedBox(height: 12),
            
            // Pickup locations info
            if (geofence.hasPickupLocations) ...[
              _buildPickupLocationsInfo(),
              const SizedBox(height: 12),
            ],
            
            // Status and additional info
            _buildStatusInfo(),
            
            const SizedBox(height: 16),
            
            // Error display
            _buildErrorDisplay(ref),
            
            // Action button
            _buildActionButton(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      geofence.name ?? 'Unnamed Geofence',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (geofence.isHighPriority)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: 12,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'HIGH PRIORITY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (geofence.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Text(
                  geofence.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final isActive = geofence.isCurrentlyActive;
    final color = isActive ? AppColors.success : AppColors.textSecondary;
    final text = isActive ? 'ACTIVE' : geofence.status.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetric(
            icon: Icons.attach_money,
            label: 'Rate',
            value: _getRateDisplay(),
            color: AppColors.success,
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: AppColors.border,
        ),
        Expanded(
          child: _buildMetric(
            icon: Icons.people,
            label: 'Slots',
            value: '${geofence.availableSlots ?? 0}/${geofence.maxRiders ?? 0}',
            color: _getSlotsColor(),
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: AppColors.border,
        ),
        Expanded(
          child: _buildMetric(
            icon: Icons.schedule,
            label: 'Duration',
            value: _getDurationDisplay(),
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEarningsHighlight() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.earningsBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.earnings.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.trending_up,
            color: AppColors.earnings,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Daily Earnings',
                  style: TextStyle(
                    color: AppColors.earnings,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${AppConstants.currencySymbol}${geofence.estimatedDailyEarnings.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.earnings,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${AppConstants.currencySymbol}${geofence.estimatedWeeklyEarnings.toStringAsFixed(0)}/week',
            style: const TextStyle(
              color: AppColors.earnings,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Column(
      children: [
        if (geofence.budget != null) ...[
          _buildInfoRow(
            'Budget Progress',
            '${geofence.budgetProgress.toStringAsFixed(1)}%',
            _getBudgetProgressColor(),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: geofence.budgetProgress / 100,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(_getBudgetProgressColor()),
          ),
          const SizedBox(height: 8),
        ],
        if (geofence.hasPerformanceData) ...[
          _buildInfoRow(
            'Success Rate',
            '${geofence.actualVerificationSuccessRate.toStringAsFixed(1)}%',
            AppColors.success,
          ),
          const SizedBox(height: 4),
        ],
        if (geofence.specialInstructions?.isNotEmpty ?? false) ...[
          _buildInfoRow(
            'Instructions',
            geofence.specialInstructions!,
            AppColors.textSecondary,
          ),
          const SizedBox(height: 4),
        ],
        _buildInfoRow(
          'Shape',
          '${geofence.shape.name.toUpperCase()}${geofence.radius != null ? ' (${(geofence.radius! / 1000).toStringAsFixed(1)}km radius)' : ''}',
          AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorDisplay(WidgetRef ref) {
    final campaignState = ref.watch(campaignProvider);
    
    if (campaignState.error != null && campaignState.error!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                campaignState.error!,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildActionButton(WidgetRef ref) {
    if (!geofence.canAcceptRiders) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textSecondary,
          ),
          child: Text(_getUnavailableReason()),
        ),
      );
    }

    final campaignState = ref.watch(campaignProvider);
    
    return SizedBox(
      width: double.infinity,
      child: LoadingButton(
        onPressed: onJoinGeofence,
        isLoading: campaignState.isJoining,
        backgroundColor: AppColors.primary,
        child: const Text(
          'JOIN THIS GEOFENCE',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _getRateDisplay() {
    switch (geofence.rateType ?? 'per_km') {
      case 'per_km':
        return '${AppConstants.currencySymbol}${(geofence.ratePerKm ?? 0).toStringAsFixed(0)}/km';
      case 'per_hour':
        return '${AppConstants.currencySymbol}${(geofence.ratePerHour ?? 0).toStringAsFixed(0)}/hr';
      case 'fixed_daily':
        return '${AppConstants.currencySymbol}${(geofence.fixedDailyRate ?? 0).toStringAsFixed(0)}/day';
      case 'hybrid':
        return 'Hybrid Rate';
      default:
        return '${AppConstants.currencySymbol}${(geofence.ratePerKm ?? 0).toStringAsFixed(0)}/km';
    }
  }

  Color _getSlotsColor() {
    final fillPercentage = geofence.fillPercentage ?? 0.0;
    if (fillPercentage >= 90) return AppColors.error;
    if (fillPercentage >= 70) return AppColors.warning;
    return AppColors.primary;
  }

  String _getDurationDisplay() {
    final now = DateTime.now();
    if (now.isBefore(geofence.startDate)) {
      // Not started yet
      final timeToStart = geofence.timeToStart;
      if (timeToStart.inDays > 0) {
        return '${timeToStart.inDays}d to start';
      } else if (timeToStart.inHours > 0) {
        return '${timeToStart.inHours}h to start';
      } else {
        return 'Starting soon';
      }
    } else if (now.isAfter(geofence.endDate)) {
      // Ended
      return 'Ended';
    } else {
      // Currently active
      final timeRemaining = geofence.timeRemaining;
      if (timeRemaining.inDays > 0) {
        return '${timeRemaining.inDays}d left';
      } else if (timeRemaining.inHours > 0) {
        return '${timeRemaining.inHours}h left';
      } else {
        return 'Ending soon';
      }
    }
  }

  Color _getBudgetProgressColor() {
    final progress = geofence.budgetProgress;
    if (progress >= 90) return AppColors.error;
    if (progress >= 70) return AppColors.warning;
    return AppColors.success;
  }

  String _getUnavailableReason() {
    if (!geofence.isCurrentlyActive) {
      if (geofence.isUpcoming) return 'NOT STARTED YET';
      if (geofence.isExpired) return 'EXPIRED';
      return 'INACTIVE';
    }
    if (!geofence.hasAvailableSlots) return 'SLOTS FULL';
    if (!geofence.hasBudgetRemaining) return 'BUDGET EXHAUSTED';
    return 'UNAVAILABLE';
  }

  Widget _buildPickupLocationsInfo() {
    final activeLocations = geofence.activePickupLocations;
    final totalCount = geofence.pickupLocationCount;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.blue[700],
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Sticker Pickup Locations',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const Spacer(),
              if (totalCount > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$totalCount locations',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Show primary location details
          if (geofence.primaryPickupLocation != null) ...[
            _buildSinglePickupLocation(geofence.primaryPickupLocation!),
            
            // Show additional locations if any
            if (activeLocations.length > 1) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '+${activeLocations.length - 1} more pickup location${activeLocations.length > 2 ? 's' : ''}:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...activeLocations.skip(1).map((location) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.place,
                            size: 12,
                            color: Colors.blue[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location['address'] ?? 'Address not specified',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ] else ...[
            // No active locations
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: Colors.orange[600],
                ),
                const SizedBox(width: 6),
                Text(
                  'No active pickup locations available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSinglePickupLocation(Map<String, dynamic> location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address
        if (location['address'] != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.place,
                size: 14,
                color: Colors.blue[600],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location['address'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        
        // Landmark
        if (location['landmark'] != null) ...[
          Row(
            children: [
              Icon(
                Icons.pin_drop,
                size: 14,
                color: Colors.blue[600],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Near ${location['landmark']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        
        // Contact info and hours
        Row(
          children: [
            // Contact
            if (location['contact_name'] != null) ...[
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location['contact_name'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Hours
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location['today_hours'] ?? 'Contact for hours',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // Instructions
        if (location['pickup_instructions'] != null && location['pickup_instructions'].isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location['pickup_instructions'],
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.amber[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
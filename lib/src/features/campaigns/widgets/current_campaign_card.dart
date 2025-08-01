import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/models/campaign.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class CurrentCampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback? onLeaveGeofence;

  const CurrentCampaignCard({
    super.key,
    required this.campaign,
    this.onLeaveGeofence,
  });

  @override
  Widget build(BuildContext context) {
    // Get geofence areas for display
    final geofenceAreas = campaign.geofences
        .where((g) => g.name != null && g.name!.isNotEmpty)
        .map((g) => g.name!)
        .take(3)
        .toList();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8), // Reduced bottom margin from 16 to 8
      height: 115, // Reduced after removing Rate section
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with campaign info and actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.name ?? 'Unnamed Campaign',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (campaign.clientName != null && campaign.clientName!.isNotEmpty)
                        Text(
                          'by ${campaign.clientName}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: AppColors.error, size: 16),
                          SizedBox(width: 6),
                          Text('Leave Geofence', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'leave' && onLeaveGeofence != null) {
                      onLeaveGeofence!();
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 6),
            
            // Active areas and duration in horizontal layout
            Row(
              children: [
                // Active areas section
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Areas',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (geofenceAreas.isNotEmpty) ...[
                        Text(
                          geofenceAreas.length == 1 
                              ? geofenceAreas.first
                              : '${geofenceAreas.first} +${geofenceAreas.length - 1} more',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Text(
                          campaign.area ?? 'General Area',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Duration section
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: AppColors.info,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                '${_formatDate(campaign.startDate)} - ${_formatDate(campaign.endDate)}',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (!campaign.isExpired) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatDuration(campaign.timeRemaining),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.info,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'TBD';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} days';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hours';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minutes';
    } else {
      return 'Ending soon';
    }
  }
}
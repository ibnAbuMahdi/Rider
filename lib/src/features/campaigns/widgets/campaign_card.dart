import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/models/campaign.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback? onJoin;
  final VoidCallback? onViewDetails;

  const CampaignCard({
    super.key,
    required this.campaign,
    this.onJoin,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sticker preview image
          _buildStickerPreview(),
          
          // Campaign content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campaign name and client
                _buildHeader(context),
                
                const SizedBox(height: 12),
                
                // Key metrics
                _buildMetrics(),
                
                const SizedBox(height: 12),
                
                // Estimated earnings highlight
                _buildEarningsHighlight(),
                
                const SizedBox(height: 16),
                
                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerPreview() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: campaign.stickerImageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: campaign.stickerImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => _buildStickerPlaceholder(),
              )
            : _buildStickerPlaceholder(),
      ),
    );
  }

  Widget _buildStickerPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 40,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Sticker Preview',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          campaign.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (campaign.clientName != null && campaign.clientName!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'by ${campaign.clientName}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetrics() {
    return Row(
      children: [
        // Rate per km
        Expanded(
          child: _buildMetricItem(
            icon: Icons.attach_money,
            label: 'Rate',
            value: '${AppConstants.currencySymbol}${campaign.ratePerKm.toStringAsFixed(0)}/km',
            color: AppColors.success,
          ),
        ),
        
        Container(
          width: 1,
          height: 40,
          color: AppColors.border,
        ),
        
        // Area
        Expanded(
          child: _buildMetricItem(
            icon: Icons.location_on,
            label: 'Area',
            value: campaign.area,
            color: AppColors.secondary,
          ),
        ),
        
        Container(
          width: 1,
          height: 40,
          color: AppColors.border,
        ),
        
        // Available slots
        Expanded(
          child: _buildMetricItem(
            icon: Icons.people,
            label: 'Slots',
            value: '${campaign.availableSlots}/${campaign.maxRiders}',
            color: campaign.fillPercentage > 80 ? AppColors.warning : AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
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
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You fit make like ${AppConstants.currencySymbol}${campaign.estimatedWeeklyEarnings.toStringAsFixed(0)} every week',
              style: const TextStyle(
                color: AppColors.earnings,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // View details button
        Expanded(
          child: OutlinedButton(
            onPressed: onViewDetails,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: const Text('VIEW DETAILS'),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Join button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: campaign.canJoin ? onJoin : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: campaign.canJoin ? AppColors.primary : AppColors.textSecondary,
            ),
            child: Text(
              campaign.canJoin ? 'JOIN CAMPAIGN' : 'FULL',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
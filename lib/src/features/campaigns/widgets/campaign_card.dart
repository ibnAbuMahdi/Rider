import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/models/campaign.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback? onViewDetails;

  const CampaignCard({
    super.key,
    required this.campaign,
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
    if (kDebugMode) {
      print('🖼️ CAMPAIGN CARD: Loading sticker image for ${campaign.name}');
      print('🖼️ Image URL: ${campaign.stickerImageUrl}');
    }
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: (campaign.stickerImageUrl?.isNotEmpty ?? false)
            ? CachedNetworkImage(
                imageUrl: campaign.stickerImageUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) {
                  if (kDebugMode) {
                    print('🖼️ IMAGE ERROR: Failed to load ${campaign.name} sticker: $error');
                  }
                  return _buildStickerPlaceholder();
                },
              )
            : _buildStickerPlaceholder(),
      ),
    );
  }

  Widget _buildStickerPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceVariant,
            AppColors.surfaceVariant.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.image_outlined,
              size: 32,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Campaign Sticker',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            campaign.name ?? 'Preview',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.6),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
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
          campaign.name ?? 'Unnamed Campaign',
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
            value: '${AppConstants.currencySymbol}${(campaign.ratePerKm ?? 0.0).toStringAsFixed(0)}/km',
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
            value: campaign.area ?? '',
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
            value: '${campaign.availableSlots ?? 0}/${campaign.maxRiders ?? 0}',
            color: (campaign.fillPercentage ?? 0.0) > 80 ? AppColors.warning : AppColors.primary,
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
              'You fit make like ${AppConstants.currencySymbol}${(campaign.estimatedWeeklyEarnings ?? 0.0).toStringAsFixed(0)} every week',
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onViewDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text(
          'VIEW DETAILS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
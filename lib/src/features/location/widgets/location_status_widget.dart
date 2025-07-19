import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/theme/app_colors.dart';

class LocationStatusWidget extends ConsumerWidget {
  final String? campaignName;
  
  const LocationStatusWidget({
    super.key,
    this.campaignName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final isTracking = locationState.isTracking;
    final currentPosition = locationState.currentPosition;
    final hasPermission = locationState.hasPermission;
    
    if (!hasPermission) {
      return _buildPermissionNeeded(context, ref);
    }
    
    if (isTracking) {
      return _buildTrackingActive(context, locationState);
    }
    
    return _buildTrackingInactive(context, ref);
  }

  Widget _buildPermissionNeeded(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_off,
            color: AppColors.warning,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            'Location Permission Needed',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'We need location access to track your campaign participation',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.read(locationProvider.notifier).requestPermissions(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingActive(BuildContext context, LocationState locationState) {
    final position = locationState.currentPosition;
    final campaignId = locationState.activeCampaignId;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location Tracking Active',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    if (campaignName != null)
                      Text(
                        'Campaign: $campaignName',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
              // Blinking indicator
              const _BlinkingDot(),
            ],
          ),
          
          if (position != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLocationStat(
                  'Accuracy',
                  '${position.accuracy.toStringAsFixed(0)}m',
                  Icons.gps_fixed,
                ),
                _buildLocationStat(
                  'Speed',
                  '${(position.speed * 3.6).toStringAsFixed(1)} km/h',
                  Icons.speed,
                ),
                _buildLocationStat(
                  'Altitude',
                  '${position.altitude.toStringAsFixed(0)}m',
                  Icons.terrain,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingInactive(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_disabled,
            color: AppColors.gray,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            'Location Tracking Inactive',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Join a campaign to start tracking your location',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.read(locationProvider.notifier).getCurrentLocation(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Get Current Location'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.gray,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.gray,
          ),
        ),
      ],
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
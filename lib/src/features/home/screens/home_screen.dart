import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/campaign_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/earnings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/campaign.dart' as models;
import '../../../core/models/campaign.dart' show CampaignStatus;
import '../../location/widgets/location_status_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Marker> _markers = {};
  Set<gmaps.Circle> _circles = {};
  bool _showMap = true;
  bool _isInitialLoading = true;

  // Default Lagos coordinates
  static const gmaps.LatLng _defaultLocation = gmaps.LatLng(6.5244, 3.3792);

  @override
  void initState() {
    super.initState();
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      // Load data sequentially to avoid race conditions and API overload
      // Each operation is wrapped in try-catch to prevent any single failure from crashing the app
      
      // 1. Load location data first (most critical)
      await _loadLocationData();
      
      // Small delay to avoid overwhelming the backend
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 2. Load campaign data
      await _loadCampaignData();
      
      // Small delay to avoid overwhelming the backend
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 3. Load earnings data last (least critical for initial display)
      await _loadEarningsData();
      
      // Update map markers after all data is loaded
      if (mounted) {
        _updateMapMarkers();
        setState(() {
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      // Handle errors gracefully - don't crash the app
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Some data could not be loaded. Pull to refresh.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadLocationData() async {
    try {
      // Load location data with timeout to prevent hanging
      await ref.read(locationProvider.notifier).requestPermissions().timeout(Duration(seconds: 10));
      await ref.read(locationProvider.notifier).getCurrentLocation().timeout(Duration(seconds: 10));
    } catch (e) {
      // Location errors are non-critical - continue without location
      if (kDebugMode) {
        print('Location loading failed (non-critical): $e');
      }
    }
  }

  Future<void> _loadCampaignData() async {
    try {
      // Load campaign data with timeout and error isolation
      await ref.read(campaignProvider.notifier).refresh().timeout(Duration(seconds: 15));
    } catch (e) {
      // Campaign errors are non-critical - continue with cached data
      if (kDebugMode) {
        print('Campaign loading failed (non-critical): $e');
      }
    }
  }

  Future<void> _loadEarningsData() async {
    try {
      // Load earnings data with timeout and error isolation
      await ref.read(earningsProvider.notifier).refresh().timeout(Duration(seconds: 15));
    } catch (e) {
      // Earnings errors are non-critical - continue with cached data
      if (kDebugMode) {
        print('Earnings loading failed (non-critical): $e');
      }
    }
  }

  void _updateMapMarkers() {
    try {
      if (!mounted) return;
      
      final campaigns = ref.read(campaignProvider).campaigns;
      final currentPosition = ref.read(locationProvider).currentPosition;
      
      final Set<gmaps.Marker> markers = {};
      final Set<gmaps.Circle> circles = {};

    // Add campaign markers and geofences
    for (final campaign in campaigns) {
      // Add markers and circles for each geofence in the campaign
      for (int i = 0; i < campaign.geofences.length; i++) {
        final geofence = campaign.geofences[i];
        
        final marker = gmaps.Marker(
          markerId: gmaps.MarkerId('${campaign.id}_geofence_$i'),
          position: gmaps.LatLng(
            geofence.centerLatitude,
            geofence.centerLongitude,
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            campaign.status == CampaignStatus.running 
              ? gmaps.BitmapDescriptor.hueGreen 
              : gmaps.BitmapDescriptor.hueOrange,
          ),
          infoWindow: gmaps.InfoWindow(
            title: campaign.name,
            snippet: '₦${campaign.ratePerHour.toStringAsFixed(0)}/hr • ${campaign.currentRiders}/${campaign.maxRiders} riders',
            onTap: () => _showCampaignDetails(campaign),
          ),
        );
        markers.add(marker);

        // Add geofence circle
        final circle = gmaps.Circle(
          circleId: gmaps.CircleId('${campaign.id}_geofence_$i'),
          center: gmaps.LatLng(
            geofence.centerLatitude,
            geofence.centerLongitude,
          ),
          radius: geofence.radius,
          fillColor: AppColors.primary.withOpacity(0.1),
          strokeColor: AppColors.primary,
          strokeWidth: 2,
        );
        circles.add(circle);
      }
    }

    // Add current location marker
    if (currentPosition != null) {
      final currentLocationMarker = gmaps.Marker(
        markerId: const gmaps.MarkerId('current_location'),
        position: gmaps.LatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        ),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueBlue),
        infoWindow: const gmaps.InfoWindow(
          title: 'Your Location',
          snippet: 'Current position',
        ),
      );
      markers.add(currentLocationMarker);
    }

      if (mounted) {
        setState(() {
          _markers = markers;
          _circles = circles;
        });
      }
    } catch (e) {
      // Handle marker update errors silently
      if (mounted) {
        setState(() {
          _markers = {};
          _circles = {};
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen during initial data load
    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading your dashboard...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final authState = ref.watch(authProvider);
    final campaignState = ref.watch(campaignProvider);
    final locationState = ref.watch(locationProvider);
    final paymentSummary = ref.watch(paymentSummaryProvider);

    final rider = authState.rider;
    final activeCampaign = campaignState.currentCampaign;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          rider != null ? 'Welcome, ${rider.firstName}!' : 'Welcome!',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showNotifications(),
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () => _showProfile(),
            icon: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: CustomScrollView(
          slivers: [
            // Quick Stats
            if (paymentSummary != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'This Week',
                          paymentSummary.formattedThisWeekEarnings,
                          Icons.calendar_view_week,
                          AppColors.success,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.textTertiary,
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Pending',
                          paymentSummary.formattedPendingEarnings,
                          Icons.schedule,
                          AppColors.warning,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.textTertiary,
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Total Paid',
                          paymentSummary.formattedPaidEarnings,
                          Icons.check_circle,
                          AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Active Campaign Card
            if (activeCampaign != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.campaign, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Active Campaign',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              locationState.isTracking ? 'TRACKING' : 'PAUSED',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        activeCampaign.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₦${activeCampaign.ratePerHour.toStringAsFixed(0)}/hour',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _navigateToVerification(activeCampaign),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.success,
                              ),
                              child: const Text('Verify Now'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => _stopCampaign(activeCampaign),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Stop'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Location Status
            const SliverToBoxAdapter(
              child: LocationStatusWidget(),
            ),

            // Map/List Toggle
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Nearby Campaigns',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          icon: Icon(Icons.map, size: 16),
                          label: Text('Map'),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          icon: Icon(Icons.list, size: 16),
                          label: Text('List'),
                        ),
                      ],
                      selected: {_showMap},
                      onSelectionChanged: (Set<bool> selected) {
                        setState(() {
                          _showMap = selected.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Map or Campaign List
            SliverToBoxAdapter(
              child: Container(
                height: 300,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.textTertiary),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _showMap ? _buildMapView() : _buildCampaignListView(),
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: _buildQuickActions(),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    try {
      final currentPosition = ref.watch(locationProvider).currentPosition;
      
      return gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(
          target: currentPosition != null 
            ? gmaps.LatLng(currentPosition.latitude, currentPosition.longitude)
            : _defaultLocation,
          zoom: 12,
        ),
        onMapCreated: (gmaps.GoogleMapController controller) {
          try {
            _mapController = controller;
            // Defer marker updates to avoid blocking UI
            Future.microtask(() => _updateMapMarkers());
          } catch (e) {
            // Handle map controller errors
          }
        },
        markers: _markers,
        circles: _circles,
        myLocationEnabled: false, // Disable to reduce load
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        buildingsEnabled: false,
        trafficEnabled: false,
        liteModeEnabled: true, // Enable lite mode for better performance
      );
    } catch (e) {
      // Fallback UI if Google Maps fails
      return Container(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 48,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Map not available',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCampaignListView() {
    final campaigns = ref.watch(campaignProvider).campaigns;
    
    if (campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No campaigns nearby',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        final campaign = campaigns[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: campaign.status == 'active' 
                ? AppColors.success 
                : AppColors.warning,
              child: const Icon(Icons.campaign, color: Colors.white),
            ),
            title: Text(
              campaign.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('₦${campaign.ratePerHour.toStringAsFixed(0)}/hr • ${campaign.currentRiders}/${campaign.maxRiders} riders'),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
            onTap: () => _showCampaignDetails(campaign),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.campaign,
                  label: 'Browse Campaigns',
                  onTap: () => Navigator.pushNamed(context, '/campaigns'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.account_balance_wallet,
                  label: 'My Earnings',
                  onTap: () => Navigator.pushNamed(context, '/earnings'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.help_outline,
                  label: 'Support',
                  onTap: () => _contactSupport(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.person,
                  label: 'Profile',
                  onTap: () => _showProfile(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.textTertiary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCampaignDetails(models.Campaign campaign) {
    // Navigate to campaign details
    Navigator.pushNamed(context, '/campaign-details', arguments: campaign);
  }

  void _navigateToVerification(models.Campaign campaign) {
    Navigator.pushNamed(context, '/verification', arguments: campaign);
  }

  Future<void> _stopCampaign(models.Campaign campaign) async {
    // Stop location tracking
    await ref.read(locationProvider.notifier).stopTracking();
    
    // Leave campaign
    await ref.read(campaignProvider.notifier).leaveCampaign();
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Left ${campaign.name} campaign'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showNotifications() {
    // Navigate to notifications screen
    Navigator.pushNamed(context, '/notifications');
  }

  void _showProfile() {
    // Navigate to profile screen
    Navigator.pushNamed(context, '/profile');
  }

  void _contactSupport() {
    // Open WhatsApp or support contact
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text('Need help? Contact our support team via WhatsApp'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open WhatsApp or call support
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('WhatsApp Support'),
          ),
        ],
      ),
    );
  }
}
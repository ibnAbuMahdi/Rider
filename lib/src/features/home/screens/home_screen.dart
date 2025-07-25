import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stika_rider/src/core/models/payment_summary.dart';
import '../../../core/models/campaign.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/campaign_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/earnings_provider.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isInitialLoading = true;
  GoogleMapController? _mapController;
  Set<Circle> _geofenceCircles = {};
  Set<Marker> _geofenceMarkers = {};

  @override
  void initState() {
    super.initState();
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (kDebugMode) {
      print('🏠 HOME SCREEN: Starting initial data load');
      print('🏠 Timestamp: ${DateTime.now().toIso8601String()}');
    }
    
    try {
      // Load data sequentially to avoid race conditions and API overload
      // Each operation is wrapped in try-catch to prevent any single failure from crashing the app
      
      // 1. Load location data first (most critical)
      if (kDebugMode) print('🏠 Step 1: Loading location data...');
      await _loadLocationData();
      
      // Small delay to avoid overwhelming the backend
      if (kDebugMode) print('🏠 Step 2: Waiting 300ms before campaigns...');
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 2. Load campaign data
      if (kDebugMode) print('🏠 Step 3: Loading campaign data...');
      // await _loadCampaignData();
      
      // // Small delay to avoid overwhelming the backend
      // if (kDebugMode) print('🏠 Step 4: Waiting 300ms before earnings...');
      // await Future.delayed(const Duration(milliseconds: 300));
      
      // // 3. Load earnings data last (least critical for initial display)
      // if (kDebugMode) print('🏠 Step 5: Loading earnings data...');
      // await _loadEarningsData();
      
      // Update state after all data is loaded
      if (mounted) {
        if (kDebugMode) print('🏠 Step 6: Setting loading to false...');
        setState(() {
          _isInitialLoading = false;
        });
      }
      
      if (kDebugMode) print('🏠 HOME SCREEN: Initial data load completed successfully');
    } catch (e) {
      if (kDebugMode) {
        print('🏠 HOME SCREEN ERROR: Initial data load failed');
        print('🏠 Error: $e');
        print('🏠 Error Type: ${e.runtimeType}');
        print('🏠 Stack Trace: ${StackTrace.current}');
      }
      
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
      if (kDebugMode) {
        print('🏠 LOCATION: Starting requestPermissions...');
      }
      
      // Wrap each call individually with timeout and error handling
      try {
        final permissionResult = await ref.read(locationProvider.notifier).requestPermissions();
        
        if (kDebugMode) {
          print('🏠 LOCATION: requestPermissions completed, starting getCurrentLocation...');
        }
      } catch (e) {
        if (kDebugMode) {
          print('🏠 LOCATION ERROR: requestPermissions failed: $e');
        }
        return; // Skip getCurrentLocation if permissions failed
      }
      
      try {
        await ref.read(locationProvider.notifier).getCurrentLocation()
            .timeout(const Duration(seconds: 20), onTimeout: () {
          if (kDebugMode) {
            print('🏠 LOCATION: getCurrentLocation timed out after 20 seconds');
          }
          throw TimeoutException('Location request timed out', const Duration(seconds: 20));
        });
        
        if (kDebugMode) {
          print('🏠 LOCATION: getCurrentLocation completed successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('🏠 LOCATION ERROR: getCurrentLocation failed: $e');
        }
      }
      
    } catch (e, stackTrace) {
      // Location errors are non-critical - continue without location
      if (kDebugMode) {
        print('🏠 LOCATION FATAL ERROR: $e');
        print('🏠 LOCATION STACK: $stackTrace');
      }
    }
    
    if (kDebugMode) {
      print('🏠 LOCATION: _loadLocationData completed');
    }
  }

  Future<void> _loadCampaignData() async {
    try {
      // Load campaign data with timeout and error isolation
      await ref.read(campaignProvider.notifier).refresh().timeout(const Duration(seconds: 15));
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
      await ref.read(earningsProvider.notifier).refresh().timeout(const Duration(seconds: 15));
    } catch (e) {
      // Earnings errors are non-critical - continue with cached data
      if (kDebugMode) {
        print('Earnings loading failed (non-critical): $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('🏠 HOME BUILD: Starting build method');
    }
    
    // Show loading screen during initial data load
    if (_isInitialLoading) {
      if (kDebugMode) {
        print('🏠 HOME BUILD: Showing loading screen');
      }
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
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

    if (kDebugMode) {
      print('🏠 HOME BUILD: Loading providers...');
    }

    // Load providers one by one with error handling
    late final AuthState authState;
    late final CampaignState campaignState;
    late final LocationState locationState;
    late final PaymentSummary? paymentSummary;
    late final rider;
    late final activeCampaign;

    try {
      if (kDebugMode) print('🏠 HOME BUILD: Loading authProvider...');
      authState = ref.watch(authProvider);
      
      if (kDebugMode) print('🏠 HOME BUILD: Loading campaignProvider...');
      campaignState = ref.watch(campaignProvider);
      
      if (kDebugMode) print('🏠 HOME BUILD: Loading locationProvider...');
      locationState = ref.watch(locationProvider);
      
      if (kDebugMode) print('🏠 HOME BUILD: Loading paymentSummaryProvider...');
      paymentSummary = ref.watch(paymentSummaryProvider);

      rider = authState.rider;
      activeCampaign = campaignState.currentCampaign;
      
      // Update geofence overlays when campaign changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateGeofenceOverlays();
      });
      
      if (kDebugMode) {
        print('🏠 HOME BUILD: All providers loaded successfully');
        print('🏠 Rider: ${rider?.firstName ?? 'null'}');
        print('🏠 Campaigns: ${campaignState.campaigns.length}');
        print('🏠 Payment Summary: ${paymentSummary != null ? 'loaded' : 'null'}');
        print('🏠 Active Campaign Geofences: ${activeCampaign?.geofences.length ?? 0}');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('🚨 HOME BUILD ERROR: Failed to load providers');
        print('🚨 Error: $e');
        print('🚨 Stack: $stack');
      }
      
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading data'),
              const SizedBox(height: 8),
              Text('$e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitialLoading = true;
                  });
                  _loadInitialData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

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
        child: Stack(
          children: [
            // Google Maps as background
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  locationState.currentPosition?.latitude ?? 6.5244, // Lagos default
                  locationState.currentPosition?.longitude ?? 3.3792,
                ),
                zoom: 14.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              circles: _geofenceCircles,
              markers: _geofenceMarkers,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _updateGeofenceOverlays();
              },
            ),
            
            // Overlay cards on top of map
            SafeArea(
              child: Column(
                children: [
                  // Top cards section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Debug info card (only in debug mode)
                        if (kDebugMode)
                          Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Debug Info:', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  Text('Rider: ${rider?.firstName ?? 'null'}'),
                                  Text('Campaigns: ${campaignState.campaigns.length}'),
                                  Text('Payment Summary: ${paymentSummary != null ? 'loaded' : 'null'}'),
                                  Text('Location: ${locationState.currentPosition != null ? 'available' : 'unavailable'}'),
                                  if (locationState.currentPosition != null) ...[
                                    Text('  Coordinates: ${locationState.currentPosition!.latitude.toStringAsFixed(4)}, ${locationState.currentPosition!.longitude.toStringAsFixed(4)}'),
                                    Text('  Accuracy: ${locationState.currentPosition!.accuracy.toStringAsFixed(1)}m'),
                                  ],
                                  Text('Permission: ${locationState.hasPermission ? 'granted' : 'denied'}'),
                                  Text('Tracking: ${locationState.isTracking ? 'active' : 'inactive'}'),
                                  if (locationState.error != null)
                                    Text('Error: ${locationState.error}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        
                        // Active Campaign card with geofence info
                        if (activeCampaign != null)
                          Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Active Campaign',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      Icon(
                                        Icons.campaign,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    activeCampaign.name ?? 'Active Campaign',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${activeCampaign.geofences.length} active areas',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (activeCampaign.geofences.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Areas:',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...activeCampaign.geofences.take(3).map((geofence) => 
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8, bottom: 2),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Color(geofence.displayColor),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${geofence.name ?? 'Geofence'} (${geofence.rateType ?? 'unknown'})',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ),
                                            Text(
                                              geofence.canAcceptRiders ? 'Available' : 'Full',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: geofence.canAcceptRiders ? Colors.green : Colors.orange,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (activeCampaign.geofences.length > 3)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 16, top: 2),
                                        child: Text(
                                          '+${activeCampaign.geofences.length - 3} more areas',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        
                        // Earnings Summary card (always visible)
                        if (paymentSummary != null)
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Earnings Summary', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  Text('This Week: ${paymentSummary.formattedThisWeekEarnings}'),
                                  Text('Pending: ${paymentSummary.formattedPendingEarnings}'),
                                  Text('Total Paid: ${paymentSummary.formattedPaidEarnings}'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Spacer to push content to top
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    // Navigate to notifications screen
    if (kDebugMode) print('🏠 HOME: Navigate to notifications');
    // Navigator.pushNamed(context, '/notifications');
  }

  void _showProfile() {
    // Navigate to profile screen
    if (kDebugMode) print('🏠 HOME: Navigate to profile');
    // Navigator.pushNamed(context, '/profile');
  }
  
  void _updateGeofenceOverlays() {
    if (_mapController == null) return;
    
    final campaignState = ref.read(campaignProvider);
    final activeCampaign = campaignState.currentCampaign;
    
    if (activeCampaign == null || activeCampaign.geofences.isEmpty) {
      setState(() {
        _geofenceCircles.clear();
        _geofenceMarkers.clear();
      });
      return;
    }
    
    final circles = <Circle>{};
    final markers = <Marker>{};
    
    for (int i = 0; i < activeCampaign.geofences.length; i++) {
      final geofence = activeCampaign.geofences[i];
      final geofenceId = geofence.id ?? 'unknown';
      
      // Create circle overlay for geofence boundary
      final circle = Circle(
        circleId: CircleId(geofenceId),
        center: LatLng(
          geofence.centerLatitude,
          geofence.centerLongitude,
        ),
        radius: geofence.radius ?? 0.0,
        fillColor: Color(geofence.displayColor).withOpacity(geofence.displayAlpha * 0.2),
        strokeColor: Color(geofence.displayColor).withOpacity(geofence.displayAlpha),
        strokeWidth: geofence.isHighPriority ? 3 : 2,
      );
      circles.add(circle);
      
      // Create marker for geofence center with earnings info
      final marker = Marker(
        markerId: MarkerId(geofenceId),
        position: LatLng(
          geofence.centerLatitude,
          geofence.centerLongitude,
        ),
        icon: geofence.isHighPriority 
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: geofence.name ?? 'Geofence',
          snippet: _getGeofenceInfoSnippet(geofence),
        ),
        onTap: () => _showGeofenceDetails(geofence),
      );
      markers.add(marker);
    }
    
    setState(() {
      _geofenceCircles = circles;
      _geofenceMarkers = markers;
    });
    
    // Adjust camera to show all geofences
    _fitCameraToGeofences(activeCampaign.geofences);
  }
  
  String _getGeofenceInfoSnippet(Geofence geofence) {
    final rateInfo = (geofence.rateType ?? 'per_km') == 'per_km' 
        ? '₦${geofence.ratePerKm ?? 0.0}/km'
        : (geofence.rateType ?? 'per_km') == 'per_hour'
            ? '₦${geofence.ratePerHour ?? 0.0}/hr'
            : (geofence.rateType ?? 'per_km') == 'fixed_daily'
                ? '₦${geofence.fixedDailyRate ?? 0.0}/day'
                : 'Hybrid rate';
    
    final availability = geofence.canAcceptRiders 
        ? '${geofence.availableSlots ?? 0} slots available'
        : 'Full (${geofence.currentRiders ?? 0}/${geofence.maxRiders ?? 0})';
    
    return '$rateInfo • $availability';
  }
  
  void _showGeofenceDetails(Geofence geofence) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(geofence.displayColor),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    geofence.name ?? 'Geofence',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (geofence.isHighPriority)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'HIGH PRIORITY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Rate Information
            _buildInfoRow('Rate Type', (geofence.rateType ?? 'per_km').toUpperCase()),
            if ((geofence.rateType ?? 'per_km') == 'per_km' || (geofence.rateType ?? 'per_km') == 'hybrid')
              _buildInfoRow('Per Kilometer', '₦${geofence.ratePerKm ?? 0.0}'),
            if ((geofence.rateType ?? 'per_km') == 'per_hour' || (geofence.rateType ?? 'per_km') == 'hybrid')
              _buildInfoRow('Per Hour', '₦${geofence.ratePerHour ?? 0.0}'),
            if ((geofence.rateType ?? 'per_km') == 'fixed_daily')
              _buildInfoRow('Daily Rate', '₦${geofence.fixedDailyRate ?? 0.0}'),
            
            const SizedBox(height: 8),
            
            // Availability Information
            _buildInfoRow('Available Slots', '${geofence.availableSlots ?? 0}'),
            _buildInfoRow('Current Riders', '${geofence.currentRiders ?? 0}/${geofence.maxRiders ?? 0}'),
            _buildInfoRow('Fill Percentage', '${(geofence.fillPercentage ?? 0.0).toStringAsFixed(1)}%'),
            
            const SizedBox(height: 8),
            
            // Financial Information
            _buildInfoRow('Budget', '₦${geofence.budget ?? 0.0}'),
            _buildInfoRow('Spent', '₦${geofence.spent ?? 0.0}'),
            _buildInfoRow('Remaining', '₦${geofence.remainingBudget ?? 0.0}'),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: geofence.canAcceptRiders ? () {
                      Navigator.pop(context);
                      _navigateToGeofence(geofence);
                    } : null,
                    child: Text(geofence.canAcceptRiders ? 'Navigate Here' : 'Area Full'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  void _navigateToGeofence(Geofence geofence) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              geofence.centerLatitude,
              geofence.centerLongitude,
            ),
            zoom: 16.0,
          ),
        ),
      );
    }
  }
  
  void _fitCameraToGeofences(List<Geofence> geofences) {
    if (_mapController == null || geofences.isEmpty) return;
    
    if (geofences.length == 1) {
      // Single geofence - center on it
      final geofence = geofences.first;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              geofence.centerLatitude,
              geofence.centerLongitude,
            ),
            zoom: 14.0,
          ),
        ),
      );
      return;
    }
    
    // Multiple geofences - fit bounds
    double minLat = geofences.first.centerLatitude;
    double maxLat = geofences.first.centerLatitude;
    double minLng = geofences.first.centerLongitude;
    double maxLng = geofences.first.centerLongitude;
    
    for (final geofence in geofences) {
      minLat = math.min(minLat, geofence.centerLatitude);
      maxLat = math.max(maxLat, geofence.centerLatitude);
      minLng = math.min(minLng, geofence.centerLongitude);
      maxLng = math.max(maxLng, geofence.centerLongitude);
    }
    
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }
}
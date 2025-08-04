import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stika_rider/src/core/models/payment_summary.dart';
import 'package:stika_rider/src/core/models/rider.dart';
import '../../../core/models/campaign.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/campaign_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/earnings_provider.dart';
import '../../../core/providers/verification_provider.dart';
import '../../../core/services/random_verification_background_service.dart';
import '../../../core/services/location_api_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/verification_request.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../verification/screens/verification_screen.dart';
import '../widgets/rider_status_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isInitialLoading = true;
  bool _isRefreshing = false; // Prevent duplicate refresh calls
  bool _showDebugCard = false; // Toggle for debug card visibility
  GoogleMapController? _mapController;
  Set<Circle> _geofenceCircles = {};
  Set<Marker> _geofenceMarkers = {};
  RandomVerificationBackgroundService? _randomVerificationService;
  Map<String, dynamic>? _trackingStats;
  LocationApiService? _locationApiService;
  Timer? _trackingStatsUpdateTimer;

  @override
  void initState() {
    super.initState();
    
    // Initialize location API service
    _locationApiService = LocationApiService(ApiService.instance);

    // Load initial data and restart verification service if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      
      // Restart verification service if rider has active geofences
      // This handles the case where service was stopped during dispose
      if (mounted) {
        final hasActiveGeofences = ref.read(hasActiveGeofenceAssignmentsProvider);
        if (hasActiveGeofences) {
          if (kDebugMode) {
            print('🎯 HOME SCREEN: Restarting verification service on return (has active geofences)');
          }
          _manageRandomVerificationService(hasActiveGeofences);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadInitialData() async {
    if (kDebugMode) {
      print('🏠 HOME SCREEN: Starting initial data load');
      print('🏠 Timestamp: ${DateTime.now().toIso8601String()}');
    }

    try {
      // Always load location data first (critical for app functionality)
      if (kDebugMode) print('🏠 Step 1: Loading location data (always required)...');
      await _loadLocationData();

      // Check if we have sufficient cached data for other operations
      final hasCachedData = await _checkCachedData();
      
      if (hasCachedData) {
        if (kDebugMode) {
          print('🏠 HOME SCREEN: Sufficient cached data found, skipping API calls but location was loaded');
        }
        
        // Update state to show cached data, location was already loaded
        if (mounted) {
          setState(() {
            _isInitialLoading = false;
          });
        }
        
        // Even with cached data, check for verification service management and update map overlays
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final hasActiveGeofences = ref.read(hasActiveGeofenceAssignmentsProvider);
            _manageRandomVerificationService(hasActiveGeofences);
            
            // Update geofence overlays for cached campaign data
            if (_mapController != null) {
              _updateGeofenceOverlays();
            }
            
            // Start tracking stats update timer
            _startTrackingStatsTimer();
          }
        });
        return;
      }

      if (kDebugMode) {
        print('🏠 HOME SCREEN: No sufficient cached data, fetching from API');
      }

      // Load remaining data sequentially to avoid race conditions and API overload
      // Each operation is wrapped in try-catch to prevent any single failure from crashing the app

      // Small delay to avoid overwhelming the backend
      if (kDebugMode) print('🏠 Step 2: Waiting 300ms before campaigns...');
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. Check for campaign cache miss and load campaign data
      if (kDebugMode) print('🏠 Step 3: Checking and loading campaign data...');
      await _checkAndLoadCampaignData();

      // Small delay to avoid overwhelming the backend
      if (kDebugMode) print('🏠 Step 4: Waiting 300ms before tracking stats...');
      await Future.delayed(const Duration(milliseconds: 300));

      // 3. Load tracking statistics (new feature)
      if (kDebugMode) print('🏠 Step 5: Loading tracking statistics...');
      await _loadTrackingStats();

      // Update state after all data is loaded
      if (mounted) {
        if (kDebugMode) print('🏠 Step 6: Setting loading to false...');
        setState(() {
          _isInitialLoading = false;
        });
      }

      if (kDebugMode) {
        print('🏠 HOME SCREEN: Initial data load completed successfully');
      }

      // Check if random verification service should be started after initial load and update map overlays
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final hasActiveGeofences = ref.read(hasActiveGeofenceAssignmentsProvider);
          _manageRandomVerificationService(hasActiveGeofences);
          
          // Update geofence overlays after all data is loaded
          if (_mapController != null) {
            _updateGeofenceOverlays();
          }
          
          // Start tracking stats update timer
          _startTrackingStatsTimer();
        }
      });
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

  /// Check if we have sufficient cached data to avoid unnecessary API calls
  /// Returns true if cached data is available and recent enough
  Future<bool> _checkCachedData() async {
    try {
      if (kDebugMode) {
        print('🏠 CACHE CHECK: Checking for cached data availability');
      }

      // Check provider states for cached data
      final authState = ref.read(authProvider);
      final campaignState = ref.read(campaignProvider);
      final locationState = ref.read(locationProvider);
      // final paymentSummary = ref.read(paymentSummaryProvider); // Commented out - moved to Earnings tab

      // Check if rider data is loaded
      final hasRiderData = authState.rider != null;
      if (!hasRiderData) {
        if (kDebugMode) print('🏠 CACHE CHECK: No rider data found');
        return false;
      }

      // Check if we have campaign data (either available campaigns or current campaign)
      final hasCampaignData = campaignState.campaigns.isNotEmpty || campaignState.currentCampaign != null;
      if (!hasCampaignData) {
        if (kDebugMode) print('🏠 CACHE CHECK: No campaign data found');
        return false;
      }

      // Check if we have payment summary (earnings data) - COMMENTED OUT - moved to Earnings tab
      // final hasPaymentData = paymentSummary != null;
      // if (!hasPaymentData) {
      //   if (kDebugMode) print('🏠 CACHE CHECK: No payment summary found');
      //   return false;
      // }

      // Location data is optional but check if location permission state is known
      final hasLocationState = locationState.hasPermission != null;
      if (!hasLocationState) {
        if (kDebugMode) print('🏠 CACHE CHECK: Location permission state unknown');
        // Don't block on location data as it's not critical for initial display
      }

      // Check cache freshness - if data is older than 5 minutes, consider refreshing
      const maxCacheAge = Duration(minutes: 5);
      final now = DateTime.now();
      
      // Only force refresh if we have actual campaign data that appears fresh
      if (campaignState.myCampaigns.isNotEmpty || campaignState.availableCampaigns.isNotEmpty) {
        if (kDebugMode) print('🏠 CACHE CHECK: Found campaign data, using cached data');
        // We have data, assume it's fresh enough for now
        // TODO: Add proper timestamp-based cache validation if needed
        return true;
      }
      
      // Check when campaign data was last loaded (simplified check)
      // We'll assume if we have current campaign with active geofences, it's fresh enough
      if (campaignState.currentCampaign != null && campaignState.currentCampaign!.activeGeofences.isNotEmpty) {
        if (kDebugMode) print('🏠 CACHE CHECK: Current campaign with active geofences found');
      }

      // Final validation - only return true if we have essential data
      final hasEssentialData = hasRiderData && hasCampaignData;
      
      if (kDebugMode) {
        print('🏠 CACHE CHECK: Cache validation results:');
        print('🏠 - Rider data: $hasRiderData');
        print('🏠 - Campaign data: $hasCampaignData (${campaignState.campaigns.length} campaigns, current: ${campaignState.currentCampaign?.name ?? 'none'})');
        print('🏠 - Location state: $hasLocationState');
        print('🏠 - Has essential data: $hasEssentialData');
        
        if (hasEssentialData) {
          print('🏠 CACHE CHECK: All essential data available - using cached data');
        } else {
          print('🏠 CACHE CHECK: Missing essential data - will refresh');
        }
      }

      return hasEssentialData;
    } catch (e) {
      if (kDebugMode) {
        print('🏠 CACHE CHECK ERROR: $e');
      }
      return false;
    }
  }

  Future<void> _loadLocationData() async {
    try {
      if (kDebugMode) {
        print('🏠 LOCATION: Starting requestPermissions...');
      }

      // Wrap each call individually with timeout and error handling
      try {
        final permissionResult =
            await ref.read(locationProvider.notifier).requestPermissions();

        if (kDebugMode) {
          print(
              '🏠 LOCATION: requestPermissions completed, starting getCurrentLocation...');
        }
      } catch (e) {
        if (kDebugMode) {
          print('🏠 LOCATION ERROR: requestPermissions failed: $e');
        }
        return; // Skip getCurrentLocation if permissions failed
      }

      try {
        await ref
            .read(locationProvider.notifier)
            .getCurrentLocation()
            .timeout(const Duration(seconds: 20), onTimeout: () {
          if (kDebugMode) {
            print('🏠 LOCATION: getCurrentLocation timed out after 20 seconds');
          }
          throw TimeoutException(
              'Location request timed out', const Duration(seconds: 20));
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
      await ref
          .read(campaignProvider.notifier)
          .refresh()
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      // Campaign errors are non-critical - continue with cached data
      if (kDebugMode) {
        print('Campaign loading failed (non-critical): $e');
      }
    }
  }

  Future<void> _checkAndLoadCampaignData() async {
    try {
      final rider = ref.read(authProvider).rider;
      final currentCampaign = ref.read(campaignProvider).currentCampaign;
      
      // If rider has currentCampaignId but no current campaign is loaded,
      // this indicates a cache miss (likely after app reinstall)
      if (rider?.currentCampaignId != null && currentCampaign == null) {
        if (kDebugMode) {
          print('🏠 HOME SCREEN: Detected campaign cache miss. Rider has campaign ${rider?.currentCampaignId} but no loaded campaign. Refreshing...');
        }
        await ref
            .read(campaignProvider.notifier)
            .refresh()
            .timeout(const Duration(seconds: 15));
      }
    } catch (e) {
      if (kDebugMode) {
        print('🏠 HOME SCREEN: Campaign cache check failed (non-critical): $e');
      }
    }
  }

  // _loadEarningsData method commented out - earnings moved to Earnings tab
  // Future<void> _loadEarningsData() async {
  //   try {
  //     // Load earnings data with timeout and error isolation
  //     await ref
  //         .read(earningsProvider.notifier)
  //         .refresh()
  //         .timeout(const Duration(seconds: 15));
  //   } catch (e) {
  //     // Earnings errors are non-critical - continue with cached data
  //     if (kDebugMode) {
  //       print('Earnings loading failed (non-critical): $e');
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // Listen for changes in active campaigns with geofences and update overlays
    ref.listen<List<Campaign>>(
      activeCampaignsProvider,
      (previous, next) {
        if (mounted && _mapController != null) {
          _updateGeofenceOverlays();
        }
      },
    );

    // Listen for active geofence assignments and manage random verification service
    ref.listen<bool>(
      hasActiveGeofenceAssignmentsProvider,
      (previous, hasActiveGeofences) {
        if (mounted) {
          _manageRandomVerificationService(hasActiveGeofences);
        }
      },
    );

    // Listen for new verification requests and show verification screen
    ref.listen<VerificationRequest?>(
      currentVerificationRequestProvider,
      (previous, current) {
        if (mounted && current != null && previous?.id != current.id) {
          if (kDebugMode) {
            print('🎯 HOME SCREEN: New verification request detected: ${current.id}');
          }
          _showVerificationDialog(current);
        }
      },
    );

    // Reduced debug logging to prevent spam
    // if (kDebugMode) {
    //   print('🏠 HOME BUILD: Starting build method');
    // }

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

    // Load providers
    late final AuthState authState;
    late final CampaignState campaignState;
    late final LocationState locationState;
    // late final PaymentSummary? paymentSummary; // Commented out - moved to Earnings tab
    late final Rider? rider;
    late final Campaign? activeCampaign;

    try {
      authState = ref.watch(authProvider);
      campaignState = ref.watch(campaignProvider);
      locationState = ref.watch(locationProvider);
      // paymentSummary = ref.watch(paymentSummaryProvider); // Commented out - moved to Earnings tab

      rider = authState.rider;
      activeCampaign = campaignState.currentCampaign;
      
      if (kDebugMode) {
        print('🏠 HOME BUILD: Provider data loaded');
        print('🏠 HOME BUILD: Rider currentCampaignId: ${rider?.currentCampaignId}');
        print('🏠 HOME BUILD: Active campaign: ${activeCampaign?.name ?? 'null'}');
        print('🏠 HOME BUILD: Campaign state campaigns: ${campaignState.campaigns.length}');
        print('🏠 HOME BUILD: Will show campaign card: ${activeCampaign != null}');
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
            rider != null ? 'Welcome, ${_getWelcomeText(rider)}!' : 'Welcome!',
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
              icon:
                  const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
            IconButton(
              onPressed: () => _refreshHomeData(),
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: RefreshIndicator(
            onRefresh: _refreshHomeData, // Use force refresh for pull-to-refresh
            child: Stack(children: [
              // Google Maps as background
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    locationState.currentPosition?.latitude ??
                        6.5244, // Lagos default
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
                  if (kDebugMode) {
                    print('🗺️ MAP: Google Map created, setting controller and updating overlays');
                  }
                  _mapController = controller;
                  _updateGeofenceOverlays();
                },
              ),

              // Overlay cards on top of map
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Compact Active Campaign card (shown when campaign is active)
                      if (activeCampaign != null && activeCampaign.activeGeofences.isNotEmpty)
                        _buildCompactCampaignCard(activeCampaign, locationState),

                      // Rider status card (only shown when no active campaign)
                      if (activeCampaign == null && rider != null)
                        RiderStatusCard(
                          rider: rider,
                          onActivationSuccess: () {
                            // Refresh data after successful activation
                            setState(() {
                              _isInitialLoading = true;
                            });
                            _loadInitialData();
                          },
                        ),

                      // Debug info card (only in debug mode with toggle)
                      if (kDebugMode) ...[
                        // Debug toggle button
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Debug Info',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showDebugCard = !_showDebugCard;
                                  });
                                },
                                icon: Icon(
                                  _showDebugCard ? Icons.visibility_off : Icons.visibility,
                                  size: 16,
                                ),
                                label: Text(
                                  _showDebugCard ? 'Hide' : 'Show',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Debug card content (collapsible)
                        if (_showDebugCard)
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
                                      Text('Debug Info:',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _showDebugCard = false;
                                          });
                                        },
                                        icon: const Icon(Icons.close, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                                Text('Rider: ${rider?.firstName ?? 'null'}'),
                                Text('Status: ${rider?.status ?? 'null'}'),
                                Text(
                                    'Verification: ${rider?.verificationStatus ?? 'null'}'),
                                Text(
                                    'Campaigns: ${campaignState.campaigns.length}'),
                                // Text('Payment Summary: ${paymentSummary != null ? 'loaded' : 'null'}'), // Commented out - moved to Earnings tab
                                Text(
                                    'Location: ${locationState.currentPosition != null ? 'available' : 'unavailable'}'),
                                if (locationState.currentPosition != null) ...[
                                  Text(
                                      '  Coordinates: ${locationState.currentPosition!.latitude.toStringAsFixed(4)}, ${locationState.currentPosition!.longitude.toStringAsFixed(4)}'),
                                  Text(
                                      '  Accuracy: ${locationState.currentPosition!.accuracy.toStringAsFixed(1)}m'),
                                ],
                                Text(
                                    'Permission: ${locationState.hasPermission ? 'granted' : 'denied'}'),
                                Text(
                                    'Tracking: ${locationState.isTracking ? 'active' : 'inactive'}'),
                                if (locationState.currentPosition != null) ...[
                                  Text('  Speed: ${(locationState.currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h'),
                                  Text('  Heading: ${locationState.currentPosition!.heading.toStringAsFixed(0)}°'),
                                  Text('  Altitude: ${locationState.currentPosition!.altitude.toStringAsFixed(0)}m'),
                                ],
                                if (locationState.error != null)
                                  Text('Error: ${locationState.error}',
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 12)),
                                const Divider(),
                                Text('Tracking Status:',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Movement Threshold: ${AppConstants.movementThresholdMeters}m'),
                                Text('Update Interval: ${AppConstants.locationUpdateIntervalSeconds}s'),
                                Text('Stationary Timeout: ${AppConstants.stationaryIntervalMinutes}min'),
                                if (activeCampaign != null) ...[
                                  Text('Active Campaign: ${activeCampaign!.name}'),
                                  Text('Campaign Status: ${activeCampaign!.status}'),
                                ],
                                const Divider(),
                                Text('Random Verification Service:',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Service Running: ${_randomVerificationService?.isRunning ?? false}'),
                                Text('Has Active Geofences: ${ref.watch(hasActiveGeofenceAssignmentsProvider)}'),
                                Text('Active Verification: ${ref.watch(hasActiveVerificationProvider)}'),
                                if (_randomVerificationService?.nextCheckTime != null)
                                  _buildNextCheckCountdown(_randomVerificationService!.nextCheckTime!),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ]
          )
        )
      );
  }

  Widget _buildCompactCampaignCard(Campaign campaign, LocationState locationState) { // Removed PaymentSummary parameter
    // Find active geofence assignment for better display
    final activeGeofenceAssignment = campaign.primaryActiveGeofence ?? 
        (campaign.activeGeofences.isNotEmpty ? campaign.activeGeofences.first : null);
    
    // Fallback to regular geofence if no assignment
    final activeGeofence = campaign.geofences.isNotEmpty 
        ? campaign.geofences.first 
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Reduced from 16 to 8 to push card up
      height: MediaQuery.of(context).size.height * 0.25, // Increased from 0.24 to 0.25 to fix 2px overflow
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          padding: const EdgeInsets.all(14), // Reduced from 16 to 14
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with campaign name and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.campaign,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.name ?? 'Active Campaign',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Show geofence assignment name if available, otherwise fall back to geofence name
                        if (activeGeofenceAssignment != null)
                          Text(
                            activeGeofenceAssignment.geofenceName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else if (activeGeofence != null)
                          Text(
                            activeGeofence.name ?? 'Area',
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8), // Reduced from 12 to 8
              
              // Geofence Assignment Info Section (NEW)
              if (activeGeofenceAssignment != null) ...[
                Container(
                  padding: const EdgeInsets.all(10), // Reduced from 12 to 10
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          const Text(
                            'Assignment Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                          const Spacer(),
                          // Tracking status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: locationState.isTracking ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  locationState.isTracking ? Icons.gps_fixed : Icons.gps_off,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  locationState.isTracking ? 'Tracking' : 'Not Tracking',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6), // Reduced from 8 to 6
                      _buildLiveTrackingStats(locationState, activeGeofenceAssignment),
                    ],
                  ),
                ),
                const SizedBox(height: 8), // Reduced from 12 to 8
              ],
              
              // Earnings summary removed - moved to Earnings tab
            ],
          ),
        ),
      ),
    );
  }

  // _buildEarningsStat method removed - earnings moved to Earnings tab

  Widget _buildLiveTrackingStats(LocationState locationState, GeofenceAssignment? activeGeofenceAssignment) {
    // Get real-time tracking data from live tracking stats provider (auto-refreshes)
    final trackingStats = ref.watch(liveTrackingStatsProvider);
    
    // Calculate current session data if in a geofence
    double currentGeofenceDistance = 0.0;
    int currentGeofenceMinutes = 0;
    if (trackingStats.currentGeofence != null && trackingStats.currentGeofenceId != null) {
      currentGeofenceDistance = (trackingStats.geofenceDistances[trackingStats.currentGeofenceId!] ?? 0.0) / 1000.0; // Convert to km
      currentGeofenceMinutes = (trackingStats.geofenceDurations[trackingStats.currentGeofenceId!] ?? Duration.zero).inMinutes;
    }
    
    // Use live data if tracking is active, fallback to assignment data
    final displayDistance = locationState.isTracking 
        ? (trackingStats.totalDistance / 1000.0).toStringAsFixed(1) // Convert meters to km
        : (activeGeofenceAssignment?.distanceCovered ?? 0.0).toStringAsFixed(1);
    
    final displayEarnings = locationState.isTracking 
        ? trackingStats.totalGeofenceEarnings.toStringAsFixed(2) // Show more precision for debugging
        : (activeGeofenceAssignment?.amountEarned ?? 0.0).toStringAsFixed(2);
    
    // Get rate and rate type information for better display
    final currentGeofence = trackingStats.currentGeofence;
    final rateType = currentGeofence?.rateType ?? 'unknown';
    final ratePerKm = currentGeofence?.ratePerKm ?? activeGeofenceAssignment?.ratePerKm ?? 0.0;
    final ratePerHour = currentGeofence?.ratePerHour ?? 0.0;
    
    // Create rate display based on rate type
    String displayRate;
    if (rateType == 'per_km') {
      displayRate = '₦${ratePerKm.toStringAsFixed(0)}/km';
    } else if (rateType == 'per_hour') {
      displayRate = '₦${ratePerHour.toStringAsFixed(0)}/hr';
    } else if (rateType == 'hybrid') {
      displayRate = '₦${ratePerKm.toStringAsFixed(0)}/km + ₦${ratePerHour.toStringAsFixed(0)}/hr';
    } else if (rateType == 'fixed_daily') {
      final dailyRate = currentGeofence?.fixedDailyRate ?? 0.0;
      displayRate = '₦${dailyRate.toStringAsFixed(0)}/day';
    } else {
      displayRate = '₦${ratePerKm.toStringAsFixed(0)}/km';
    }
    
    return Column(
      children: [
        // Main stats row
        Row(
          children: [
            Expanded(
              child: _buildAssignmentStat(
                'Distance',
                '${displayDistance} km',
                Icons.straighten,
                isLive: locationState.isTracking,
              ),
            ),
            Container(
              width: 1,
              height: 28,
              color: Colors.blue.withOpacity(0.3),
            ),
            Expanded(
              child: _buildAssignmentStat(
                'Rate',
                displayRate,
                Icons.attach_money,
                isLive: false, // Rate doesn't change in real-time
              ),
            ),
            Container(
              width: 1,
              height: 28,
              color: Colors.blue.withOpacity(0.3),
            ),
            Expanded(
              child: _buildAssignmentStat(
                'Earned',
                '₦${displayEarnings}',
                Icons.account_balance_wallet,
                isLive: locationState.isTracking,
                subtitle: trackingStats.isWithinGeofence 
                    ? 'In geofence' 
                    : (locationState.isTracking ? 'Outside geofence' : null),
              ),
            ),
          ],
        ),
        
        // Current geofence session info (if in geofence and tracking)
        // if (locationState.isTracking && trackingStats.isWithinGeofence && trackingStats.currentGeofence != null) ...[
        //   const SizedBox(height: 6),
        //   Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        //     decoration: BoxDecoration(
        //       color: Colors.green.withOpacity(0.1),
        //       borderRadius: BorderRadius.circular(6),
        //       border: Border.all(color: Colors.green.withOpacity(0.3)),
        //     ),
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //         Icon(Icons.location_on, size: 10, color: Colors.green),
        //         const SizedBox(width: 4),
        //         Text(
        //           'In ${trackingStats.currentGeofence.name}',
        //           style: const TextStyle(
        //             fontSize: 9,
        //             fontWeight: FontWeight.w600,
        //             color: Colors.green,
        //           ),
        //         ),
        //         const SizedBox(width: 8),
        //         Text(
        //           '${currentGeofenceDistance.toStringAsFixed(1)}km',
        //           style: const TextStyle(
        //             fontSize: 9,
        //             fontWeight: FontWeight.bold,
        //             color: Colors.green,
        //           ),
        //         ),
        //         if (currentGeofenceMinutes > 0) ...[
        //           const SizedBox(width: 8), 
        //           Icon(Icons.access_time, size: 10, color: Colors.green),
        //           const SizedBox(width: 2),
        //           Text(
        //             '${currentGeofenceMinutes}min',
        //             style: const TextStyle(
        //               fontSize: 9,
        //               fontWeight: FontWeight.bold,
        //               color: Colors.green,
        //             ),
        //           ),
        //         ],
        //       ],
        //     ),
        //   ),
        // ],
      ],
    );
  }

  Widget _buildAssignmentStat(String label, String value, IconData icon, {bool isLive = false, String? subtitle}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 12,
              color: Colors.blue,
            ),
            if (isLive) ...[
              const SizedBox(width: 2),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isLive ? Colors.green : Colors.blue,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 7,
              color: subtitle.contains('Outside') ? Colors.orange : Colors.green,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String _getWelcomeText(Rider rider) {
    // Priority order: firstName, lastName, riderId (STK-R-XXXXX format), phoneNumber
    if (rider.firstName != null && rider.firstName!.isNotEmpty) {
      return rider.firstName!;
    }
    if (rider.lastName != null && rider.lastName!.isNotEmpty) {
      return rider.lastName!;
    }
    if (rider.riderId != null && rider.riderId!.isNotEmpty) {
      return rider.riderId!;
    }
    if (rider.phoneNumber.isNotEmpty) {
      return rider.phoneNumber;
    }
    return 'Rider';
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

  /// Load tracking statistics from backend
  Future<void> _loadTrackingStats() async {
    try {
      if (kDebugMode) print('🏠 HOME: Loading tracking statistics...');
      
      final trackingStats = await _locationApiService?.getTrackingStats();
      
      if (trackingStats != null && mounted) {
        setState(() {
          _trackingStats = trackingStats;
        });
        
        if (kDebugMode) {
          print('🏠 HOME: Tracking stats loaded successfully');
          print('🏠 - Today distance: ${trackingStats['today_distance']} km');
          print('🏠 - Today earnings: ₦${trackingStats['today_earnings']}');
          print('🏠 - Active geofences: ${trackingStats['active_geofences']}');
          print('🏠 - Pending sync: ${trackingStats['pending_sync_count']}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🏠 HOME: Failed to load tracking stats: $e');
      }
      // Don't show error to user as this is supplementary data
    }
  }

  /// Force refresh data - called by the refresh button
  /// This bypasses cache and always fetches fresh data
  Future<void> _refreshHomeData() async {
    // Prevent duplicate refresh calls
    if (_isRefreshing) {
      if (kDebugMode) print('🏠 HOME: Refresh already in progress, skipping duplicate call');
      return;
    }
    
    _isRefreshing = true;
    if (kDebugMode) print('🏠 HOME: Force refreshing home data (bypass cache)...');
    
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refreshing data...'),
          duration: Duration(seconds: 1),
          backgroundColor: AppColors.primary,
        ),
      );
    }

    try {
      // Enhanced refresh that includes myCampaigns endpoint
      // This method always fetches fresh data regardless of cache
      if (kDebugMode) print('🏠 HOME: Step 1: Loading location data...');
      await _loadLocationData();

      if (kDebugMode) print('🏠 HOME: Step 2: Loading my campaigns (including active geofence assignments)...');
      await Future.delayed(const Duration(milliseconds: 300));
      await ref.read(campaignProvider.notifier).loadMyCampaigns();

      if (kDebugMode) print('🏠 HOME: Step 3: Loading available campaigns...');
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadCampaignData();

      // if (kDebugMode) print('🏠 HOME: Step 4: Loading earnings data...'); // Commented out - moved to Earnings tab
      // await Future.delayed(const Duration(milliseconds: 300));
      // await _loadEarningsData();

      if (kDebugMode) print('🏠 HOME: Step 4: Loading tracking statistics...');
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadTrackingStats();
      
      if (kDebugMode) print('🏠 HOME: Force refresh completed successfully');
      
      // Restart verification service and update map overlays after refresh
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final hasActiveGeofences = ref.read(hasActiveGeofenceAssignmentsProvider);
          _manageRandomVerificationService(hasActiveGeofences);
          
          // Update map overlays with refreshed geofence data
          _updateGeofenceOverlays();
        }
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data refreshed successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('🏠 HOME: Force refresh failed: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always reset refresh flag
      _isRefreshing = false;
    }
  }

  void _updateGeofenceOverlays() {
    if (kDebugMode) {
      print('🗺️ MAP: _updateGeofenceOverlays called, mapController: ${_mapController != null ? 'available' : 'null'}');
    }
    
    if (_mapController == null) {
      if (kDebugMode) {
        print('🗺️ MAP: No map controller, skipping geofence overlay update');
      }
      return;
    }

    // Get campaigns with active geofence assignments from myCampaigns
    final activeCampaigns = ref.read(activeCampaignsProvider);
    // Get available campaigns (with full geofence details) from availableCampaigns
    final availableCampaigns = ref.read(campaignProvider).availableCampaigns;
    
    if (kDebugMode) {
      print('🗺️ MAP: Active campaigns count: ${activeCampaigns.length}');
      print('🗺️ MAP: Available campaigns count: ${availableCampaigns.length}');
      for (final campaign in activeCampaigns) {
        print('🗺️ MAP: - Active Campaign: ${campaign.name}, active geofences: ${campaign.currentActiveGeofences.length}');
      }
    }

    if (activeCampaigns.isEmpty) {
      if (_geofenceCircles.isNotEmpty || _geofenceMarkers.isNotEmpty) {
        setState(() {
          _geofenceCircles.clear();
          _geofenceMarkers.clear();
        });
      }
      return;
    }

    final circles = <Circle>{};
    final markers = <Marker>{};

    // Iterate through all active campaigns and their geofence assignments
    for (final activeCampaign in activeCampaigns) {
      if (kDebugMode) {
        print('🗺️ MAP: Processing active campaign: ${activeCampaign.name}');
      }
      
      for (final geofenceAssignment in activeCampaign.currentActiveGeofences) {
        if (kDebugMode) {
          print('🗺️ MAP: Processing geofence assignment: ${geofenceAssignment.geofenceName} (ID: ${geofenceAssignment.geofenceId})');
          print('🗺️ MAP: Assignment data - centerLat: ${geofenceAssignment.centerLatitudeCamelCase ?? geofenceAssignment.centerLatitude}, centerLng: ${geofenceAssignment.centerLongitudeCamelCase ?? geofenceAssignment.centerLongitude}, radius: ${geofenceAssignment.radius ?? geofenceAssignment.radiusMeters}');
        }
        
        // Use geofence assignment data directly (now includes all display properties from backend)
        final geofenceId = geofenceAssignment.geofenceId;
        if (kDebugMode) {
          print('🗺️ MAP: ✅ Using assignment data for geofence: ${geofenceAssignment.geofenceName}');
        }

        // Create circle overlay for geofence boundary using assignment data
        final circle = Circle(
          circleId: CircleId(geofenceId),
          center: LatLng(
            geofenceAssignment.centerLatitudeCamelCase ?? geofenceAssignment.centerLatitude,
            geofenceAssignment.centerLongitudeCamelCase ?? geofenceAssignment.centerLongitude,
          ),
          radius: (geofenceAssignment.radius ?? geofenceAssignment.radiusMeters).toDouble(),
          fillColor: Color(geofenceAssignment.displayColor ?? 0xFF4CAF50)
              .withOpacity((geofenceAssignment.displayAlpha ?? 1.0) * 0.2),
          strokeColor: Color(geofenceAssignment.displayColor ?? 0xFF4CAF50)
              .withOpacity(geofenceAssignment.displayAlpha ?? 1.0),
          strokeWidth: (geofenceAssignment.isHighPriority ?? false) ? 3 : 2,
        );
        circles.add(circle);
        if (kDebugMode) {
          print('🗺️ MAP: ✅ Added circle for geofence: ${geofenceAssignment.geofenceName}');
        }

        // Create marker for geofence center with earnings info
        final marker = Marker(
          markerId: MarkerId(geofenceId),
          position: LatLng(
            geofenceAssignment.centerLatitudeCamelCase ?? geofenceAssignment.centerLatitude,
            geofenceAssignment.centerLongitudeCamelCase ?? geofenceAssignment.centerLongitude,
          ),
          icon: (geofenceAssignment.isHighPriority ?? false)
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: geofenceAssignment.geofenceName ?? 'Geofence',
            snippet: _getGeofenceAssignmentInfoSnippet(geofenceAssignment),
          ),
          onTap: () => _showGeofenceAssignmentDetails(geofenceAssignment),
        );
        markers.add(marker);
        if (kDebugMode) {
          print('🗺️ MAP: ✅ Added marker for geofence: ${geofenceAssignment.geofenceName}');
        }
      }
    }

    if (kDebugMode) {
      print('🗺️ MAP: Total circles created: ${circles.length}');
      print('🗺️ MAP: Total markers created: ${markers.length}');
    }

    // Only update state if there are actual changes
    if (!_setsEqual(_geofenceCircles, circles) ||
        !_setsEqual(_geofenceMarkers, markers)) {
      if (kDebugMode) {
        print('🗺️ MAP: Updating map overlays - circles: ${circles.length}, markers: ${markers.length}');
      }
      setState(() {
        _geofenceCircles = circles;
        _geofenceMarkers = markers;
      });
    } else {
      if (kDebugMode) {
        print('🗺️ MAP: No changes detected, skipping overlay update');
      }
    }

    // Adjust camera to show all active geofence assignments
    final allAssignments = <GeofenceAssignment>[];
    for (final campaign in activeCampaigns) {
      allAssignments.addAll(campaign.currentActiveGeofences);
    }
    if (allAssignments.isNotEmpty) {
      _fitCameraToGeofenceAssignments(allAssignments);
    }
  }

  // Helper method to compare sets for equality
  bool _setsEqual<T>(Set<T> set1, Set<T> set2) {
    if (set1.length != set2.length) return false;
    return set1.containsAll(set2);
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            _buildInfoRow(
                'Rate Type', (geofence.rateType ?? 'per_km').toUpperCase()),
            if ((geofence.rateType ?? 'per_km') == 'per_km' ||
                (geofence.rateType ?? 'per_km') == 'hybrid')
              _buildInfoRow('Per Kilometer', '₦${geofence.ratePerKm ?? 0.0}'),
            if ((geofence.rateType ?? 'per_km') == 'per_hour' ||
                (geofence.rateType ?? 'per_km') == 'hybrid')
              _buildInfoRow('Per Hour', '₦${geofence.ratePerHour ?? 0.0}'),
            if ((geofence.rateType ?? 'per_km') == 'fixed_daily')
              _buildInfoRow('Daily Rate', '₦${geofence.fixedDailyRate ?? 0.0}'),

            const SizedBox(height: 8),

            // Availability Information
            _buildInfoRow('Available Slots', '${geofence.availableSlots ?? 0}'),
            _buildInfoRow('Current Riders',
                '${geofence.currentRiders ?? 0}/${geofence.maxRiders ?? 0}'),
            _buildInfoRow('Fill Percentage',
                '${(geofence.fillPercentage ?? 0.0).toStringAsFixed(1)}%'),

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
                    onPressed: geofence.canAcceptRiders
                        ? () {
                            Navigator.pop(context);
                            _navigateToGeofence(geofence);
                          }
                        : null,
                    child: Text(geofence.canAcceptRiders
                        ? 'Navigate Here'
                        : 'Area Full'),
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

  void _fitCameraToGeofenceAssignments(List<GeofenceAssignment> assignments) {
    if (_mapController == null || assignments.isEmpty) return;

    if (assignments.length == 1) {
      // Single assignment - center on it
      final assignment = assignments.first;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              assignment.centerLatitudeCamelCase ?? assignment.centerLatitude,
              assignment.centerLongitudeCamelCase ?? assignment.centerLongitude,
            ),
            zoom: 14.0,
          ),
        ),
      );
      return;
    }

    // Multiple assignments - fit bounds
    double minLat = assignments.first.centerLatitudeCamelCase ?? assignments.first.centerLatitude;
    double maxLat = assignments.first.centerLatitudeCamelCase ?? assignments.first.centerLatitude;
    double minLng = assignments.first.centerLongitudeCamelCase ?? assignments.first.centerLongitude;
    double maxLng = assignments.first.centerLongitudeCamelCase ?? assignments.first.centerLongitude;

    for (final assignment in assignments) {
      final lat = assignment.centerLatitudeCamelCase ?? assignment.centerLatitude;
      final lng = assignment.centerLongitudeCamelCase ?? assignment.centerLongitude;
      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
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

  /// Manage random verification service lifecycle based on geofence assignments
  void _manageRandomVerificationService(bool hasActiveGeofences) {
    if (hasActiveGeofences) {
      // Start random verification service when rider has active geofence assignments
      if (_randomVerificationService == null || !_randomVerificationService!.isRunning) {
        if (kDebugMode) {
          print('🎯 HOME SCREEN: Starting random verification service (rider has active geofences)');
          print('🎯 Current service state: ${_randomVerificationService?.isRunning ?? 'null'}');
        }
        
        // Only get a fresh reference if we don't have a service or it's not running
        if (_randomVerificationService == null) {
          _randomVerificationService = ref.read(randomVerificationBackgroundServiceProvider);
        }
        
        // Ensure the service is running (handle case where service exists but was stopped)
        if (!_randomVerificationService!.isRunning) {
          _randomVerificationService!.start();
          if (kDebugMode) {
            print('🎯 HOME SCREEN: Started verification service');
          }
        }
        
        if (kDebugMode) {
          print('🎯 HOME SCREEN: Random verification service ensured running: ${_randomVerificationService!.isRunning}');
        }
      } else {
        if (kDebugMode) {
          print('🎯 HOME SCREEN: Verification service already running');
        }
      }
    } else {
      // RESILIENCE FIX: Only stop service if we're confident there are no active geofences
      // Don't stop during temporary state transitions (like during refresh)
      if (_randomVerificationService != null && _randomVerificationService!.isRunning) {
        // Double-check the provider state to avoid stopping during refresh
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            final hasActiveGeofencesDelayed = ref.read(hasActiveGeofenceAssignmentsProvider);
            if (!hasActiveGeofencesDelayed && _randomVerificationService != null && _randomVerificationService!.isRunning) {
              if (kDebugMode) {
                print('🎯 HOME SCREEN: Stopping random verification service (confirmed no active geofences)');
              }
              
              _randomVerificationService!.stop();
              
              if (kDebugMode) {
                print('🎯 HOME SCREEN: Random verification service stopped');
              }
            } else if (hasActiveGeofencesDelayed) {
              if (kDebugMode) {
                print('🎯 HOME SCREEN: Keeping verification service running (active geofences detected after delay)');
              }
            }
          }
        });
      }
    }
  }

  /// Show verification dialog when a random verification is triggered
  void _showVerificationDialog(VerificationRequest request) {
    if (kDebugMode) {
      print('🎯 HOME SCREEN: Showing verification dialog for request ${request.id}');
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Cannot dismiss randomly triggered verifications
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.verified_user,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Verification Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have been randomly selected for verification to ensure your presence in the geofence area.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Time remaining: ${_formatTimeRemaining(request.deadline)}',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToVerificationScreen(request);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Verification'),
          ),
        ],
      ),
    );
  }

  /// Navigate to verification screen
  void _navigateToVerificationScreen(VerificationRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VerificationScreen(request: request),
        fullscreenDialog: true,
      ),
    );
  }

  /// Build countdown widget for next check time
  Widget _buildNextCheckCountdown(DateTime nextCheckTime) {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final remaining = nextCheckTime.difference(now);
        
        if (remaining.isNegative) {
          return const Text(
            'Next Check: Checking now...',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          );
        }
        
        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;
        
        return Text(
          'Next Check: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: minutes < 5 ? Colors.orange : Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }

  /// Format time remaining until deadline
  String _formatTimeRemaining(DateTime deadline) {
    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    
    if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes} minutes';
    } else {
      return '${remaining.inSeconds} seconds';
    }
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getGeofenceAssignmentInfoSnippet(GeofenceAssignment assignment) {
    final rateInfo = '₦${assignment.ratePerKm ?? 0.0}/km';
    final earnings = '₦${assignment.amountEarned ?? 0.0} earned';
    return '$rateInfo • $earnings';
  }

  void _showGeofenceAssignmentDetails(GeofenceAssignment assignment) {
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
                    color: Color(assignment.displayColor ?? 0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    assignment.geofenceName ?? 'Geofence',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (assignment.isHighPriority ?? false)
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

            // Assignment Information
            _buildInfoRow('Status', assignment.status.displayName),
            _buildInfoRow('Rate per KM', '₦${assignment.ratePerKm ?? 0.0}'),
            _buildInfoRow('Rate per Hour', '₦${assignment.ratePerHour ?? 0.0}'),
            _buildInfoRow('Amount Earned', '₦${assignment.amountEarned ?? 0.0}'),

            const SizedBox(height: 8),

            // Location Information
            _buildInfoRow('Center', '${(assignment.centerLatitudeCamelCase ?? assignment.centerLatitude)?.toStringAsFixed(4)}, ${(assignment.centerLongitudeCamelCase ?? assignment.centerLongitude)?.toStringAsFixed(4)}'),
            _buildInfoRow('Radius', '${assignment.radius ?? assignment.radiusMeters}m'),

            const SizedBox(height: 16),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up tracking stats timer
    _trackingStatsUpdateTimer?.cancel();
    _trackingStatsUpdateTimer = null;
    
    // Don't stop the verification service on dispose - it should continue running in background
    // The service will be managed by the provider's lifecycle and business logic
    if (kDebugMode) {
      print('🎯 HOME SCREEN: Disposing home screen (keeping verification service running)');
    }
    super.dispose();
  }

  /// Start timer to update tracking stats UI periodically when tracking is active
  /// NOTE: This is now handled automatically by liveTrackingStatsProvider
  void _startTrackingStatsTimer() {
    // Timer no longer needed - auto-refresh provider handles this
    _trackingStatsUpdateTimer?.cancel();
    _trackingStatsUpdateTimer = null;
    
    if (kDebugMode) {
      print('🏠 Tracking stats timer disabled - using auto-refresh provider instead');
    }
  }
}

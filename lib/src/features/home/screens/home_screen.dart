import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stika_rider/src/core/models/payment_summary.dart';
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
      
      if (kDebugMode) {
        print('🏠 HOME BUILD: All providers loaded successfully');
        print('🏠 Rider: ${rider?.firstName ?? 'null'}');
        print('🏠 Campaigns: ${campaignState.campaigns.length}');
        print('🏠 Payment Summary: ${paymentSummary != null ? 'loaded' : 'null'}');
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Debug info
                if (kDebugMode)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Debug Info:', style: Theme.of(context).textTheme.titleMedium),
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
                
                // Quick Stats (simplified)
                if (paymentSummary != null)
                  Card(
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
                
                // Campaigns info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Campaigns', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (campaignState.isLoading)
                          const Text('Loading campaigns...')
                        else if (campaignState.campaigns.isEmpty)
                          const Text('No campaigns available')
                        else
                          Text('${campaignState.campaigns.length} campaigns available'),
                        
                        if (activeCampaign != null) ...[
                          const SizedBox(height: 8),
                          Text('Active: ${activeCampaign.name}'),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Quick actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _showProfile,
                          child: const Text('View Profile'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
}
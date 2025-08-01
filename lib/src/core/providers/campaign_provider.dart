import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/campaign.dart';
import '../services/campaign_service.dart';
import '../storage/hive_service.dart';
import 'location_provider.dart';

// Campaign state class
class CampaignState {
  final List<Campaign> myCampaigns; // Campaigns with assignments (from /my-campaigns)
  final List<Campaign> availableCampaigns; // Campaigns available for joining (from /campaigns)
  final Campaign? currentCampaign;
  final Geofence? currentGeofence;
  final bool isLoading;
  final bool isJoining;
  final String? error;

  const CampaignState({
    this.myCampaigns = const [],
    this.availableCampaigns = const [],
    this.currentCampaign,
    this.currentGeofence,
    this.isLoading = false,
    this.isJoining = false,
    this.error,
  });

  CampaignState copyWith({
    List<Campaign>? myCampaigns,
    List<Campaign>? availableCampaigns,
    Campaign? currentCampaign,
    Geofence? currentGeofence,
    bool? isLoading,
    bool? isJoining,
    String? error,
  }) {
    return CampaignState(
      myCampaigns: myCampaigns ?? this.myCampaigns,
      availableCampaigns: availableCampaigns ?? this.availableCampaigns,
      currentCampaign: currentCampaign ?? this.currentCampaign,
      currentGeofence: currentGeofence ?? this.currentGeofence,
      isLoading: isLoading ?? this.isLoading,
      isJoining: isJoining ?? this.isJoining,
      error: error,
    );
  }
  
  // Convenience getters for backward compatibility and clarity
  List<Campaign> get campaigns => [...myCampaigns, ...availableCampaigns]; // Combined for backward compatibility
  List<Campaign> get activeCampaignsWithAssignments => myCampaigns.where((c) => c.hasActiveGeofenceAssignments).toList();
}

// Campaign state notifier
class CampaignNotifier extends StateNotifier<CampaignState> {
  final CampaignService _campaignService;
  final Ref _ref;

  CampaignNotifier(this._campaignService, this._ref) : super(const CampaignState()) {
    _loadCachedData();
  }

  void _loadCachedData() {
    // Load cached campaigns from Hive
    final campaigns = HiveService.getCampaigns();
    final rider = HiveService.getRider();
    
    if (kDebugMode) {
      print('🎯 CAMPAIGN PROVIDER: Loading cached data...');
      print('🎯 CAMPAIGN PROVIDER: Found ${campaigns.length} cached campaigns');
      print('🎯 CAMPAIGN PROVIDER: Rider currentCampaignId: ${rider?.currentCampaignId}');
      if (campaigns.isNotEmpty) {
        print('🎯 CAMPAIGN PROVIDER: Cached campaign IDs: ${campaigns.map((c) => c.id).toList()}');
      }
    }
    
    Campaign? currentCampaign;
    bool needsRefresh = false;
    
    if (rider?.currentCampaignId != null) {
      currentCampaign = campaigns
          .where((c) => c.id == rider!.currentCampaignId)
          .firstOrNull;
      
      // If rider has currentCampaignId but no cached campaign details,
      // we need to fetch from server (likely after app reinstall)
      if (currentCampaign == null) {
        if (kDebugMode) {
          print('🎯 CAMPAIGN CACHE MISS: Rider has currentCampaignId ${rider?.currentCampaignId} but no cached campaign. Will refresh from server.');
        }
        needsRefresh = true;
      } else {
        if (kDebugMode) {
          print('🎯 CAMPAIGN CACHE HIT: Found current campaign ${currentCampaign.id} - ${currentCampaign.name}');
        }
      }
    } else {
      if (kDebugMode) {
        print('🎯 CAMPAIGN PROVIDER: Rider has no currentCampaignId');
      }
    }

    // Load cached myCampaigns (campaigns with assignments)
    List<Campaign> cachedMyCampaigns = [];
    try {
      final cachedMyCampaignsJson = HiveService.getSetting<List<dynamic>>('my_campaigns_cache');
      if (cachedMyCampaignsJson != null) {
        cachedMyCampaigns = cachedMyCampaignsJson
            .map((json) => Campaign.fromMyCampaignsJson(json as Map<String, dynamic>))
            .toList();
        if (kDebugMode) {
          print('🎯 CAMPAIGN PROVIDER: Loaded ${cachedMyCampaigns.length} cached myCampaigns with assignments');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🎯 CAMPAIGN PROVIDER: Failed to load cached myCampaigns: $e');
      }
    }

    if (kDebugMode) {
      print('🎯 CAMPAIGN PROVIDER: Initial state update - availableCampaigns: ${campaigns.length}, myCampaigns: ${cachedMyCampaigns.length}, currentCampaign: ${currentCampaign?.name ?? 'null'}');
    }
    
    state = state.copyWith(
      availableCampaigns: campaigns,
      myCampaigns: cachedMyCampaigns,
      currentCampaign: currentCampaign,
    );
    
    // Automatically fetch campaigns if we detected a cache miss
    if (needsRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (kDebugMode) {
          print('🎯 CAMPAIGN AUTO-REFRESH: Fetching campaigns due to cache miss');
        }
        // Load from my-campaigns endpoint to get assignment data
        loadMyCampaigns();
      });
    }
  }

  Future<void> loadAvailableCampaigns({bool forceRefresh = false}) async {
    if (kDebugMode) {
      print('🎯 LOADING CAMPAIGNS: Starting campaign load (forceRefresh: $forceRefresh)');
      print('🎯 Current state: campaigns=${state.campaigns.length}, myCampaigns=${state.myCampaigns.length}, availableCampaigns=${state.availableCampaigns.length}, isLoading=${state.isLoading}');
    }
    
    // Prevent concurrent loading
    if (state.isLoading) {
      if (kDebugMode) {
        print('🎯 CAMPAIGNS LOAD BLOCKED: Already loading');
      }
      return;
    }
    
    // Check cache freshness unless force refresh is requested
    if (!forceRefresh && _isAvailableCampaignsCacheFresh()) {
      if (kDebugMode) {
        print('🎯 CAMPAIGNS LOAD SKIPPED: Cache is still fresh');
      }
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      if (kDebugMode) print('🎯 Calling campaign service...');
      final campaigns = await _campaignService.getAvailableCampaigns();
      
      if (kDebugMode) {
        print('🎯 CAMPAIGNS LOADED: ${campaigns.length} campaigns received');
        if (campaigns.isNotEmpty) {
          for (int i = 0; i < campaigns.length && i < 3; i++) {
            print('🎯 Campaign $i: ${campaigns[i].name} (${campaigns[i].status})');
          }
        } else {
          print('🎯 No campaigns available');
        }
      }
      
      // Cache campaigns locally with timestamp
      if (kDebugMode) print('🎯 Caching campaigns to Hive...');
      await HiveService.saveCampaigns(campaigns);
      await HiveService.saveSetting('available_campaigns_cache_time', DateTime.now().millisecondsSinceEpoch);
      
      // Check if we need to update current campaign from the loaded campaigns
      final rider = HiveService.getRider();
      Campaign? currentCampaign = state.currentCampaign;
      
      if (rider?.currentCampaignId != null && currentCampaign == null) {
        // Try to find current campaign in loaded campaigns
        currentCampaign = campaigns
            .where((c) => c.id == rider!.currentCampaignId)
            .firstOrNull;
            
        if (currentCampaign != null && kDebugMode) {
          print('🎯 CURRENT CAMPAIGN FOUND: Found current campaign ${currentCampaign.name} in loaded campaigns');
        }
      }
      
      state = state.copyWith(
        availableCampaigns: campaigns,
        currentCampaign: currentCampaign,
        isLoading: false,
      );
      
      if (kDebugMode) print('🎯 CAMPAIGNS LOAD SUCCESS: State updated');
    } catch (e) {
      if (kDebugMode) {
        print('🎯 CAMPAIGNS LOAD ERROR: $e');
        print('🎯 Error type: ${e.runtimeType}');
        print('🎯 Stack trace: ${StackTrace.current}');
      }
      
      // Ensure we always clear loading state even on error
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      // Prevent exception from bubbling up and crashing the app
      if (kDebugMode) {
        print('Campaign loading error (handled): $e');
      }
    }
  }

  Future<void> refresh() async {
    // Prevent concurrent refresh calls
    if (state.isLoading) {
      if (kDebugMode) {
        print('🎯 CAMPAIGNS REFRESH BLOCKED: Already loading');
      }
      return;
    }
    
    // Load both available campaigns and rider's active campaigns with force refresh
    await Future.wait([
      loadAvailableCampaigns(forceRefresh: true),
      loadMyCampaigns(), // This loads rider's active assignments and triggers tracking updates
    ]);
  }

  /// Load current campaign after cache miss (e.g., after app reinstall)
  /// @deprecated No longer needed - use loadMyCampaigns() to get assignment data
  @Deprecated('Use loadMyCampaigns() instead to get proper assignment data')
  Future<void> _loadCurrentCampaignAfterCacheMiss(String currentCampaignId) async {
    if (kDebugMode) {
      print('🎯 DEPRECATED: _loadCurrentCampaignAfterCacheMiss called - using loadMyCampaigns() instead');
    }
    await loadMyCampaigns();
  }

  @Deprecated('Use joinGeofence instead. Campaign joining now requires geofence selection.')
  Future<bool> joinCampaign(String campaignId) async {
    state = state.copyWith(
      isJoining: false,
      error: 'Campaign joining now requires geofence selection. Please select a specific geofence to join.',
    );
    return false;
  }
  
  /// Join a specific geofence with verification (photo required)
  /// This is the new preferred method with enhanced security
  Future<bool> joinGeofenceWithVerification({
    required String geofenceId,
    required String imagePath,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    state = state.copyWith(isJoining: true, error: null);
    
    try {
      if (kDebugMode) {
        print('🎯 JOINING GEOFENCE WITH VERIFICATION: geofenceId=$geofenceId');
      }
      
      // Join geofence with verification
      final result = await _campaignService.joinGeofenceWithVerification(
        geofenceId: geofenceId,
        imagePath: imagePath,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );
      
      if (result.success) {
        return await _processSuccessfulGeofenceJoin(result, geofenceId);
      }
      
      state = state.copyWith(
        isJoining: false,
        error: result.error ?? 'Failed to join geofence with verification',
      );
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('🎯 GEOFENCE VERIFICATION JOIN ERROR: $e');
      }
      state = state.copyWith(
        isJoining: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Check if rider is eligible to join a geofence (including cooldown check)
  Future<bool> checkGeofenceJoinEligibility({
    required String geofenceId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (kDebugMode) {
        print('🎯 CHECKING GEOFENCE ELIGIBILITY: geofenceId=$geofenceId');
      }
      
      final result = await _campaignService.checkGeofenceJoinEligibility(
        geofenceId: geofenceId,
        latitude: latitude,
        longitude: longitude,
      );
      
      if (!result.success) {
        state = state.copyWith(error: result.error);
        return false;
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('🎯 GEOFENCE ELIGIBILITY CHECK ERROR: $e');
      }
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Join a specific geofence with automatic location detection (legacy method)
  /// @deprecated Use joinGeofenceWithVerification for enhanced security
  Future<bool> joinGeofence(String geofenceId) async {
    state = state.copyWith(isJoining: true, error: null);
    
    try {
      if (kDebugMode) {
        print('🎯 JOINING GEOFENCE (LEGACY): geofenceId=$geofenceId');
      }
      
      // Join geofence with current location validation
      final result = await _campaignService.joinGeofenceAtCurrentLocation(geofenceId);
      
      if (result.success) {
        return await _processSuccessfulGeofenceJoin(result, geofenceId);
      }
      
      state = state.copyWith(
        isJoining: false,
        error: result.error ?? 'Failed to join geofence',
      );
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('🎯 GEOFENCE JOIN ERROR: $e');
      }
      state = state.copyWith(
        isJoining: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Process successful geofence join result (shared logic)
  Future<bool> _processSuccessfulGeofenceJoin(CampaignResult result, String geofenceId) async {
    try {
      final assignmentData = result.data;
      
      if (assignmentData != null && assignmentData['assigned_geofence'] != null) {
        final geofenceData = assignmentData['assigned_geofence'];
        final campaignData = assignmentData['assignment']?['campaign'];
        
        if (campaignData != null) {
          // Update rider's current campaign and geofence
          final rider = HiveService.getRider();
          if (rider != null) {
            final updatedRider = rider.copyWith(
              currentCampaignId: campaignData['id'],
            );
            await HiveService.saveRider(updatedRider);
          }
          
          // Find and update the campaign in our state
          final campaignId = campaignData['id'];
          final campaignIndex = state.campaigns.indexWhere(
            (c) => c.id == campaignId,
          );
          
          if (campaignIndex != -1) {
            final campaign = state.campaigns[campaignIndex];
            
            // Find the geofence within the campaign
            final geofenceIndex = campaign.geofences.indexWhere(
              (g) => g.id == geofenceId,
            );
            
            if (geofenceIndex != -1) {
              // Update geofence with new rider count
              final geofence = campaign.geofences[geofenceIndex];
              final updatedGeofence = Geofence(
                id: geofence.id,
                name: geofence.name,
                centerLatitude: geofence.centerLatitude,
                centerLongitude: geofence.centerLongitude,
                radius: geofence.radius,
                shape: geofence.shape,
                polygonPoints: geofence.polygonPoints,
                budget: geofence.budget,
                spent: geofence.spent,
                remainingBudget: geofence.remainingBudget,
                rateType: geofence.rateType,
                ratePerKm: geofence.ratePerKm,
                ratePerHour: geofence.ratePerHour,
                fixedDailyRate: geofence.fixedDailyRate,
                startDate: geofence.startDate,
                endDate: geofence.endDate,
                maxRiders: geofence.maxRiders,
                currentRiders: (geofence.currentRiders ?? 0) + 1,
                availableSlots: geofence.availableSlots,
                minRiders: geofence.minRiders,
                status: geofence.status,
                isActive: geofence.isActive,
                isHighPriority: geofence.isHighPriority,
                priority: geofence.priority,
                fillPercentage: geofence.fillPercentage,
                budgetUtilization: geofence.budgetUtilization,
                verificationSuccessRate: geofence.verificationSuccessRate,
                averageHourlyRate: geofence.averageHourlyRate,
                areaType: geofence.areaType,
                targetCoverageHours: geofence.targetCoverageHours,
                verificationFrequency: geofence.verificationFrequency,
                specialInstructions: geofence.specialInstructions,
                description: geofence.description,
                totalDistanceCovered: geofence.totalDistanceCovered,
                totalVerifications: geofence.totalVerifications,
                successfulVerifications: geofence.successfulVerifications,
                totalHoursActive: geofence.totalHoursActive,
                targetDemographics: geofence.targetDemographics,
              );
              
              // Update campaign with updated geofence
              final updatedGeofences = List<Geofence>.from(campaign.geofences);
              updatedGeofences[geofenceIndex] = updatedGeofence;
              
              final updatedCampaign = campaign.copyWith(
                geofences: updatedGeofences,
                currentRiders: (campaign.currentRiders ?? 0) + 1,
              );
              
              // Update campaigns list
              final updatedCampaigns = List<Campaign>.from(state.campaigns);
              updatedCampaigns[campaignIndex] = updatedCampaign;
              
              // Save to local storage
              await HiveService.saveCampaign(updatedCampaign);
              
              // Update state
              state = state.copyWith(
                myCampaigns: updatedCampaigns,
                currentCampaign: updatedCampaign,
                currentGeofence: updatedGeofence,
                isJoining: false,
              );
              
              if (kDebugMode) {
                print('🎯 SUCCESSFULLY JOINED GEOFENCE: ${updatedGeofence.name} in ${updatedCampaign.name}');
              }
              
              return true;
            }
          }
        }
      }
      
      state = state.copyWith(
        isJoining: false,
        error: 'Failed to process geofence join',
      );
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('🎯 PROCESS GEOFENCE JOIN ERROR: $e');
      }
      state = state.copyWith(
        isJoining: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> leaveCampaign() async {
    if (state.currentCampaign == null) return false;
    
    state = state.copyWith(isJoining: true, error: null);
    
    try {
      final campaignId = state.currentCampaign!.id;
      final result = await _campaignService.leaveCampaign(campaignId);
      
      if (result.success) {
        // Update rider's current campaign
        final rider = HiveService.getRider();
        if (rider != null) {
          final updatedRider = rider.copyWith(currentCampaignId: null);
          await HiveService.saveRider(updatedRider);
        }
        
        // Update local campaign data
        final campaign = state.currentCampaign!;
        final updatedCampaign = campaign.copyWith(
          currentRiders: ((campaign.currentRiders ?? 0) - 1).clamp(0, campaign.maxRiders ?? 0),
        );
        await HiveService.saveCampaign(updatedCampaign);
        
        // Update state
        // Update the campaign in the appropriate list (myCampaigns since this is leaving a campaign)
        final updatedMyCampaigns = state.myCampaigns.map((c) {
          return (c.id == campaign.id) ? updatedCampaign : c;
        }).toList();
        
        state = state.copyWith(
          myCampaigns: updatedMyCampaigns,
          currentCampaign: null,
          isJoining: false,
        );
        
        return true;
      }
      
      state = state.copyWith(
        isJoining: false,
        error: result.error ?? 'Failed to leave campaign',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isJoining: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> refreshCampaigns() async {
    await loadAvailableCampaigns(forceRefresh: true);
  }

  /// Load rider's active campaigns with geofence assignments after login
  Future<void> loadMyCampaigns() async {
    if (kDebugMode) {
      print('🎯 LOADING MY CAMPAIGNS: Starting my campaigns load');
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final myCampaigns = await _campaignService.getMyCampaigns();
      
      if (kDebugMode) {
        print('🎯 MY CAMPAIGNS LOADED: ${myCampaigns.length} active campaigns');
        for (final campaign in myCampaigns) {
          print('🎯 Active Campaign: ${campaign.name} (${campaign.status})');
          if (campaign.hasActiveGeofenceAssignments) {
            for (final geofence in campaign.currentActiveGeofences) {
              print('🎯   - Geofence: ${geofence.geofenceName} (${geofence.status.displayName})');
            }
          }
        }
      }
      
      // Cache my campaigns separately to preserve assignment data
      await HiveService.saveSetting('my_campaigns_cache', myCampaigns.map((c) => c.toJson()).toList());
      await HiveService.saveSetting('my_campaigns_cache_time', DateTime.now().millisecondsSinceEpoch);
      
      // Set current campaign and geofence (first active assignment if multiple)
      Campaign? currentCampaign;
      Geofence? currentGeofence;
      
      if (myCampaigns.isNotEmpty) {
        // Find campaign with active geofence assignments
        final campaignWithActiveGeofences = myCampaigns
            .where((c) => c.hasActiveGeofenceAssignments)
            .firstOrNull;
            
        if (campaignWithActiveGeofences != null) {
          currentCampaign = campaignWithActiveGeofences;
          
          // Get the first active geofence assignment
          final activeGeofenceAssignment = campaignWithActiveGeofences.primaryActiveGeofence;
          
          if (activeGeofenceAssignment != null) {
            // Find the corresponding Geofence object in the campaign's geofences
            currentGeofence = currentCampaign.geofences
                .where((g) => g.id == activeGeofenceAssignment.geofenceId)
                .firstOrNull;
                
            if (kDebugMode) {
              print('🎯 CURRENT GEOFENCE: ${currentGeofence?.name ?? activeGeofenceAssignment.geofenceName}');
            }
          }
          
          // Update rider's currentCampaignId if not set
          final rider = HiveService.getRider();
          if (rider != null && rider.currentCampaignId != currentCampaign.id) {
            final updatedRider = rider.copyWith(
              currentCampaignId: currentCampaign.id,
            );
            await HiveService.saveRider(updatedRider);
          }
        } else {
          // No active geofence assignments, but has campaigns
          currentCampaign = myCampaigns.first;
          if (kDebugMode) {
            print('🎯 CAMPAIGN WITHOUT ACTIVE GEOFENCES: ${currentCampaign.name}');
          }
        }
      }
      
      state = state.copyWith(
        myCampaigns: myCampaigns,
        currentCampaign: currentCampaign,
        currentGeofence: currentGeofence,
        isLoading: false,
      );
      
      // Auto-start or update location tracking based on active geofence assignments
      await _updateLocationTrackingForAssignments(myCampaigns);
      
      if (kDebugMode) {
        print('🎯 MY CAMPAIGNS SUCCESS: Updated state with ${myCampaigns.length} campaigns');
        print('🎯 Current Campaign: ${currentCampaign?.name ?? 'None'}');
        print('🎯 Current Geofence: ${currentGeofence?.name ?? 'None'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🎯 MY CAMPAIGNS ERROR: $e');
      }
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// Check if available campaigns cache is still fresh
  bool _isAvailableCampaignsCacheFresh() {
    try {
      const cacheValidDuration = Duration(minutes: 5); // Cache valid for 5 minutes
      final cacheTime = HiveService.getSetting<int>('available_campaigns_cache_time');
      
      if (cacheTime == null) {
        if (kDebugMode) print('🎯 CACHE CHECK: No cache timestamp found');
        return false;
      }
      
      final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
      final now = DateTime.now();
      final cacheAge = now.difference(cacheDateTime);
      
      final isFresh = cacheAge <= cacheValidDuration;
      if (kDebugMode) {
        print('🎯 CACHE CHECK: Cache age: ${cacheAge.inMinutes}m ${cacheAge.inSeconds % 60}s, fresh: $isFresh');
      }
      
      return isFresh;
    } catch (e) {
      if (kDebugMode) {
        print('🎯 CACHE CHECK ERROR: $e');
      }
      return false;
    }
  }

  /// Clear error after a delay (for automatic dismissal)
  void clearErrorAfterDelay([Duration delay = const Duration(seconds: 8)]) {
    Timer(delay, () {
      if (state.error != null) {
        clearError();
      }
    });
  }

  // Get campaigns by status
  List<Campaign> get availableCampaigns {
    return state.campaigns
        .where((c) => c.canJoin)
        .toList();
  }

  List<Campaign> get runningCampaigns {
    return state.campaigns
        .where((c) => c.isRunning)
        .toList();
  }

  List<Campaign> get upcomingCampaigns {
    return state.campaigns
        .where((c) => c.isUpcoming)
        .toList();
  }


  /// Leave current geofence
  Future<bool> leaveCurrentGeofence() async {
    final currentGeofence = state.currentGeofence;
    if (currentGeofence == null) {
      if (kDebugMode) {
        print('🎯 CAMPAIGN PROVIDER: No current geofence to leave');
      }
      return false;
    }
    
    if (kDebugMode) {
      print('🎯 CAMPAIGN PROVIDER: Leaving current geofence ${currentGeofence.id}');
    }
    
    state = state.copyWith(isJoining: true, error: null);
    
    try {
      final result = await _campaignService.leaveGeofence(currentGeofence.id);
      
      if (result.success) {
        // Update rider's current campaign (clear)
        final rider = HiveService.getRider();
        if (rider != null) {
          final updatedRider = rider.copyWith(
            currentCampaignId: null,
          );
          await HiveService.saveRider(updatedRider);
        }
        
        // Clear current state
        state = state.copyWith(
          currentCampaign: null,
          currentGeofence: null,
          isJoining: false,
        );
        
        if (kDebugMode) {
          print('🎯 CAMPAIGN PROVIDER SUCCESS: Left geofence successfully');
        }
        
        return true;
      }
      
      state = state.copyWith(
        isJoining: false,
        error: result.error ?? 'Failed to leave geofence',
      );
      
      if (kDebugMode) {
        print('🎯 CAMPAIGN PROVIDER ERROR: ${result.error}');
      }
      
      return false;
    } catch (e) {
      state = state.copyWith(
        isJoining: false,
        error: e.toString(),
      );
      
      if (kDebugMode) {
        print('🎯 CAMPAIGN PROVIDER EXCEPTION: Failed to leave geofence: $e');
      }
      
      return false;
    }
  }

  /// Get geofences for a specific campaign
  Future<List<Geofence>> getCampaignGeofences(String campaignId) async {
    try {
      if (kDebugMode) {
        print('🎯 CAMPAIGN PROVIDER: Fetching geofences for campaign $campaignId');
      }
      
      return await _campaignService.getCampaignGeofences(campaignId);
    } catch (e) {
      if (kDebugMode) {
        print('🎯 CAMPAIGN PROVIDER ERROR: Failed to fetch geofences: $e');
      }
      
      // Fallback to local data
      final campaign = state.campaigns
          .where((c) => c.id == campaignId)
          .firstOrNull;
      
      return campaign?.geofences ?? [];
    }
  }

  /// Get details of a specific geofence
  Future<Geofence?> getGeofenceDetails(String campaignId, String geofenceId) async {
    try {
      if (kDebugMode) {
        print('🎯 CAMPAIGN PROVIDER: Fetching geofence details for $geofenceId');
      }
      
      return await _campaignService.getGeofenceDetails(campaignId, geofenceId);
    } catch (e) {
      if (kDebugMode) {
        print('🎯 CAMPAIGN PROVIDER ERROR: Failed to fetch geofence details: $e');
      }
      
      // Fallback to local data
      final campaign = state.campaigns
          .where((c) => c.id == campaignId)
          .firstOrNull;
      
      return campaign?.geofences
          .where((g) => g.id == geofenceId)
          .firstOrNull;
    }
  }

  /// Update location tracking based on geofence assignments
  /// This is the key method that implements the requirement: "tracking should be done whenever a geofenceassignment is detected"
  Future<void> _updateLocationTrackingForAssignments(List<Campaign> myCampaigns) async {
    try {
      final locationNotifier = _ref.read(locationProvider.notifier);
      
      // Collect all active geofence assignments across all campaigns
      final allActiveAssignments = <GeofenceAssignment>[];
      Campaign? primaryCampaign;
      
      for (final campaign in myCampaigns) {
        if (campaign.hasActiveGeofenceAssignments) {
          allActiveAssignments.addAll(campaign.currentActiveGeofences);
          primaryCampaign ??= campaign; // Use first campaign with assignments as primary
        }
      }
      
      if (kDebugMode) {
        print('🎯 LOCATION TRACKING UPDATE: Found ${allActiveAssignments.length} active geofence assignments');
        for (final assignment in allActiveAssignments) {
          print('🎯   - ${assignment.geofenceName} (${assignment.status.displayName})');
        }
      }
      
      // If we have active assignments, ensure location tracking is started
      if (allActiveAssignments.isNotEmpty && primaryCampaign != null) {
        final isCurrentlyTracking = locationNotifier.state.isTracking;
        
        if (!isCurrentlyTracking) {
          // Start tracking with assignments
          if (kDebugMode) {
            print('🎯 AUTO-STARTING location tracking due to active geofence assignments');
          }
          
          await locationNotifier.startTracking(
            campaignId: primaryCampaign.id,
            campaign: primaryCampaign,
            geofenceAssignments: allActiveAssignments,
          );
        } else {
          // Update existing tracking with new assignments
          if (kDebugMode) {
            print('🎯 UPDATING location tracking with new geofence assignments');
          }
          
          await locationNotifier.updateGeofenceAssignments(allActiveAssignments);
        }
      } else {
        // No active assignments - stop tracking if it was auto-started
        if (kDebugMode) {
          print('🎯 No active geofence assignments - location tracking may continue if manually started');
        }
        
        // Update with empty assignments list
        await locationNotifier.updateGeofenceAssignments([]);
      }
    } catch (e) {
      if (kDebugMode) {
        print('🎯 ERROR updating location tracking for assignments: $e');
      }
    }
  }
}

// Providers
final campaignServiceProvider = Provider<CampaignService>((ref) {
  return CampaignService();
});

final campaignProvider = StateNotifierProvider<CampaignNotifier, CampaignState>((ref) {
  final campaignService = ref.watch(campaignServiceProvider);
  return CampaignNotifier(campaignService, ref);
});

// Helper providers
final availableCampaignsProvider = Provider<List<Campaign>>((ref) {
  return ref.watch(campaignProvider.notifier).availableCampaigns;
});

final currentCampaignProvider = Provider<Campaign?>((ref) {
  return ref.watch(campaignProvider).currentCampaign;
});

final hasCurrentCampaignProvider = Provider<bool>((ref) {
  return ref.watch(campaignProvider).currentCampaign != null;
});

// Campaigns with active geofence assignments (from myCampaigns)
final activeCampaignsProvider = Provider<List<Campaign>>((ref) {
  final myCampaigns = ref.watch(campaignProvider).myCampaigns;
  return myCampaigns.where((c) => c.hasActiveGeofenceAssignments).toList();
});

// Available campaigns for joining (from availableCampaigns)
final availableCampaignsForJoiningProvider = Provider<List<Campaign>>((ref) {
  return ref.watch(campaignProvider).availableCampaigns;
});

final hasActiveGeofenceAssignmentsProvider = Provider<bool>((ref) {
  final campaigns = ref.watch(activeCampaignsProvider);
  return campaigns.isNotEmpty;
});

final currentGeofenceProvider = Provider<Geofence?>((ref) {
  return ref.watch(campaignProvider).currentGeofence;
});

final activeGeofenceAssignmentsProvider = Provider<List<GeofenceAssignment>>((ref) {
  final campaigns = ref.watch(activeCampaignsProvider);
  return campaigns.expand((c) => c.currentActiveGeofences).toList();
});
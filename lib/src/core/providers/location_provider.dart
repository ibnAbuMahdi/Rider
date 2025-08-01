import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../models/location_record.dart';
import '../models/campaign.dart';

// Location tracking state
class LocationState {
  final bool isTracking;
  final Position? currentPosition;
  final String? activeCampaignId;
  final List<LocationRecord> recentLocations;
  final bool hasPermission;
  final String? error;

  const LocationState({
    this.isTracking = false,
    this.currentPosition,
    this.activeCampaignId,
    this.recentLocations = const [],
    this.hasPermission = false,
    this.error,
  });

  LocationState copyWith({
    bool? isTracking,
    Position? currentPosition,
    String? activeCampaignId,
    List<LocationRecord>? recentLocations,
    bool? hasPermission,
    String? error,
  }) {
    return LocationState(
      isTracking: isTracking ?? this.isTracking,
      currentPosition: currentPosition ?? this.currentPosition,
      activeCampaignId: activeCampaignId ?? this.activeCampaignId,
      recentLocations: recentLocations ?? this.recentLocations,
      hasPermission: hasPermission ?? this.hasPermission,
      error: error ?? this.error,
    );
  }
}

// Location provider
class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(const LocationState()) {
    _checkPermissions();
    
    // Set up callback so LocationService can update our state during tracking
    _locationService.setPositionUpdateCallback((position) {
      updateCurrentPosition(position);
    });
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _locationService.hasLocationPermission();
    state = state.copyWith(hasPermission: hasPermission);
  }

  Future<bool> requestPermissions() async {
    if (kDebugMode) {
      print('📍 LOCATION: Starting permission request...');
    }
    
    try {
      final granted = await _locationService.requestLocationPermission();
      
      if (kDebugMode) {
        print('📍 LOCATION: Permission request completed, granted: $granted');
      }
      
      state = state.copyWith(hasPermission: granted);
      return granted;
    } catch (e) {
      if (kDebugMode) {
        print('📍 LOCATION ERROR: Permission request failed: $e');
      }
      state = state.copyWith(hasPermission: false, error: e.toString());
      return false;
    }
  }

  Future<void> getCurrentLocation() async {
    if (kDebugMode) {
      print('📍 LOCATION: Starting getCurrentLocation...');
    }
    
    try {
      state = state.copyWith(error: null);
      
      if (kDebugMode) {
        print('📍 LOCATION: Calling location service getCurrentPosition...');
      }
      
      Position? position;
      try {
        position = await _locationService.getCurrentPosition();
      } catch (locationError) {
        if (kDebugMode) {
          print('📍 LOCATION: Location service call failed: $locationError');
        }
        // Set error and continue
        state = state.copyWith(error: 'Location service failed: $locationError');
        return;
      }
      
      if (kDebugMode) {
        print('📍 LOCATION: getCurrentPosition completed, position: ${position != null ? 'available' : 'null'}');
        if (position != null) {
          print('📍 LOCATION: Position details - lat: ${position.latitude}, lon: ${position.longitude}, accuracy: ${position.accuracy}');
        }
      }
      
      if (position != null) {
        if (kDebugMode) {
          print('📍 LOCATION: About to update state with position...');
        }
        
        state = state.copyWith(currentPosition: position);
        
        if (kDebugMode) {
          print('📍 LOCATION: State updated successfully');
          print('📍 LOCATION: Current state position: ${state.currentPosition?.latitude}, ${state.currentPosition?.longitude}');
        }
      } else {
        if (kDebugMode) {
          print('📍 LOCATION: Position is null, not updating state');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('📍 LOCATION ERROR: getCurrentLocation failed: $e');
        print('📍 LOCATION ERROR: Stack trace: ${StackTrace.current}');
      }
      state = state.copyWith(error: e.toString());
    }
    
    if (kDebugMode) {
      print('📍 LOCATION: getCurrentLocation method completed');
    }
  }

  Future<void> startTracking({String? campaignId, Campaign? campaign, List<GeofenceAssignment>? geofenceAssignments}) async {
    try {
      if (!state.hasPermission) {
        final granted = await requestPermissions();
        if (!granted) {
          state = state.copyWith(error: 'Location permission denied');
          return;
        }
      }

      state = state.copyWith(
        error: null,
        isTracking: true,
        activeCampaignId: campaignId,
      );

      await _locationService.startTracking(
        campaignId: campaignId,
        campaign: campaign,
        geofenceAssignments: geofenceAssignments,
      );
      
      if (kDebugMode) {
        print('📍 Location tracking started for campaign: $campaignId');
        if (geofenceAssignments != null) {
          print('📍 With ${geofenceAssignments.length} geofence assignments');
        }
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isTracking: false,
      );
      if (kDebugMode) {
        print('❌ Failed to start location tracking: $e');
      }
    }
  }

  Future<void> stopTracking() async {
    try {
      await _locationService.stopTracking();
      state = state.copyWith(
        isTracking: false,
        activeCampaignId: null,
        error: null,
      );
      
      if (kDebugMode) {
        print('📍 Location tracking stopped');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      if (kDebugMode) {
        print('❌ Failed to stop location tracking: $e');
      }
    }
  }

  Future<void> refreshRecentLocations() async {
    try {
      final locations = await _locationService.getUnsyncedLocations();
      state = state.copyWith(recentLocations: locations);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to refresh recent locations: $e');
      }
    }
  }

  // Check if rider is within campaign geofence
  bool isWithinCampaignGeofence(Campaign campaign) {
    if (state.currentPosition == null || campaign.geofences.isEmpty) return false;
    
    // Check if position is within any of the campaign's geofences
    for (final geofence in campaign.geofences) {
      if (geofence.containsPoint(
        state.currentPosition!.latitude,
        state.currentPosition!.longitude,
      )) {
        return true;
      }
    }
    return false;
  }

  // Calculate distance to campaign center
  double? getDistanceToCampaign(Campaign campaign) {
    if (state.currentPosition == null || campaign.geofences.isEmpty) return null;
    
    // Get distance to the first geofence center
    final firstGeofence = campaign.geofences.first;
    return LocationService.calculateDistance(
      state.currentPosition!.latitude,
      state.currentPosition!.longitude,
      firstGeofence.centerLatitude,
      firstGeofence.centerLongitude,
    );
  }

  // Mark locations as synced after successful API upload
  Future<void> markLocationsSynced(List<String> locationIds) async {
    await _locationService.markLocationsSynced(locationIds);
    await refreshRecentLocations();
  }

  // Update geofence assignments for runtime changes (called when getMyCampaigns() detects changes)
  Future<void> updateGeofenceAssignments(List<GeofenceAssignment> assignments) async {
    await _locationService.updateGeofenceAssignments(assignments);
    
    if (kDebugMode) {
      print('📍 LOCATION PROVIDER: Updated geofence assignments (${assignments.length} assignments)');
    }
  }

  // Update current position during tracking (called by LocationService)
  void updateCurrentPosition(Position position) {
    state = state.copyWith(currentPosition: position);
    
    if (kDebugMode) {
      print('📍 LOCATION PROVIDER: Updated current position from tracking: ${position.latitude}, ${position.longitude}');
    }
  }
}

// Providers
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService.instance;
});

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationNotifier(locationService);
});

// Current position provider for quick access
final currentPositionProvider = Provider<Position?>((ref) {
  return ref.watch(locationProvider).currentPosition;
});

// Is tracking provider
final isTrackingProvider = Provider<bool>((ref) {
  return ref.watch(locationProvider).isTracking;
});

// Active campaign location provider
final activeCampaignLocationProvider = Provider<String?>((ref) {
  return ref.watch(locationProvider).activeCampaignId;
});

// Enhanced location data providers
final totalDistanceProvider = Provider<double>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.totalDistance;
});

final isOnlineProvider = Provider<bool>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.isOnline;
});

final unsyncedLocationCountProvider = Provider<int>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.unsyncedLocationCount;
});

// Additional providers for tracking UI
final totalGeofenceEarningsProvider = Provider<double>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.totalGeofenceEarnings;
});

final currentGeofenceProvider = Provider<dynamic>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.currentGeofence;
});

final isWithinActiveGeofenceProvider = Provider<bool>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.isWithinActiveGeofence;
});

final geofenceDistancesProvider = Provider<Map<String, double>>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.geofenceDistances;
});

final geofenceDurationsProvider = Provider<Map<String, Duration>>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.geofenceDurations;
});

final currentGeofenceIdProvider = Provider<String?>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.currentGeofenceId;
});

// Tracking stats state that updates periodically
class TrackingStats {
  final double totalDistance;
  final double totalGeofenceEarnings;
  final dynamic currentGeofence;
  final bool isWithinGeofence;
  final Map<String, double> geofenceDistances;
  final Map<String, Duration> geofenceDurations;
  final String? currentGeofenceId;
  final DateTime lastUpdated;

  const TrackingStats({
    required this.totalDistance,
    required this.totalGeofenceEarnings,
    required this.currentGeofence,
    required this.isWithinGeofence,
    required this.geofenceDistances,
    required this.geofenceDurations,
    required this.currentGeofenceId,
    required this.lastUpdated,
  });

  TrackingStats copyWith({
    double? totalDistance,
    double? totalGeofenceEarnings,
    dynamic currentGeofence,
    bool? isWithinGeofence,
    Map<String, double>? geofenceDistances,
    Map<String, Duration>? geofenceDurations,
    String? currentGeofenceId,
    DateTime? lastUpdated,
  }) {
    return TrackingStats(
      totalDistance: totalDistance ?? this.totalDistance,
      totalGeofenceEarnings: totalGeofenceEarnings ?? this.totalGeofenceEarnings,
      currentGeofence: currentGeofence ?? this.currentGeofence,
      isWithinGeofence: isWithinGeofence ?? this.isWithinGeofence,
      geofenceDistances: geofenceDistances ?? this.geofenceDistances,
      geofenceDurations: geofenceDurations ?? this.geofenceDurations,
      currentGeofenceId: currentGeofenceId ?? this.currentGeofenceId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class TrackingStatsNotifier extends StateNotifier<TrackingStats> {
  final LocationService _locationService;

  TrackingStatsNotifier(this._locationService) : super(
    TrackingStats(
      totalDistance: 0.0,
      totalGeofenceEarnings: 0.0,
      currentGeofence: null,
      isWithinGeofence: false,
      geofenceDistances: {},
      geofenceDurations: {},
      currentGeofenceId: null,
      lastUpdated: DateTime.now(),
    ),
  );

  void updateStats() {
    state = TrackingStats(
      totalDistance: _locationService.totalDistance,
      totalGeofenceEarnings: _locationService.totalGeofenceEarnings,
      currentGeofence: _locationService.currentGeofence,
      isWithinGeofence: _locationService.isWithinActiveGeofence,
      geofenceDistances: Map.from(_locationService.geofenceDistances),
      geofenceDurations: Map.from(_locationService.geofenceDurations),
      currentGeofenceId: _locationService.currentGeofenceId,
      lastUpdated: DateTime.now(),
    );
  }
}

final trackingStatsProvider = StateNotifierProvider<TrackingStatsNotifier, TrackingStats>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return TrackingStatsNotifier(locationService);
});

// Auto-refresh provider that triggers every few seconds when tracking is active
final autoRefreshProvider = StreamProvider<int>((ref) {
  final locationState = ref.watch(locationProvider);
  
  if (locationState.isTracking) {
    // Create a stream that emits every 3 seconds when tracking is active
    return Stream.periodic(const Duration(seconds: 3), (count) => count);
  } else {
    // When not tracking, emit once and complete
    return Stream.value(0);
  }
});

// Enhanced providers that auto-refresh when tracking is active
final liveTrackingStatsProvider = Provider<TrackingStats>((ref) {
  // Watch auto-refresh to trigger updates
  ref.watch(autoRefreshProvider);
  
  final locationService = ref.watch(locationServiceProvider);
  return TrackingStats(
    totalDistance: locationService.totalDistance,
    totalGeofenceEarnings: locationService.totalGeofenceEarnings,
    currentGeofence: locationService.currentGeofence,
    isWithinGeofence: locationService.isWithinActiveGeofence,
    geofenceDistances: Map.from(locationService.geofenceDistances),
    geofenceDurations: Map.from(locationService.geofenceDurations),
    currentGeofenceId: locationService.currentGeofenceId,
    lastUpdated: DateTime.now(),
  );
});
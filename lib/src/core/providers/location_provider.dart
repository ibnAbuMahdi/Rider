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
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _locationService.hasLocationPermission();
    state = state.copyWith(hasPermission: hasPermission);
  }

  Future<bool> requestPermissions() async {
    final granted = await _locationService.requestLocationPermission();
    state = state.copyWith(hasPermission: granted);
    return granted;
  }

  Future<void> getCurrentLocation() async {
    try {
      state = state.copyWith(error: null);
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        state = state.copyWith(currentPosition: position);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      if (kDebugMode) {
        print('❌ Failed to get current location: $e');
      }
    }
  }

  Future<void> startTracking({String? campaignId}) async {
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

      await _locationService.startTracking(campaignId: campaignId);
      
      if (kDebugMode) {
        print('📍 Location tracking started for campaign: $campaignId');
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
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
import '../storage/hive_service.dart';
import '../models/location_record.dart';
import '../models/campaign.dart';
import 'notification_service.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  
  LocationService._();

  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;
  Timer? _stationaryTimer;
  Timer? _geofenceCheckTimer;
  bool _isTracking = false;
  String? _activeCampaignId;
  Campaign? _activeCampaign;
  bool _wasInsideGeofence = false;

  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('📍 Location service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize location service: $e');
      }
    }
  }

  Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
             permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      if (!await hasLocationPermission()) {
        final granted = await requestLocationPermission();
        if (!granted) return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get current position: $e');
      }
      return null;
    }
  }

  Future<void> startTracking({String? campaignId, Campaign? campaign}) async {
    if (_isTracking) return;

    try {
      if (!await hasLocationPermission()) {
        final granted = await requestLocationPermission();
        if (!granted) {
          throw Exception('Location permission denied');
        }
      }

      _isTracking = true;
      _activeCampaignId = campaignId;
      _activeCampaign = campaign;

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConstants.movementThresholdMetersInt,
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) => _onLocationUpdate(position, campaignId),
        onError: (error) {
          if (kDebugMode) {
            print('❌ Location stream error: $error');
          }
        },
      );

      // Start geofence monitoring if campaign is provided
      if (_activeCampaign != null) {
        _startGeofenceMonitoring();
      }

      if (kDebugMode) {
        print('📍 Location tracking started for campaign: $campaignId');
      }
    } catch (e) {
      _isTracking = false;
      _activeCampaignId = null;
      _activeCampaign = null;
      if (kDebugMode) {
        print('❌ Failed to start location tracking: $e');
      }
      rethrow;
    }
  }

  Future<void> stopTracking() async {
    try {
      await _positionStream?.cancel();
      _positionStream = null;
      _stationaryTimer?.cancel();
      _stationaryTimer = null;
      _geofenceCheckTimer?.cancel();
      _geofenceCheckTimer = null;
      _isTracking = false;
      _activeCampaignId = null;
      _activeCampaign = null;
      _wasInsideGeofence = false;
      
      if (kDebugMode) {
        print('📍 Location tracking stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to stop location tracking: $e');
      }
    }
  }

  Future<void> _onLocationUpdate(Position position, String? campaignId) async {
    try {
      // Check if rider is moving
      bool isMoving = false;
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        
        isMoving = distance > AppConstants.movementThresholdMeters;
        
        if (isMoving) {
          _onMovement();
        } else {
          _onStationary();
        }
      }

      // Store location record
      final locationRecord = LocationRecord(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        riderId: HiveService.getUserId() ?? '',
        campaignId: campaignId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        altitude: position.altitude,
        timestamp: DateTime.now(),
        isWorking: campaignId != null,
        createdAt: DateTime.now(),
      );

      await HiveService.saveLocationRecord(locationRecord);
      
      _lastPosition = position;
      
      if (kDebugMode) {
        print('📍 Location updated: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to process location update: $e');
      }
    }
  }

  void _onMovement() {
    // Cancel stationary timer
    _stationaryTimer?.cancel();
    _stationaryTimer = null;
    
    if (kDebugMode) {
      print('🚶 Rider is moving');
    }
  }

  void _onStationary() {
    // Start stationary timer if not already running
    _stationaryTimer ??= Timer(
      Duration(minutes: AppConstants.stationaryIntervalMinutes),
      () {
        if (kDebugMode) {
          print('🛑 Rider is stationary');
        }
        // Could reduce tracking frequency here
      },
    );
  }

  bool get isTracking => _isTracking;
  
  Position? get lastKnownPosition => _lastPosition;

  // Calculate distance between two points
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Check if position is within geofence
  static bool isWithinGeofence(
    Position position,
    double centerLat,
    double centerLon,
    double radiusMeters,
  ) {
    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      centerLat,
      centerLon,
    );
    return distance <= radiusMeters;
  }

  // Get location records for sync
  Future<List<LocationRecord>> getUnsyncedLocations() async {
    return HiveService.getUnsyncedLocations();
  }

  // Mark locations as synced
  Future<void> markLocationsSynced(List<String> locationIds) async {
    await HiveService.markLocationsSynced(locationIds);
  }

  // Start geofence monitoring
  void _startGeofenceMonitoring() {
    if (_activeCampaign == null) return;

    _geofenceCheckTimer = Timer.periodic(
      const Duration(seconds: 30), // Check every 30 seconds
      (timer) => _checkGeofence(),
    );

    if (kDebugMode) {
      print('🔍 Geofence monitoring started');
    }
  }

  // Check if rider is within campaign geofence
  void _checkGeofence() {
    if (_lastPosition == null || _activeCampaign == null) return;

    // Check if rider is within any of the campaign's geofences
    bool isInsideAnyGeofence = false;
    
    for (final geofence in _activeCampaign!.geofences) {
      final isInside = geofence.containsPoint(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
      );
      
      if (isInside) {
        isInsideAnyGeofence = true;
        break;
      }
    }

    // Check for geofence violations
    if (_wasInsideGeofence && !isInsideAnyGeofence) {
      _onGeofenceExit();
    } else if (!_wasInsideGeofence && isInsideAnyGeofence) {
      _onGeofenceEnter();
    }

    _wasInsideGeofence = isInsideAnyGeofence;
  }

  // Handle rider entering geofence
  void _onGeofenceEnter() {
    if (kDebugMode) {
      print('✅ Rider entered campaign geofence');
    }

    // Store geofence event
    _recordGeofenceEvent('enter');
  }

  // Handle rider leaving geofence
  void _onGeofenceExit() {
    if (kDebugMode) {
      print('⚠️ Rider left campaign geofence');
    }

    // Show notification about leaving geofence
    if (_activeCampaign != null) {
      NotificationService.showCampaignUpdate(
        title: 'Campaign Area Warning',
        message: 'You have left the ${_activeCampaign!.name} campaign area. Return to continue earning.',
      );
    }

    // Store geofence event
    _recordGeofenceEvent('exit');
  }

  // Record geofence events for tracking compliance
  void _recordGeofenceEvent(String eventType) {
    if (_lastPosition == null || _activeCampaign == null) return;

    try {
      final geofenceEvent = {
        'type': eventType,
        'campaign_id': _activeCampaign!.id,
        'latitude': _lastPosition!.latitude,
        'longitude': _lastPosition!.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'accuracy': _lastPosition!.accuracy,
      };

      // Store in local storage for sync
      final events = HiveService.getSetting<List<dynamic>>('geofence_events') ?? [];
      events.add(geofenceEvent);
      
      // Keep only last 100 events
      if (events.length > 100) {
        events.removeRange(0, events.length - 100);
      }
      
      HiveService.saveSetting('geofence_events', events);

      if (kDebugMode) {
        print('📍 Geofence event recorded: $eventType');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to record geofence event: $e');
      }
    }
  }

  // Get active campaign info
  String? get activeCampaignId => _activeCampaignId;
  Campaign? get activeCampaign => _activeCampaign;

  // Check if currently within geofence
  bool get isWithinActiveGeofence {
    if (_lastPosition == null || _activeCampaign == null) return false;
    return _wasInsideGeofence;
  }

  // Calculate earnings eligibility based on location
  bool isEligibleForEarnings() {
    return _isTracking && 
           _activeCampaign != null && 
           _wasInsideGeofence;
  }

  // Get distance to active campaign center
  double? getDistanceToActiveCampaign() {
    if (_lastPosition == null || _activeCampaign == null || _activeCampaign!.geofences.isEmpty) return null;
    
    // Get distance to the first geofence center
    final firstGeofence = _activeCampaign!.geofences.first;
    return calculateDistance(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      firstGeofence.centerLatitude,
      firstGeofence.centerLongitude,
    );
  }

  // Get geofence events for sync
  List<Map<String, dynamic>> getGeofenceEvents() {
    try {
      final events = HiveService.getSetting<List<dynamic>>('geofence_events') ?? [];
      return events.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get geofence events: $e');
      }
      return [];
    }
  }

  // Clear synced geofence events
  Future<void> clearGeofenceEvents() async {
    try {
      await HiveService.saveSetting('geofence_events', <Map<String, dynamic>>[]);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear geofence events: $e');
      }
    }
  }
}
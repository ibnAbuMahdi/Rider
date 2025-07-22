import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Position? _lastPosition;
  Timer? _stationaryTimer;
  Timer? _geofenceCheckTimer;
  bool _isTracking = false;
  String? _activeCampaignId;
  bool _isGettingPosition = false;
  Campaign? _activeCampaign;
  bool _wasInsideGeofence = false;
  bool _isOnline = false;
  final Connectivity _connectivity = Connectivity();
  
  // Enhanced location tracking variables
  final List<LocationRecord> _unsyncedLocations = [];
  double _totalDistance = 0.0;

  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('📍 Location service initializing...');
      }
      
      // Initialize connectivity monitoring
      await instance._initConnectivity();
      
      if (kDebugMode) {
        print('📍 Location service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize location service: $e');
      }
    }
  }
  
  Future<void> _initConnectivity() async {
    try {
      // Check initial connectivity
      var initialResult = await _connectivity.checkConnectivity();
      _isOnline = initialResult != ConnectivityResult.none;
      
      if (kDebugMode) {
        print('📍 Initial connectivity: ${_isOnline ? 'online' : 'offline'} ($initialResult)');
      }
      
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        ConnectivityResult result,
      ) {
        bool wasOnline = _isOnline;
        _isOnline = result != ConnectivityResult.none;
        
        if (kDebugMode) {
          print('📍 Connectivity changed: ${_isOnline ? 'online' : 'offline'} ($result)');
        }
        
        // If we just came online, try to sync stored locations
        if (!wasOnline && _isOnline) {
          _syncStoredLocations();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize connectivity: $e');
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
      if (kDebugMode) {
        print('📍 SERVICE: Skipping service check, going straight to permissions...');
      }
      
      // Skip the isLocationServiceEnabled() call that's causing crashes
      // and go straight to permission checks which are more reliable
      
      if (kDebugMode) {
        print('📍 SERVICE: Checking current permission...');
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (kDebugMode) {
        print('📍 SERVICE: Current permission: $permission');
      }
      
      if (permission == LocationPermission.denied) {
        if (kDebugMode) {
          print('📍 SERVICE: Permission denied, requesting permission...');
        }
        
        permission = await Geolocator.requestPermission();
        
        if (kDebugMode) {
          print('📍 SERVICE: Permission request result: $permission');
        }
        
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('📍 SERVICE: Permission denied forever');
        }
        return false;
      }

      if (kDebugMode) {
        print('📍 SERVICE: Permission granted successfully');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('📍 SERVICE ERROR: requestLocationPermission failed: $e');
      }
      return false;
    }
  }

  // Diagnostic method to check if geolocator is functioning
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final Map<String, dynamic> diagnostics = {};
    
    try {
      // Check if location services are enabled
      diagnostics['locationServiceEnabled'] = 'checking...';
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        diagnostics['locationServiceEnabled'] = serviceEnabled;
      } catch (e) {
        diagnostics['locationServiceEnabled'] = 'error: $e';
      }
      
      // Check permission status
      diagnostics['permissionStatus'] = 'checking...';
      try {
        final permission = await Geolocator.checkPermission();
        diagnostics['permissionStatus'] = permission.toString();
      } catch (e) {
        diagnostics['permissionStatus'] = 'error: $e';
      }
      
      // Try to get last known position
      diagnostics['lastKnownPosition'] = 'checking...';
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          diagnostics['lastKnownPosition'] = 'lat: ${lastKnown.latitude}, lon: ${lastKnown.longitude}';
        } else {
          diagnostics['lastKnownPosition'] = 'null';
        }
      } catch (e) {
        diagnostics['lastKnownPosition'] = 'error: $e';
      }
      
    } catch (e) {
      diagnostics['generalError'] = e.toString();
    }
    
    return diagnostics;
  }

  Future<Position?> getCurrentPosition() async {
    // Prevent concurrent location requests
    if (_isGettingPosition) {
      if (kDebugMode) {
        print('📍 SERVICE: getCurrentPosition already in progress, skipping...');
      }
      return _lastPosition;
    }
    
    _isGettingPosition = true;
    
    try {
      if (kDebugMode) {
        print('📍 SERVICE: getCurrentPosition - checking permissions...');
      }
      
      if (!await hasLocationPermission()) {
        if (kDebugMode) {
          print('📍 SERVICE: No permission, requesting...');
        }
        
        final granted = await requestLocationPermission();
        if (!granted) {
          if (kDebugMode) {
            print('📍 SERVICE: Permission not granted, returning null');
          }
          return null;
        }
      }

      if (kDebugMode) {
        print('📍 SERVICE: Permission available, getting current position...');
      }
      
      // Try to get last known position first to avoid crashes
      if (kDebugMode) {
        print('📍 SERVICE: Trying to get last known position first...');
      }
      
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition()
            .timeout(const Duration(seconds: 5), onTimeout: () {
          if (kDebugMode) {
            print('📍 SERVICE: getLastKnownPosition timed out');
          }
          return null;
        });
      } catch (e) {
        if (kDebugMode) {
          print('📍 SERVICE: getLastKnownPosition failed: $e');
        }
        position = null;
      }
      
      if (position == null) {
        if (kDebugMode) {
          print('📍 SERVICE: No last known position, trying current position with fallback...');
        }
        
        try {
          // Try with lowest accuracy and longer timeout to prevent crashes
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.lowest, // Use lowest accuracy
            timeLimit: const Duration(seconds: 20), // Reasonable timeout
          );
        } catch (gpsError) {
          if (kDebugMode) {
            print('📍 SERVICE: GPS getCurrentPosition failed: $gpsError');
            print('📍 SERVICE: Trying one more time with different settings...');
          }
          
          // Final attempt with most permissive settings
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.lowest,
            ).timeout(const Duration(seconds: 10));
          } catch (finalError) {
            if (kDebugMode) {
              print('📍 SERVICE: All location attempts failed: $finalError');
            }
            // Return null - the calling code will handle it
            position = null;
          }
        }
      } else {
        if (kDebugMode) {
          print('📍 SERVICE: Using last known position');
        }
      }
      
      if (position != null) {
        if (kDebugMode) {
          print('📍 SERVICE: Position obtained: ${position.latitude}, ${position.longitude}');
        }
      } else {
        if (kDebugMode) {
          print('📍 SERVICE: Position is still null after all attempts');
        }
      }
      
      // Store position and reset flag before returning
      if (position != null) {
        _lastPosition = position;
      }
      _isGettingPosition = false;
      return position;
    } catch (e) {
      _isGettingPosition = false; // Reset flag on error too
      
      if (kDebugMode) {
        print('📍 SERVICE ERROR: getCurrentPosition failed: $e');
      }
      
      // Check if it's a location service disabled error
      if (e.toString().contains('location service on the device is disabled')) {
        if (kDebugMode) {
          print('📍 SERVICE: Location services are disabled on device');
        }
        // You could throw a specific exception here for the UI to handle
        throw Exception('Location services are disabled. Please enable location services in your device settings.');
      }
      
      return null;
    }
  }

  Future<void> startTracking({String? campaignId, Campaign? campaign}) async {
    if (_isTracking) {
      if (kDebugMode) {
        print('📍 Location tracking already active');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('📍 Starting location tracking for campaign: $campaignId');
      }
      
      if (!await hasLocationPermission()) {
        final granted = await requestLocationPermission();
        if (!granted) {
          throw Exception('Location permission denied');
        }
      }

      _isTracking = true;
      _activeCampaignId = campaignId;
      _activeCampaign = campaign;
      _totalDistance = 0.0;

      // Enhanced location settings based on reference implementation
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation, // Better accuracy
        distanceFilter: 10, // Track every 10 meters (more granular)
        timeLimit: Duration(seconds: 30), // Timeout for each location request
      );

      if (kDebugMode) {
        print('📍 Creating position stream with enhanced settings...');
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) => _onLocationUpdate(position, campaignId),
        onError: (error) {
          if (kDebugMode) {
            print('❌ Location stream error: $error');
          }
          // Try to restart the stream after a delay
          Timer(const Duration(seconds: 5), () {
            if (_isTracking) {
              _restartLocationStream();
            }
          });
        },
        onDone: () {
          if (kDebugMode) {
            print('📍 Location stream completed');
          }
        },
      );

      // Start geofence monitoring if campaign is provided
      if (_activeCampaign != null) {
        _startGeofenceMonitoring();
      }

      if (kDebugMode) {
        print('📍 Location tracking started successfully');
        print('📍 Campaign: $campaignId');
        print('📍 Enhanced settings: bestForNavigation, 10m filter');
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
  
  Future<void> _restartLocationStream() async {
    if (!_isTracking) return;
    
    try {
      if (kDebugMode) {
        print('📍 Restarting location stream...');
      }
      
      await _positionStream?.cancel();
      
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
        timeLimit: Duration(seconds: 30),
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) => _onLocationUpdate(position, _activeCampaignId),
        onError: (error) {
          if (kDebugMode) {
            print('❌ Location stream error after restart: $error');
          }
        },
      );
      
      if (kDebugMode) {
        print('📍 Location stream restarted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to restart location stream: $e');
      }
    }
  }

  Future<void> stopTracking() async {
    try {
      if (kDebugMode) {
        print('📍 Stopping location tracking...');
      }
      
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
      
      // Try to sync any remaining unsynced locations
      if (_unsyncedLocations.isNotEmpty && _isOnline) {
        await _syncStoredLocations();
      }
      
      if (kDebugMode) {
        print('📍 Location tracking stopped successfully');
        print('📍 Total distance tracked: ${_totalDistance.toStringAsFixed(2)}m');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to stop location tracking: $e');
      }
    }
  }
  
  // Clean up method for when the service is disposed
  Future<void> dispose() async {
    try {
      await stopTracking();
      await _connectivitySubscription?.cancel();
      _connectivitySubscription = null;
      
      if (kDebugMode) {
        print('📍 Location service disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to dispose location service: $e');
      }
    }
  }

  Future<void> _onLocationUpdate(Position position, String? campaignId) async {
    try {
      if (kDebugMode) {
        print('📍 Processing location update: ${position.latitude}, ${position.longitude}');
        print('📍 Accuracy: ${position.accuracy}m, Speed: ${position.speed}m/s');
      }

      // Calculate distance if we have a previous position
      double distanceFromLast = 0.0;
      bool isMoving = false;
      
      if (_lastPosition != null) {
        distanceFromLast = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        
        // Add to total distance traveled
        _totalDistance += distanceFromLast;
        
        isMoving = distanceFromLast > AppConstants.movementThresholdMeters;
        
        if (kDebugMode) {
          print('📍 Distance from last: ${distanceFromLast.toStringAsFixed(2)}m');
          print('📍 Total distance: ${_totalDistance.toStringAsFixed(2)}m');
          print('📍 Movement status: ${isMoving ? 'moving' : 'stationary'}');
        }
        
        if (isMoving) {
          _onMovement();
        } else {
          _onStationary();
        }
      }

      // Create location record with enhanced data
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

      // Store location record (with offline capability)
      await _storeLocationRecord(locationRecord);
      
      _lastPosition = position;
      
      if (kDebugMode) {
        print('📍 Location record stored successfully');
        print('📍 Online status: ${_isOnline ? 'online' : 'offline'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to process location update: $e');
        print('❌ Error details: ${e.toString()}');
      }
    }
  }
  
  Future<void> _storeLocationRecord(LocationRecord record) async {
    try {
      // Always store to local database
      await HiveService.saveLocationRecord(record);
      
      if (_isOnline) {
        // If online, try to sync immediately
        // Note: This would need to be implemented with your API service
        if (kDebugMode) {
          print('📍 Would sync location record to server: ${record.id}');
        }
      } else {
        // If offline, add to unsynced list
        _unsyncedLocations.add(record);
        if (kDebugMode) {
          print('📍 Added to offline queue. Unsynced count: ${_unsyncedLocations.length}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to store location record: $e');
      }
    }
  }
  
  Future<void> _syncStoredLocations() async {
    if (!_isOnline || _unsyncedLocations.isEmpty) return;
    
    try {
      if (kDebugMode) {
        print('📍 Syncing ${_unsyncedLocations.length} stored locations...');
      }
      
      // TODO: Implement actual API sync here
      // for (var record in _unsyncedLocations) {
      //   await locationApiService.syncLocationRecord(record);
      // }
      
      // For now, just clear the unsynced list after a delay
      await Future.delayed(const Duration(seconds: 2));
      _unsyncedLocations.clear();
      
      if (kDebugMode) {
        print('📍 Location sync completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to sync locations: $e');
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
      const Duration(minutes: AppConstants.stationaryIntervalMinutes),
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
  
  // New getters for enhanced functionality
  double get totalDistance => _totalDistance;
  
  bool get isOnline => _isOnline;
  
  int get unsyncedLocationCount => _unsyncedLocations.length;
  
  List<LocationRecord> get unsyncedLocations => List.unmodifiable(_unsyncedLocations);

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
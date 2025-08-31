import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/app_constants.dart';
import '../storage/hive_service.dart';
import '../models/location_record.dart';
import '../models/campaign.dart';
import 'notification_service.dart';
import 'hourly_tracking_service.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  
  LocationService._();

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Position? _lastPosition;
  Timer? _stationaryTimer;
  Timer? _geofenceCheckTimer;
  Timer? _periodicLocationTimer;
  bool _isTracking = false;
  String? _activeCampaignId;
  bool _isGettingPosition = false;
  Campaign? _activeCampaign;
  bool _wasInsideGeofence = false;
  bool _isOnline = false;
  final Connectivity _connectivity = Connectivity();
  
  // Debug flag to suspend geofence checking for earnings AND tracking (testing only)
  bool _suspendGeofenceChecking = false; // Set to false to restore normal geofence-based tracking and earnings
  
  // Callback to update the location provider when new position is received
  Function(Position)? _positionUpdateCallback;
  
  // Hourly tracking service for per_hour rate types
  final HourlyTrackingService _hourlyTrackingService = HourlyTrackingService.instance;
  
  // Set the callback to update location provider state
  void setPositionUpdateCallback(Function(Position) callback) {
    _positionUpdateCallback = callback;
  }

  // Handle app lifecycle changes to ensure tracking continues in background
  void handleAppLifecycleChange(AppLifecycleState state) {
    if (kDebugMode) {
      print('📍 LOCATION SERVICE: App lifecycle changed to $state, tracking: $_isTracking');
    }

    switch (state) {
      case AppLifecycleState.paused:
        // App went to background - ensure location tracking continues
        if (_isTracking) {
          if (kDebugMode) {
            print('📍 LOCATION SERVICE: App backgrounded, ensuring location tracking continues');
          }
          // The location stream should continue running, but we might want to adjust the settings
          // for better battery optimization while maintaining accuracy
        }
        break;
      case AppLifecycleState.resumed:
        // App came back to foreground - ensure location tracking is still active
        if (_isTracking) {
          if (kDebugMode) {
            print('📍 LOCATION SERVICE: App resumed, verifying location tracking status');
          }
          // Check if the position stream is still active and restart if needed
          _verifyLocationStreamStatus();
        }
        break;
      default:
        break;
    }
  }

  Future<void> _verifyLocationStreamStatus() async {
    if (_isTracking && _positionStream == null) {
      if (kDebugMode) {
        print('📍 LOCATION SERVICE: Position stream was lost, restarting...');
      }
      await _restartLocationStream();
    }
  }
  
  // Enhanced location tracking variables
  final List<LocationRecord> _unsyncedLocations = [];
  double _totalDistance = 0.0;
  
  // Multi-geofence tracking
  String? _currentGeofenceId;
  Geofence? _currentGeofence;
  String? _currentAssignmentId; // Track current active assignment
  List<GeofenceAssignment> _geofenceAssignments = []; // Track assigned geofences
  final Map<String, double> _geofenceDistances = {}; // Track distance per geofence (for hybrid rates)
  final Map<String, double> _assignmentEarnings = {}; // Track earnings per assignment (UX consistency)
  final Map<String, DateTime> _geofenceEntryTimes = {}; // Track time spent in each geofence
  final Map<String, Duration> _geofenceDurations = {}; // Total time per geofence
  int _locationUpdateCount = 0; // Counter for periodic sync

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
        
        // If we just came online, try to sync stored locations and hourly windows
        if (!wasOnline && _isOnline) {
          _syncStoredLocations();
          _syncPendingHourlyWindows();
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

  Future<void> startTracking({String? campaignId, Campaign? campaign, List<GeofenceAssignment>? geofenceAssignments}) async {
    if (_isTracking) {
      if (kDebugMode) {
        print('📍 Location tracking already active');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('📍 Starting location tracking for campaign: $campaignId');
        if (geofenceAssignments != null) {
          print('📍 Geofence assignments: ${geofenceAssignments.length} assignments');
          for (final assignment in geofenceAssignments) {
            print('📍   - ${assignment.geofenceName} (${assignment.status.displayName})');
          }
        }
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
      _geofenceAssignments = geofenceAssignments ?? [];
      _totalDistance = 0.0;
      
      // Reset geofence tracking data
      _currentGeofenceId = null;
      _currentGeofence = null;
      _currentAssignmentId = null;
      _geofenceDistances.clear();
      _assignmentEarnings.clear();
      _geofenceEntryTimes.clear();
      _geofenceDurations.clear();
      
      // Check for per_hour rate types and start hourly tracking if needed
      await _startHourlyTrackingIfNeeded();
      
      // Sync any pending hourly tracking windows
      await HourlyTrackingService.performPeriodicSync();

      // Enhanced location settings optimized for background tracking  
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium, // Further reduced accuracy requirement
        distanceFilter: 10, // Only update when moved 10m (less frequent updates)
        timeLimit: Duration(seconds: 60), // Much longer timeout
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
          // Try to restart the stream after a delay with exponential backoff
          const retryDelay = Duration(seconds: 10); // Longer initial delay
          Timer(retryDelay, () {
            if (_isTracking) {
              if (kDebugMode) {
                print('📍 Stream failed, switching to periodic position requests...');
              }
              _startPeriodicLocationUpdates(); // Fallback to periodic requests
            }
          });
        },
        onDone: () {
          if (kDebugMode) {
            print('📍 Location stream completed');
          }
        },
      );

      // Start geofence monitoring if we have assignments or campaign
      if (_geofenceAssignments.isNotEmpty || _activeCampaign != null) {
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
        distanceFilter: 0,
        timeLimit: Duration(seconds: 10),
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
      _periodicLocationTimer?.cancel();
      _periodicLocationTimer = null;
      
      // Stop hourly tracking if it was started
      if (_hourlyTrackingService.isTracking) {
        await _hourlyTrackingService.stopHourlyTracking();
        if (kDebugMode) {
          print('📍 Stopped hourly tracking service');
        }
      }
      
      _isTracking = false;
      _activeCampaignId = null;
      _activeCampaign = null;
      _geofenceAssignments.clear();
      _wasInsideGeofence = false;
      
      // Clear multi-geofence tracking data
      _currentGeofenceId = null;
      _currentGeofence = null;
      _currentAssignmentId = null;
      _geofenceDistances.clear();
      _assignmentEarnings.clear();
      _geofenceEntryTimes.clear();
      _geofenceDurations.clear();
      
      // Try to sync any remaining unsynced locations and hourly windows
      if (_isOnline) {
        if (_unsyncedLocations.isNotEmpty) {
          await _syncStoredLocations();
        }
        await _syncPendingHourlyWindows();
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

      // Update location provider state if callback is set
      _positionUpdateCallback?.call(position);

      // Check if we should track this position update
      bool shouldTrack = _shouldTrackPosition(position);
      
      // Calculate distance if we have a previous position AND should track
      double distanceFromLast = 0.0;
      bool isMoving = false;
      
      if (_lastPosition != null && shouldTrack) {
        distanceFromLast = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (kDebugMode) {
        print('📍 Distance from last: $distanceFromLast');
        }
        // Add to total distance traveled (only when tracking)
        _totalDistance += distanceFromLast;
        
        // Add distance to current geofence if rider is inside one OR if debugging
        if (_currentGeofenceId != null || _suspendGeofenceChecking) {
          final geofenceId = _currentGeofenceId ?? _getDebugGeofenceId();
          
          if (geofenceId != null) {
            _geofenceDistances[geofenceId] = 
                (_geofenceDistances[geofenceId] ?? 0.0) + distanceFromLast;
            
            // Update earnings for current geofence
            _updateGeofenceEarnings(geofenceId, distanceFromLast);
            
            if (kDebugMode && _suspendGeofenceChecking && _currentGeofenceId == null) {
              print('🐛 DEBUG MODE: Earning without geofence check (using ${_findGeofenceById(geofenceId)?.name ?? geofenceId})');
            }
          }
        }
      }
      
      // Calculate movement status
      isMoving = distanceFromLast > AppConstants.movementThresholdMeters;
      
      if (kDebugMode) {
        print('📍 Should track: $shouldTrack');
        print('📍 Distance from last: ${distanceFromLast.toStringAsFixed(2)}m');
        print('📍 Current geofence: ${_currentGeofenceId != null ? _currentGeofence?.name ?? 'unknown' : 'NONE'}');
        print('📍 Total distance: ${(_totalDistance / 1000.0).toStringAsFixed(3)}km');
        print('📍 Total earnings: ₦${totalGeofenceEarnings.toStringAsFixed(2)}');
        print('📍 Movement status: ${isMoving ? 'moving' : 'stationary'}');
        if (!shouldTrack) {
          print('🚫 TRACKING PAUSED: ${_getTrackingPauseReason()}');
        }
      }
      
      if (isMoving) {
        _onMovement();
      } else {
        _onStationary();
      }

      // Only create and store location records when actively tracking
      if (shouldTrack) {
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
        
        if (kDebugMode) {
          print('📍 Location record stored successfully');
        }
      } else if (kDebugMode) {
        print('⏸️ Location record NOT stored - tracking paused');
      }
      
      _lastPosition = position;
      
      // Periodically sync hourly tracking windows (every 10th location update)
      _locationUpdateCount++;
      if (_locationUpdateCount % 10 == 0 && HourlyTrackingService.hasPendingWindows()) {
        HourlyTrackingService.performPeriodicSync().catchError((e) {
          if (kDebugMode) {
            print('❌ Periodic hourly sync failed: $e');
          }
        });
      }
      
      if (kDebugMode) {
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
  
  /// Sync pending hourly tracking windows when online
  Future<void> _syncPendingHourlyWindows() async {
    if (!_isOnline) return;
    
    try {
      final pendingCount = _hourlyTrackingService.pendingSyncWindowsCount;
      if (pendingCount > 0) {
        if (kDebugMode) {
          print('📍 Syncing $pendingCount pending hourly tracking windows...');
        }
        
        await _hourlyTrackingService.syncPendingWindows();
        
        if (kDebugMode) {
          print('📍 Hourly window sync completed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to sync hourly windows: $e');
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

  // Get unsynced location records
  Future<List<LocationRecord>> getUnsyncedLocations() async {
    return List.from(_unsyncedLocations);
  }

  // Mark locations as synced
  Future<void> markLocationsSynced(List<String> locationIds) async {
    _unsyncedLocations.removeWhere((record) => locationIds.contains(record.id));
  }


  // Find geofence by ID
  Geofence? _findGeofenceById(String geofenceId) {
    if (_activeCampaign != null) {
      for (final geofence in _activeCampaign!.geofences) {
        if (geofence.id == geofenceId) {
          return geofence;
        }
      }
    }
    return null;
  }

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


  // Fallback: Use periodic getCurrentPosition instead of stream
  void _startPeriodicLocationUpdates() {
    _periodicLocationTimer?.cancel();
    
    if (kDebugMode) {
      print('📍 Starting periodic location updates (every 30 seconds)...');
    }
    
    _periodicLocationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }
      
      try {
        final position = await getCurrentPosition();
        if (position != null) {
          _onLocationUpdate(position, _activeCampaignId);
        }
      } catch (e) {
        if (kDebugMode) {
          print('📍 Periodic location update failed: $e');
        }
      }
    });
  }

  // Start geofence monitoring
  void _startGeofenceMonitoring() {
    if (_geofenceAssignments.isEmpty && _activeCampaign == null) return;

    _geofenceCheckTimer = Timer.periodic(
      const Duration(seconds: 30), // Check every 30 seconds
      (timer) => _checkGeofence(),
    );

    if (kDebugMode) {
      print('🔍 Geofence monitoring started');
      print('🔍 Monitoring ${_geofenceAssignments.length} assigned geofences');
    }
  }

  // Check if rider is within assigned geofences - enhanced for assignment-based tracking
  void _checkGeofence() {
    if (_lastPosition == null) return;

    // Find which geofences the rider is currently inside
    Geofence? activeGeofence;
    String? activeGeofenceId;
    bool isInsideAnyGeofence = false;
    
    // First check assigned geofences (priority over campaign geofences)
    if (_geofenceAssignments.isNotEmpty) {
      for (final assignment in _geofenceAssignments) {
        // Only check active assignments
        if (assignment.status != GeofenceAssignmentStatus.active) continue;
        
        // Use assignment data directly instead of searching in empty campaign.geofences
        if (kDebugMode) {
          print('🔍 GEOFENCE CHECK: Checking ${assignment.geofenceName}');
          print('🔍   Center: ${assignment.centerLatitude}, ${assignment.centerLongitude}');
          print('🔍   Radius: ${assignment.radiusMeters ?? assignment.radius}m');
          print('🔍   Current position: ${_lastPosition!.latitude}, ${_lastPosition!.longitude}');
          
          // Calculate distance manually to verify
          final distance = Geolocator.distanceBetween(
            _lastPosition!.latitude, 
            _lastPosition!.longitude,
            assignment.centerLatitude, 
            assignment.centerLongitude
          );
          print('🔍   Distance to center: ${distance.toStringAsFixed(2)}m');
        }
        
        // Calculate if inside using assignment boundary data
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude, 
          _lastPosition!.longitude,
          assignment.centerLatitude, 
          assignment.centerLongitude
        );
        final radius = (assignment.radiusMeters ?? assignment.radius ?? 0).toDouble();
        final effectiveRadius = radius + _lastPosition!.accuracy;
        final isInside = distance <= effectiveRadius;
        
        if (kDebugMode) {
          print('🔍   Effective radius (radius + accuracy): ${effectiveRadius.toStringAsFixed(2)}m');
          print('🔍   Is inside: $isInside');
        }
        
        if (isInside) {
          isInsideAnyGeofence = true;
          
          // Use the first active geofence found (simplified logic since we're using assignments)
          if (activeGeofenceId == null) {
            activeGeofenceId = assignment.geofenceId;
            // Create a simple geofence object from assignment data for compatibility
            activeGeofence = Geofence(
              id: assignment.geofenceId,
              name: assignment.geofenceName,
              centerLatitude: assignment.centerLatitude,
              centerLongitude: assignment.centerLongitude,
              radius: (assignment.radiusMeters ?? assignment.radius ?? 0).toDouble(),
              startDate: assignment.startedAt ?? DateTime.now(),
              endDate: assignment.endedAt ?? DateTime.now().add(const Duration(days: 365)),
	      ratePerKm: assignment.ratePerKm,
	      rateType: assignment.rateType,
	      ratePerHour: assignment.ratePerHour,
	      fixedDailyRate: assignment.fixedDailyRate,
            );
          }
        }
      }
    }
    
    // Fallback to campaign geofences if no assignments but have active campaign
    if (!isInsideAnyGeofence && _activeCampaign != null) {
      for (final geofence in _activeCampaign!.geofences) {
        final isInside = geofence.containsPoint(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          accuracyBuffer: _lastPosition!.accuracy, // Add GPS accuracy as buffer
        );
        
        if (isInside) {
          isInsideAnyGeofence = true;
          
          // If no active geofence yet, or this one has higher priority
          if (activeGeofence == null || 
              (geofence.isHighPriority && !activeGeofence.isHighPriority) ||
              (geofence.isHighPriority == activeGeofence.isHighPriority && 
               (geofence.priority ?? 0) < (activeGeofence.priority ?? 0))) {
            activeGeofence = geofence;
            activeGeofenceId = geofence.id;
          }
        }
      }
    }

    // Check for geofence transitions
    if (_currentGeofenceId != activeGeofenceId) {
      // Exit current geofence if we were in one
      if (_currentGeofenceId != null) {
        _onGeofenceExit(_currentGeofenceId!, _currentGeofence);
      }
      
      // Enter new geofence if we found one
      if (activeGeofenceId != null && activeGeofence != null) {
        _onGeofenceEnter(activeGeofenceId, activeGeofence);
      }
      
      _currentGeofenceId = activeGeofenceId;
      _currentGeofence = activeGeofence;
    }

    _wasInsideGeofence = isInsideAnyGeofence;
  }

  // Handle rider entering geofence - enhanced for assignment-based tracking
  void _onGeofenceEnter(String geofenceId, Geofence geofence) {
    // Find active assignment for this geofence
    final assignment = _geofenceAssignments.firstWhere(
      (a) => a.geofenceId == geofenceId && a.status == GeofenceAssignmentStatus.active,
      orElse: () => throw Exception('No active assignment found for geofence $geofenceId'),
    );
    
    if (kDebugMode) {
      print('✅ Rider entered geofence: ${geofence.name} (ID: $geofenceId)');
      print('✅ Geofence rate type: ${assignment.rateType}');
      print('✅ Rate per km: ${assignment.ratePerKm}, Rate per hour: ${assignment.ratePerHour}');
    }
    
    // Update current assignment ID for tracking
    _currentAssignmentId = assignment.id;
    
    // Record entry time for this geofence
    _geofenceEntryTimes[geofenceId] = DateTime.now();
    
    // Initialize tracking data for this geofence if not exists
    _geofenceDistances[geofenceId] ??= 0.0;
    _assignmentEarnings[assignment.id] ??= 0.0; // Track earnings per assignment
    _geofenceDurations[geofenceId] ??= Duration.zero;

    // Store geofence event
    _recordGeofenceEvent('enter', geofenceId: geofenceId, geofenceName: geofence.name, assignmentId: assignment.id);
  }

  // Handle rider leaving geofence - enhanced for assignment-based tracking
  void _onGeofenceExit(String geofenceId, Geofence? geofence) {
    if (kDebugMode) {
      print('⚠️ Rider left geofence: ${geofence?.name ?? 'Unknown'} (ID: $geofenceId)');
    }

    // Find assignment for this geofence
    final assignment = _geofenceAssignments.firstWhere(
      (a) => a.geofenceId == geofenceId,
      orElse: () => GeofenceAssignment(
        id: 'unknown',
        geofenceId: geofenceId,
        geofenceName: 'Unknown',
        status: GeofenceAssignmentStatus.cancelled,
        centerLatitude: 0.0,
        centerLongitude: 0.0,
        radiusMeters: 0,
      ),
    );

    // Calculate time spent in this geofence
    if (_geofenceEntryTimes.containsKey(geofenceId)) {
      final entryTime = _geofenceEntryTimes[geofenceId]!;
      final exitTime = DateTime.now();
      final timeSpent = exitTime.difference(entryTime);
      
      // Add to total duration for this geofence
      _geofenceDurations[geofenceId] = 
          (_geofenceDurations[geofenceId] ?? Duration.zero) + timeSpent;
      
      if (kDebugMode) {
        print('⏱️ Time spent in geofence: ${timeSpent.inMinutes} minutes');
        print('⏱️ Total time in this geofence: ${_geofenceDurations[geofenceId]!.inMinutes} minutes');
      }
      
      // Update earnings based on time if geofence uses hourly or hybrid rates
      if (geofence != null && assignment.id != 'unknown') {
        _updateAssignmentEarningsForTime(assignment.id, geofence, timeSpent);
      }
      
      // Remove entry time
      _geofenceEntryTimes.remove(geofenceId);
    }

    // Clear current assignment when exiting
    if (_currentAssignmentId == assignment.id) {
      _currentAssignmentId = null;
    }

    // Show notification about leaving geofence
    if (geofence != null) {
      NotificationService.showCampaignUpdate(
        title: 'Geofence Area Warning',
        message: 'You have left the ${geofence.name} area. Move to another campaign area to continue earning.',
      );
    }

    // Store geofence event
    _recordGeofenceEvent('exit', geofenceId: geofenceId, geofenceName: geofence?.name, assignmentId: assignment.id);
  }

  // Record geofence events for tracking compliance - enhanced for assignment-based tracking
  void _recordGeofenceEvent(String eventType, {String? geofenceId, String? geofenceName, String? assignmentId}) {
    if (_lastPosition == null || _activeCampaign == null) return;

    try {
      final geofenceEvent = {
        'type': eventType,
        'campaign_id': _activeCampaign!.id,
        'geofence_id': geofenceId,
        'geofence_name': geofenceName,
        'assignment_id': assignmentId, // Track assignment for earnings attribution
        'latitude': _lastPosition!.latitude,
        'longitude': _lastPosition!.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'accuracy': _lastPosition!.accuracy,
        'distance_in_geofence': geofenceId != null ? _geofenceDistances[geofenceId] : null,
        'earnings_from_assignment': assignmentId != null ? _assignmentEarnings[assignmentId] : null, // Assignment-based earnings
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
        print('📍 Geofence event recorded: $eventType for ${geofenceName ?? "unknown geofence"} (Assignment: ${assignmentId ?? "unknown"})');
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
  List<GeofenceAssignment> get geofenceAssignments => List.unmodifiable(_geofenceAssignments);

  // Check if currently within geofence - real-time check
  bool get isWithinActiveGeofence {
    if (_lastPosition == null) return false;
    
    // Check assigned geofences first (priority)
    if (_geofenceAssignments.isNotEmpty) {
      for (final assignment in _geofenceAssignments) {
        if (assignment.status != GeofenceAssignmentStatus.active) continue;
        
        // Use assignment boundary data directly instead of searching in empty campaign.geofences
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          assignment.centerLatitude,
          assignment.centerLongitude,
        );
        
        final radius = (assignment.radiusMeters ?? assignment.radius ?? 0).toDouble();
        final effectiveRadius = radius + _lastPosition!.accuracy;
        final isInside = distance <= effectiveRadius;
        
        if (isInside) {
          return true;
        }
      }
    }
    
    // Fallback to campaign geofences
    if (_activeCampaign != null) {
      for (final geofence in _activeCampaign!.geofences) {
        if (geofence.containsPoint(_lastPosition!.latitude, _lastPosition!.longitude)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  // Get current geofence information
  Geofence? get currentGeofence => _currentGeofence;
  String? get currentGeofenceId => _currentGeofenceId;
  
  // Get geofence-specific tracking data  
  Map<String, double> get geofenceDistances => Map.unmodifiable(_geofenceDistances);
  Map<String, double> get geofenceEarnings => Map.unmodifiable(_assignmentEarnings); // For UI compatibility
  Map<String, Duration> get geofenceDurations => Map.unmodifiable(_geofenceDurations);
  
  // Get assignment-specific tracking data
  Map<String, double> get assignmentEarnings => Map.unmodifiable(_assignmentEarnings);
  
  // Get real-time duration for current geofence (for per_hour tracking UI)
  Duration? getCurrentGeofenceDuration(String geofenceId) {
    if (!_geofenceEntryTimes.containsKey(geofenceId)) {
      return _geofenceDurations[geofenceId];
    }
    
    final entryTime = _geofenceEntryTimes[geofenceId]!;
    final currentTime = DateTime.now();
    final currentSessionDuration = currentTime.difference(entryTime);
    
    // Add current session duration to any previous duration
    final previousDuration = _geofenceDurations[geofenceId] ?? Duration.zero;
    return previousDuration + currentSessionDuration;
  }
  
  // Get total earnings across all assignments (consistent with earnings history)
  double get totalGeofenceEarnings {
    return _assignmentEarnings.values.fold(0.0, (sum, earnings) => sum + earnings);
  }

  // Update geofence assignments during runtime (called when getMyCampaigns() detects changes)
  Future<void> updateGeofenceAssignments(List<GeofenceAssignment> newAssignments) async {
    if (kDebugMode) {
      print('📍 Updating geofence assignments: ${newAssignments.length} assignments');
    }
    
    _geofenceAssignments = newAssignments;
    
    // Update hourly tracking based on new assignments
    await _updateHourlyTrackingForAssignments();
    
    // If we're tracking and now have assignments, start monitoring
    if (_isTracking && _geofenceAssignments.isNotEmpty) {
      if (_geofenceCheckTimer == null) {
        _startGeofenceMonitoring();
      }
    }
    
    // If no assignments left, we might need to stop specific monitoring
    if (_geofenceAssignments.isEmpty && _activeCampaign == null) {
      _geofenceCheckTimer?.cancel();
      _geofenceCheckTimer = null;
      if (kDebugMode) {
        print('📍 No assignments or campaign - stopped geofence monitoring');
      }
    }
  }

  // Calculate earnings eligibility based on location (enhanced for assignments)
  bool isEligibleForEarnings() {
    // If tracking with assignments, check if inside assigned geofence
    if (_isTracking && _geofenceAssignments.isNotEmpty) {
      return _wasInsideGeofence && _currentGeofenceId != null;
    }
    
    // Fallback to campaign-based eligibility
    return _isTracking && 
           _activeCampaign != null && 
           _wasInsideGeofence;
  }

  // Get distance to active campaign center - enhanced for multiple geofences
  double? getDistanceToActiveCampaign() {
    if (_lastPosition == null || _activeCampaign == null || _activeCampaign!.geofences.isEmpty) return null;
    
    // If currently in a geofence, return 0
    if (_currentGeofence != null) return 0.0;
    
    // Find closest geofence
    double? minDistance;
    for (final geofence in _activeCampaign!.geofences) {
      final distance = calculateDistance(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        geofence.centerLatitude,
        geofence.centerLongitude,
      );
      
      if (minDistance == null || distance < minDistance) {
        minDistance = distance;
      }
    }
    
    return minDistance;
  }
  
  // Get distance to nearest available geofence
  Map<String, double> getDistancesToAllGeofences() {
    if (_lastPosition == null || _activeCampaign == null) return {};
    
    final distances = <String, double>{};
    for (final geofence in _activeCampaign!.geofences) {
      distances[geofence.id ?? 'unknown_${distances.length}'] = calculateDistance(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        geofence.centerLatitude,
        geofence.centerLongitude,
      );
    }
    
    return distances;
  }
  
  // Helper method to get a geofence ID for debug mode earnings
  String? _getDebugGeofenceId() {
    // Use first active geofence assignment
    if (_geofenceAssignments.isNotEmpty) {
      final activeAssignment = _geofenceAssignments
          .where((a) => a.status == GeofenceAssignmentStatus.active)
          .firstOrNull;
      if (activeAssignment != null) {
        return activeAssignment.geofenceId;
      }
    }
    
    // Fallback to first campaign geofence
    if (_activeCampaign != null && _activeCampaign!.geofences.isNotEmpty) {
      return _activeCampaign!.geofences.first.id;
    }
    
    return null;
  }
  
  // Debug method to toggle geofence checking suspension
  void setDebugMode(bool suspend) {
    _suspendGeofenceChecking = suspend;
    if (kDebugMode) {
      print('🐛 DEBUG MODE: Geofence restrictions ${suspend ? 'SUSPENDED' : 'RESTORED'}');
      print('🐛 Tracking and earnings will now occur ${suspend ? 'everywhere' : 'only inside active geofence assignments'}');
    }
  }
  
  bool get isDebugModeActive => _suspendGeofenceChecking;
  
  // Get current tracking eligibility status
  bool get isCurrentlyTracking {
    if (!_isTracking) return false;
    if (_lastPosition == null) return false;
    return _shouldTrackPosition(_lastPosition!);
  }
  
  // Check if we should track the current position (always track when active, regardless of geofence)
  bool _shouldTrackPosition(Position position) {
    // Always track when tracking is active - location samples are collected continuously
    // Only earnings calculations are restricted to geofence boundaries
    return true;
  }
  
  // Get reason why tracking is paused (for debugging)
  String _getTrackingPauseReason() {
    if (_geofenceAssignments.isEmpty) {
      return 'No geofence assignments';
    }
    
    final activeAssignments = _geofenceAssignments
        .where((a) => a.status == GeofenceAssignmentStatus.active)
        .toList();
    
    if (activeAssignments.isEmpty) {
      return 'No active geofence assignments (${_geofenceAssignments.length} total)';
    }
    
    // Enhanced debugging for the "1 active assignment but no geofence" issue
    if (kDebugMode && _lastPosition != null) {
      print('🔍 DETAILED TRACKING PAUSE ANALYSIS:');
      print('🔍 Active assignments: ${activeAssignments.length}');
      
      for (int i = 0; i < activeAssignments.length; i++) {
        final assignment = activeAssignments[i];
        print('🔍 [$i] Assignment: ${assignment.geofenceName} (ID: ${assignment.geofenceId})');
        
        // Use assignment boundary data directly instead of searching in empty campaign.geofences
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude, 
          _lastPosition!.longitude,
          assignment.centerLatitude, 
          assignment.centerLongitude
        );
        final radius = (assignment.radiusMeters ?? assignment.radius ?? 0).toDouble();
        final effectiveRadius = radius + _lastPosition!.accuracy;
        final shouldBeInside = distance <= effectiveRadius;
        
        print('🔍 [$i] Geofence: ${assignment.geofenceName}');
        print('🔍 [$i] Distance: ${distance.toStringAsFixed(2)}m');
        print('🔍 [$i] Radius: ${radius}m');
        print('🔍 [$i] GPS accuracy: ${_lastPosition!.accuracy.toStringAsFixed(2)}m');
        print('🔍 [$i] Effective radius: ${effectiveRadius.toStringAsFixed(2)}m');
        print('🔍 [$i] Should be inside: $shouldBeInside');
        
        if (!shouldBeInside) {
          final distanceOutside = distance - radius;
          print('🔍 [$i] Distance outside geofence: ${distanceOutside.toStringAsFixed(2)}m');
        }
      }
    }
    
    return 'Outside all active geofences (${activeAssignments.length} active assignments)';
  }
  
  // Update earnings for a specific geofence based on distance - assignment-based
  void _updateGeofenceEarnings(String geofenceId, double distanceMeters) {
    // In debug mode, find geofence if _currentGeofence is null
    Geofence? geofence = _currentGeofence;
    if (geofence == null && _suspendGeofenceChecking) {
      geofence = _findGeofenceById(geofenceId);
    }
    
    if (geofence == null) return;
    
    // Find assignment for this geofence to track earnings per assignment
    final assignment = _geofenceAssignments.firstWhere(
      (a) => a.geofenceId == geofenceId && a.status == GeofenceAssignmentStatus.active,
      orElse: () => throw Exception('No active assignment found for geofence $geofenceId'),
    );
    
    final distanceKm = distanceMeters / 1000.0;
    double additionalEarnings = 0.0;
    
    if (kDebugMode) {
      print('💰 EARNINGS UPDATE: Geofence ${geofence.name} (Assignment: ${assignment.id})');
      print('💰   Rate Type: ${assignment.rateType}');
      print('💰   Rate Per Km: ${assignment.ratePerKm}');
      print('💰   Distance: ${distanceKm.toStringAsFixed(4)} km (${distanceMeters.toStringAsFixed(2)}m)');
      if (_suspendGeofenceChecking && _currentGeofence == null) {
        print('🐛 DEBUG MODE: Calculating earnings without geofence boundary check');
      }
    }
    
    switch (assignment.rateType) {
      case 'per_km':
        additionalEarnings = (assignment.ratePerKm ?? 0.0) * distanceKm;
        break;
      case 'hybrid':
        // For hybrid, we add distance-based earnings here, time-based on exit
        additionalEarnings = (assignment.ratePerKm ?? 0.0) * distanceKm;
        break;
      case 'per_hour':
      case 'fixed_daily':
        // These are calculated on geofence exit based on time
        additionalEarnings = 0.0;
        break;
    }
    
    // Track earnings per assignment for UX consistency with earnings history
    _assignmentEarnings[assignment.id] = 
        (_assignmentEarnings[assignment.id] ?? 0.0) + additionalEarnings;
    
    if (kDebugMode) {
      print('💰   Additional Earnings: ₦${additionalEarnings.toStringAsFixed(4)}');
      print('💰   Assignment Total: ₦${_assignmentEarnings[assignment.id]!.toStringAsFixed(4)}');
      print('💰   Total All Assignments: ₦${totalGeofenceEarnings.toStringAsFixed(4)}');
    }
  }
  
  // Update earnings for time-based rates when exiting geofence - assignment-based
  void _updateAssignmentEarningsForTime(String assignmentId, Geofence geofence, Duration timeSpent) {
    // Find the assignment to get the correct rate data
    final assignment = _geofenceAssignments.firstWhere(
      (a) => a.id == assignmentId,
      orElse: () => GeofenceAssignment(
        id: assignmentId,
        geofenceId: geofence.id ?? 'unknown',
        geofenceName: geofence.name ?? 'Unknown',
        status: GeofenceAssignmentStatus.cancelled,
        centerLatitude: 0.0,
        centerLongitude: 0.0,
        radiusMeters: 0,
      ),
    );
    
    double additionalEarnings = 0.0;
    final hoursSpent = timeSpent.inMilliseconds / (1000 * 60 * 60);
    
    switch (assignment.rateType) {
      case 'per_hour':
        additionalEarnings = (assignment.ratePerHour ?? 0.0) * hoursSpent;
        break;
      case 'fixed_daily':
        // For fixed daily, award proportional amount based on time spent
        final dailyHours = (geofence.targetCoverageHours ?? 8).toDouble();
        if (dailyHours > 0) {
          additionalEarnings = (assignment.fixedDailyRate ?? 0.0) * (hoursSpent / dailyHours);
        }
        break;
      case 'hybrid':
        // For hybrid, add time-based component (distance was added during movement)
        additionalEarnings = (assignment.ratePerHour ?? 0.0) * hoursSpent;
        break;
      case 'per_km':
        // No additional earnings for pure distance-based rates
        additionalEarnings = 0.0;
        break;
    }
    
    if (additionalEarnings > 0) {
      _assignmentEarnings[assignmentId] = 
          (_assignmentEarnings[assignmentId] ?? 0.0) + additionalEarnings;
      
      if (kDebugMode) {
        print('💰 Added ₦${additionalEarnings.toStringAsFixed(2)} for ${timeSpent.inMinutes} minutes in ${geofence.name} (Assignment: $assignmentId)');
        print('💰 Total earnings from this assignment: ₦${_assignmentEarnings[assignmentId]!.toStringAsFixed(2)}');
      }
    }
  }
  
  // Get earnings breakdown per assignment (consistent with earnings history UX)
  Map<String, Map<String, dynamic>> getEarningsBreakdown() {
    if (_geofenceAssignments.isEmpty) return {};
    
    final breakdown = <String, Map<String, dynamic>>{};
    
    for (final assignment in _geofenceAssignments) {
      final geofenceId = assignment.geofenceId;
      breakdown[assignment.id] = {
        'assignment_id': assignment.id,
        'geofence_name': assignment.geofenceName,
        'geofence_id': geofenceId,
        'rate_type': assignment.rateType,
        'status': assignment.status.toString(),
        'distance_km': (_geofenceDistances[geofenceId] ?? 0.0) / 1000.0,
        'duration_minutes': (_geofenceDurations[geofenceId] ?? Duration.zero).inMinutes,
        'earnings': _assignmentEarnings[assignment.id] ?? 0.0, // Assignment-based earnings
        'rate_per_km': assignment.ratePerKm,
        'rate_per_hour': assignment.ratePerHour,
        'fixed_daily_rate': assignment.fixedDailyRate,
      };
    }
    
    return breakdown;
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

  /// Start hourly tracking service for geofences with per_hour rate type
  Future<void> _startHourlyTrackingIfNeeded() async {
    try {
      if (kDebugMode) {
        print('🕐 CHECKING HOURLY TRACKING: Total assignments: ${_geofenceAssignments.length}');
        for (final assignment in _geofenceAssignments) {
          print('🕐   Assignment: ${assignment.geofenceName} - Rate Type: ${assignment.rateType}');
        }
      }
      
      // Check if any geofence assignments have per_hour rate type
      final hourlyGeofences = _geofenceAssignments.where((assignment) {
        return assignment.rateType == 'per_hour';
      }).toList();

      if (hourlyGeofences.isNotEmpty) {
        if (kDebugMode) {
          print('🕐 HOURLY TRACKING: Found ${hourlyGeofences.length} per_hour geofences');
          for (final assignment in hourlyGeofences) {
            print('🕐   - ${assignment.geofenceName} (₦${assignment.ratePerHour}/hr)');
          }
        }

        // Start hourly tracking for the first per_hour geofence assignment
        // Note: HourlyTrackingService currently supports one assignment at a time
        // Future enhancement could support multiple assignments
        final primaryHourlyAssignment = hourlyGeofences.first;
        final geofenceId = primaryHourlyAssignment.geofenceId;  // Fixed: use direct geofenceId
        final campaignId = _activeCampaignId ?? '';
        final assignmentId = primaryHourlyAssignment.id ?? '';

        await _hourlyTrackingService.startHourlyTracking(
          geofenceId: geofenceId,
          campaignId: campaignId,
          assignmentId: assignmentId,
        );

        if (kDebugMode) {
          print('🕐 HOURLY TRACKING: Started for assignment $assignmentId');
          print('🕐 HOURLY TRACKING: Geofence ID: $geofenceId');
          print('🕐 HOURLY TRACKING: Geofence: ${primaryHourlyAssignment.geofenceName}');
          print('🕐 HOURLY TRACKING: Rate: ₦${primaryHourlyAssignment.ratePerHour ?? 0}/hr');
          print('🕐 HOURLY TRACKING: Working hours: 7 AM - 6 PM');
          print('🕐 HOURLY TRACKING: Sample interval: 5 minutes');
          print('🕐 HOURLY TRACKING: Minimum billable time: 10 minutes');
        }
      } else {
        if (kDebugMode) {
          print('🕐 HOURLY TRACKING: No per_hour geofences found, using standard distance tracking');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ HOURLY TRACKING ERROR: Failed to start hourly tracking: $e');
      }
    }
  }

  /// Add hourly earnings from HourlyTrackingService to update UI
  /// Tracks earnings per assignment for UX consistency with earnings history
  Future<void> addHourlyEarnings(String assignmentId, double amount) async {
    if (amount > 0) {
      _assignmentEarnings[assignmentId] = 
          (_assignmentEarnings[assignmentId] ?? 0.0) + amount;
      
      if (kDebugMode) {
        print('💰 HOURLY EARNINGS: Added ₦${amount.toStringAsFixed(2)} to assignment $assignmentId');
        print('💰 Assignment total: ₦${_assignmentEarnings[assignmentId]!.toStringAsFixed(2)}');
        print('💰 Grand total: ₦${totalGeofenceEarnings.toStringAsFixed(2)}');
      }
    }
  }

  /// Update hourly tracking when geofence assignments change
  Future<void> _updateHourlyTrackingForAssignments() async {
    try {
      final currentHourlyGeofences = _geofenceAssignments.where((assignment) {
        return assignment.rateType == 'per_hour';
      }).toList();

      final wasHourlyTracking = _hourlyTrackingService.isTracking;
      final hasHourlyGeofences = currentHourlyGeofences.isNotEmpty;

      if (kDebugMode) {
        print('🕐 HOURLY TRACKING UPDATE: Was tracking: $wasHourlyTracking, Has hourly geofences: $hasHourlyGeofences');
      }

      if (wasHourlyTracking && !hasHourlyGeofences) {
        // Stop hourly tracking - no more per_hour geofences
        await _hourlyTrackingService.stopHourlyTracking();
        if (kDebugMode) {
          print('🕐 HOURLY TRACKING: Stopped - no per_hour geofences remaining');
        }
      } else if (!wasHourlyTracking && hasHourlyGeofences) {
        // Start hourly tracking - new per_hour geofences detected
        await _startHourlyTrackingIfNeeded();
      } else if (wasHourlyTracking && hasHourlyGeofences) {
        // Already tracking but assignments changed - restart with new geofence
        await _hourlyTrackingService.stopHourlyTracking();
        await _startHourlyTrackingIfNeeded();
        if (kDebugMode) {
          print('🕐 HOURLY TRACKING: Restarted with updated assignments');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ HOURLY TRACKING UPDATE ERROR: $e');
      }
    }
  }
  
  /// Clear all user-specific location data on logout
  Future<void> clearUserLocationData() async {
    try {
      if (kDebugMode) {
        print('🧹 LOCATION SERVICE: Clearing user data on logout...');
      }
      
      // Stop all tracking first
      await stopTracking();
      
      // Clear any remaining state
      _lastPosition = null;
      _wasInsideGeofence = false;
      _activeCampaignId = null;
      _activeCampaign = null;
      _geofenceAssignments.clear();
      
      // Cancel all timers
      _stationaryTimer?.cancel();
      _stationaryTimer = null;
      _geofenceCheckTimer?.cancel();
      _geofenceCheckTimer = null;
      _periodicLocationTimer?.cancel();
      _periodicLocationTimer = null;
      
      // Reset tracking state
      _isTracking = false;
      _isGettingPosition = false;
      
      if (kDebugMode) {
        print('✅ LOCATION SERVICE: User data cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LOCATION SERVICE: Error clearing user data: $e');
      }
    }
  }
}
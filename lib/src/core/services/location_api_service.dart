import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/location_record.dart';
import '../storage/hive_service.dart';
import 'api_service.dart';

class LocationApiService {
  final ApiService _apiService;
  final Uuid _uuid = const Uuid();

  LocationApiService(this._apiService);

  /// Truncates accuracy to 8 digits maximum for consistency
  static double _truncateAccuracy(double accuracy) {
    final accuracyString = accuracy.toString();
    if (accuracyString.length <= 8) {
      return accuracy;
    }
    
    final truncated = accuracyString.substring(0, 8);
    return double.tryParse(truncated) ?? accuracy;
  }

  // Upload location records to server using new tracking endpoint
  Future<Map<String, dynamic>> uploadLocations(List<LocationRecord> locations) async {
    if (locations.isEmpty) {
      return {'success': true, 'processed_count': 0, 'failed_count': 0};
    }

    try {
      final batchId = _uuid.v4();
      if (kDebugMode) {
        print('📍 Syncing ${locations.length} locations with batch ID: $batchId');
      }
      
      // Convert location records to new API format
      final locationData = locations.map((location) => {
        'mobile_id': location.id,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracy': location.accuracy,
        'speed': location.speed,
        'heading': location.heading,
        'altitude': location.altitude,
        'recorded_at': location.timestamp.toIso8601String(),
        'is_working': location.isWorking,
        'campaign_id': location.campaignId,
        'metadata': location.metadata ?? {},
      }).toList();

      final result = await _apiService.syncLocationBatch(locationData, batchId);
      
      if (kDebugMode) {
        print('📍 Batch sync result: $result');
      }
      
      // Mark successfully synced locations as synced
      if (result['processed_count'] != null && result['processed_count'] > 0) {
        await _markLocationsAsSynced(locations, result);
      }
      
      return result;

    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to upload locations: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'processed_count': 0,
        'failed_count': locations.length,
      };
    }
  }

  // Upload geofence events
  Future<bool> uploadGeofenceEvents(List<Map<String, dynamic>> events) async {
    if (events.isEmpty) return true;

    try {
      final response = await _apiService.post('/rider/geofence-events/bulk/', 
        data: {
          'events': events,
        });

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (kDebugMode) {
          print('🔍 Successfully uploaded ${events.length} geofence events');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to upload geofence events: $e');
      }
      return false;
    }
  }

  // Get rider's location history from server
  Future<List<LocationRecord>?> getLocationHistory({
    String? campaignId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (campaignId != null) queryParams['campaign_id'] = campaignId;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiService.get('/rider/locations/', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> locationsJson = response.data['results'] ?? response.data;
        
        return locationsJson.map((json) => LocationRecord.fromJson(json)).toList();
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get location history: $e');
      }
      return null;
    }
  }

  // Get location stats for rider
  Future<Map<String, dynamic>?> getLocationStats({
    String? campaignId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (campaignId != null) queryParams['campaign_id'] = campaignId;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _apiService.get('/rider/location-stats/', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get location stats: $e');
      }
      return null;
    }
  }

  // Mark locations as synced in local storage
  Future<void> _markLocationsAsSynced(
    List<LocationRecord> locations, 
    Map<String, dynamic> syncResult
  ) async {
    try {
      // Get the list of successfully processed mobile IDs
      final processedCount = syncResult['processed_count'] as int? ?? 0;
      final errors = syncResult['errors'] as List? ?? [];
      
      // Create a set of failed mobile IDs for quick lookup
      final failedMobileIds = <String>{};
      for (final error in errors) {
        if (error is Map<String, dynamic> && error['mobile_id'] != null) {
          failedMobileIds.add(error['mobile_id'] as String);
        }
      }
      
      // Mark locations as synced if they weren't in the failed list
      int marked = 0;
      for (final location in locations) {
        if (!failedMobileIds.contains(location.id) && marked < processedCount) {
          final syncedLocation = location.copyWith(isSynced: true);
          await HiveService.updateLocationRecord(syncedLocation);
          marked++;
        }
      }
      
      if (kDebugMode) {
        print('📍 Marked $marked locations as synced');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to mark locations as synced: $e');
      }
    }
  }

  // Get tracking statistics from backend
  Future<Map<String, dynamic>> getTrackingStats() async {
    try {
      return await _apiService.getTrackingStats();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get tracking stats: $e');
      }
      return {
        'today_distance': 0.0,
        'today_earnings': 0.0,
        'today_sessions': 0,
        'week_distance': 0.0,
        'week_earnings': 0.0,
        'month_distance': 0.0,
        'month_earnings': 0.0,
        'active_geofences': <String>[],
        'pending_sync_count': 0,
        'last_sync': null,
      };
    }
  }

  // Calculate earnings on backend
  Future<Map<String, dynamic>> calculateEarnings({
    required String mobileId,
    required int geofenceId,
    required String earningsType,
    required double distanceKm,
    required double durationHours,
    required int verificationsCompleted,
    required DateTime earnedAt,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      return await _apiService.calculateEarnings(
        mobileId: mobileId,
        geofenceId: geofenceId,
        earningsType: earningsType,
        distanceKm: distanceKm,
        durationHours: durationHours,
        verificationsCompleted: verificationsCompleted,
        earnedAt: earnedAt,
        metadata: metadata,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to calculate earnings: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  // Sync all pending location data
  Future<Map<String, dynamic>> syncAllLocationData() async {
    try {
      // Get unsynced locations
      final unsyncedLocations = HiveService.getUnsyncedLocations();
      if (unsyncedLocations.isNotEmpty) {
        final result = await uploadLocations(unsyncedLocations);
        if (result['success'] == true) {
          if (kDebugMode) {
            print('📍 Successfully synced ${result['processed_count']} locations');
          }
        }
        return result;
      }

      // Get and upload geofence events
      final geofenceEvents = HiveService.getSetting<List<dynamic>>('geofence_events') ?? [];
      if (geofenceEvents.isNotEmpty) {
        final success = await uploadGeofenceEvents(geofenceEvents.cast<Map<String, dynamic>>());
        if (success) {
          // Clear synced events
          await HiveService.saveSetting('geofence_events', <Map<String, dynamic>>[]);
        }
      }

      if (kDebugMode) {
        print('📍 Location data sync completed');
      }
      
      return {'success': true, 'processed_count': 0, 'message': 'No data to sync'};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to sync location data: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  // Check if rider is within campaign boundaries (server validation)
  Future<bool> validateLocationForCampaign({
    required String campaignId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiService.post('/rider/validate-location/', 
        data: {
          'campaign_id': campaignId,
          'latitude': latitude,
          'longitude': longitude,
        });

      if (response.statusCode == 200) {
        return response.data['is_valid'] ?? false;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to validate location: $e');
      }
      return false;
    }
  }

  // Get nearby campaigns based on current location
  Future<List<Map<String, dynamic>>?> getNearbyCampaigns({
    required double latitude,
    required double longitude,
    double radius = 5000, // 5km default
  }) async {
    try {
      final response = await _apiService.get('/rider/nearby-campaigns/', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      });

      if (response.statusCode == 200) {
	 if (kDebugMode) {
        print('📢 RAW CAMPAIGNS API RESPONSE: ${response.data}'); 
      }
        return List<Map<String, dynamic>>.from(response.data['results'] ?? response.data);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get nearby campaigns: $e');
      }
      return null;
    }
  }

  // Report location anomaly (for defensive security)
  Future<void> reportLocationAnomaly({
    required String anomalyType,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _apiService.post('/rider/location-anomaly/', 
        data: {
          'anomaly_type': anomalyType,
          'details': details,
          'timestamp': DateTime.now().toIso8601String(),
        });

      if (kDebugMode) {
        print('🚨 Location anomaly reported: $anomalyType');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to report location anomaly: $e');
      }
    }
  }
}
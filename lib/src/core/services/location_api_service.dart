import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/location_record.dart';
import '../storage/hive_service.dart';
import 'api_service.dart';

class LocationApiService {
  final ApiService _apiService;

  LocationApiService(this._apiService);

  // Upload location records to server
  Future<bool> uploadLocations(List<LocationRecord> locations) async {
    if (locations.isEmpty) return true;

    try {
      final locationData = locations.map((location) => {
        'id': location.id,
        'rider_id': location.riderId,
        'campaign_id': location.campaignId,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracy': location.accuracy,
        'speed': location.speed,
        'heading': location.heading,
        'altitude': location.altitude,
        'timestamp': location.timestamp.toIso8601String(),
        'is_working': location.isWorking,
        'created_at': location.createdAt.toIso8601String(),
      }).toList();

      final response = await _apiService.post('/rider/locations/bulk/', 
        data: {
          'locations': locationData,
        });

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (kDebugMode) {
          print('📍 Successfully uploaded ${locations.length} locations');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to upload locations: $e');
      }
      return false;
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

  // Sync all pending location data
  Future<void> syncAllLocationData() async {
    try {
      // Get unsynced locations
      final unsyncedLocations = HiveService.getUnsyncedLocations();
      if (unsyncedLocations.isNotEmpty) {
        final success = await uploadLocations(unsyncedLocations);
        if (success) {
          // Mark as synced
          final locationIds = unsyncedLocations.map((l) => l.id).toList();
          await HiveService.markLocationsSynced(locationIds);
        }
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
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to sync location data: $e');
      }
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
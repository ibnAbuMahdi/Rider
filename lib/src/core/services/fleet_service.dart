import 'package:flutter/foundation.dart';

import '../models/fleet_owner.dart';
import '../models/fleet_status.dart';
import 'api_service.dart';

class FleetService {
  final ApiService _apiService;

  FleetService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  /// Lookup fleet information by fleet code
  /// 
  /// Returns fleet information if code is valid and fleet is active
  Future<FleetLookupResult> lookupFleetByCode(String fleetCode) async {
    try {
      if (fleetCode.trim().isEmpty) {
        return const FleetLookupResult(
          success: false,
          message: 'Fleet code cannot be empty',
        );
      }

      final response = await _apiService.post(
        '/fleets/lookup/',
        data: {
          'fleet_code': fleetCode.trim().toUpperCase(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true && data['fleet'] != null) {
        final fleet = FleetOwner.fromJson(data['fleet'] as Map<String, dynamic>);
        
        return FleetLookupResult(
          success: true,
          message: data['message'] as String? ?? 'Fleet found successfully',
          fleet: fleet,
        );
      } else {
        return FleetLookupResult(
          success: false,
          message: data['message'] as String? ?? 'Fleet lookup failed',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fleet lookup error: $e');
      }
      
      String errorMessage = 'Failed to lookup fleet';
      if (e is ApiException) {
        errorMessage = e.message;
      }
      
      return FleetLookupResult(
        success: false,
        message: errorMessage,
      );
    }
  }

  /// Join a fleet using fleet code
  /// 
  /// Returns success status and updated rider/fleet information
  Future<FleetJoinResult> joinFleet(String fleetCode) async {
    try {
      if (fleetCode.trim().isEmpty) {
        return const FleetJoinResult(
          success: false,
          message: 'Fleet code cannot be empty',
        );
      }

      final response = await _apiService.post(
        '/fleets/join/',
        data: {
          'fleet_code': fleetCode.trim().toUpperCase(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        FleetOwner? fleet;
        RiderFleetInfo? rider;
        
        if (data['fleet'] != null) {
          fleet = FleetOwner.fromJson(data['fleet'] as Map<String, dynamic>);
        }
        
        if (data['rider'] != null) {
          rider = RiderFleetInfo.fromJson(data['rider'] as Map<String, dynamic>);
        }
        
        return FleetJoinResult(
          success: true,
          message: data['message'] as String? ?? 'Joined fleet successfully',
          fleet: fleet,
          rider: rider,
        );
      } else {
        return FleetJoinResult(
          success: false,
          message: data['message'] as String? ?? 'Failed to join fleet',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fleet join error: $e');
      }
      
      String errorMessage = 'Failed to join fleet';
      if (e is ApiException) {
        errorMessage = e.message;
      }
      
      return FleetJoinResult(
        success: false,
        message: errorMessage,
      );
    }
  }

  /// Leave current fleet
  /// 
  /// Returns success status and updated rider information
  Future<FleetLeaveResult> leaveFleet({String? reason}) async {
    try {
      final requestData = <String, dynamic>{};
      if (reason != null && reason.trim().isNotEmpty) {
        requestData['reason'] = reason.trim();
      }

      final response = await _apiService.post(
        '/fleets/leave/',
        data: requestData,
      );

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        RiderFleetInfo? rider;
        
        if (data['rider'] != null) {
          rider = RiderFleetInfo.fromJson(data['rider'] as Map<String, dynamic>);
        }
        
        return FleetLeaveResult(
          success: true,
          message: data['message'] as String? ?? 'Left fleet successfully',
          rider: rider,
        );
      } else {
        return FleetLeaveResult(
          success: false,
          message: data['message'] as String? ?? 'Failed to leave fleet',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fleet leave error: $e');
      }
      
      String errorMessage = 'Failed to leave fleet';
      if (e is ApiException) {
        errorMessage = e.message;
      }
      
      return FleetLeaveResult(
        success: false,
        message: errorMessage,
      );
    }
  }

  /// Get current fleet status for the authenticated rider
  /// 
  /// Returns current fleet information and rider status
  Future<FleetStatus?> getFleetStatus() async {
    try {
      final response = await _apiService.get('/fleets/status/');

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        return FleetStatus.fromJson(data);
      } else {
        if (kDebugMode) {
          print('Fleet status request failed: ${data['message']}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fleet status error: $e');
      }
      return null;
    }
  }

  /// Check if rider can join fleets (not currently in one)
  /// 
  /// This is a convenience method to check status before showing join options
  Future<bool> canJoinFleet() async {
    try {
      final status = await getFleetStatus();
      return status?.rider.isIndependentRider ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('Can join fleet check error: $e');
      }
      // Assume they can join if we can't determine status
      return true;
    }
  }

  /// Check if rider can leave their current fleet (in one and not locked)
  /// 
  /// This is a convenience method to check if leave option should be shown
  Future<bool> canLeaveFleet() async {
    try {
      final status = await getFleetStatus();
      if (status?.isInFleet == true) {
        // Check if fleet has locked riders
        return status!.fleet!.lockedRiders != true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Can leave fleet check error: $e');
      }
      return false;
    }
  }

  /// Get formatted fleet status for display
  /// 
  /// Returns user-friendly status string
  Future<String> getFleetStatusDisplay() async {
    try {
      final status = await getFleetStatus();
      return status?.statusDisplay ?? 'Status Unknown';
    } catch (e) {
      if (kDebugMode) {
        print('Fleet status display error: $e');
      }
      return 'Status Unknown';
    }
  }
}
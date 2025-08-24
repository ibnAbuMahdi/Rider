import 'dart:math';
import '../models/campaign.dart';
import 'api_service.dart';
import 'location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

class CampaignResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  const CampaignResult({
    required this.success,
    this.error,
    this.data,
  });
}

class CampaignService {
  final ApiService _apiService = ApiService();

  /// Extract user-friendly error message from API response
  /// Prioritizes detailed nested errors over generic messages
  /// 
  /// Example response formats handled:
  /// 1. {"success": false, "message": "Invalid request", "errors": {"non_field_errors": ["You must be within the Surulere Markets area to join this geofence. You are 656293m away from the boundary."]}}
  /// 2. {"errors": {"latitude": ["This field is required."]}}
  /// 3. {"message": "Some error"}
  /// 4. {"error": "Some error"}
  String? _extractErrorMessage(Map<String, dynamic>? errorData) {
    if (errorData == null) return null;
    
    // First check for nested errors structure (prioritize specific errors)
    if (errorData['errors'] != null) {
      final errors = errorData['errors'];
      
      // Check for non_field_errors (most common for validation errors)
      if (errors['non_field_errors'] != null) {
        final nonFieldErrors = errors['non_field_errors'];
        if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
          return nonFieldErrors.first.toString();
        }
      }
      
      // Check for other field-specific errors
      if (errors is Map<String, dynamic>) {
        for (final key in errors.keys) {
          final fieldErrors = errors[key];
          if (fieldErrors is List && fieldErrors.isNotEmpty) {
            return fieldErrors.first.toString();
          } else if (fieldErrors is String) {
            return fieldErrors;
          }
        }
      }
    }
    
    // Check for direct error
    if (errorData['error'] != null) {
      return errorData['error'];
    }
    
    // Fallback to generic message
    if (errorData['message'] != null) {
      return errorData['message'];
    }
    
    return null;
  }
  final LocationService _locationService = LocationService.instance;

  Future<List<Campaign>> getAvailableCampaigns() async {
    try {
      final response = await _apiService.get('/campaigns/available/');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        print('🎯 CAMPAIGN API SUCCESS: Received real data from server');
        print('🎯 Response type: ${responseData.runtimeType}');
        
        // Handle both array and object responses
        List<dynamic> campaignsJson;
        if (responseData is Map<String, dynamic>) {
          campaignsJson = responseData['results'] ?? responseData['data'] ?? [];
        } else if (responseData is List) {
          campaignsJson = responseData;
        } else {
          print('🎯 WARNING: Unexpected response format, using mock data');
          return _getMockCampaigns();
        }
        
        print('🎯 CAMPAIGNS JSON: Found ${campaignsJson.length} campaigns');
        
        // Parse campaigns with error handling
        final campaigns = <Campaign>[];
        for (int i = 0; i < campaignsJson.length; i++) {
          try {
            final campaignJson = campaignsJson[i];
            if (campaignJson is Map<String, dynamic>) {
              campaigns.add(Campaign.fromJson(campaignJson));
              //campaigns.add(parseCampaignManually(campaignJson));
		print('🎯 PARSED CAMPAIGN ${i + 1}: ${campaignJson['name'] ?? 'Unknown'}');
            } else {
              print('🎯 WARNING: Campaign $i is not a Map, skipping');
            }
          } catch (e) {
            print('🎯 ERROR parsing campaign $i: $e');
            // Continue with other campaigns instead of failing completely
          }
        }
        
        if (campaigns.isNotEmpty) {
          print('🎯 CAMPAIGN SERVICE SUCCESS: Returning ${campaigns.length} real campaigns');
          return campaigns;
        } else {
          print('🎯 WARNING: No valid campaigns parsed, using mock data');
          return _getMockCampaigns();
        }
      } else {
        print('🎯 CAMPAIGN API ERROR: Status ${response.statusCode}, using mock data');
        return _getMockCampaigns();
      }
    } catch (e) {
      print('🎯 CAMPAIGN API EXCEPTION: $e, using mock data as fallback');
      print('🎯 Exception type: ${e.runtimeType}');
      return _getMockCampaigns();
    }
  }

  List<Campaign> _getMockCampaigns() {
    print('🎭 MOCK DATA DISABLED: Returning empty list instead of placeholder campaigns');
    return [];
  }

  Future<Campaign> getCampaignDetails(String campaignId) async {
    try {
      final response = await _apiService.get('/campaigns/$campaignId/');
      
      if (response.statusCode == 200) {
        return Campaign.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Campaign not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch campaign details: $e');
    }
  }

  @Deprecated('Use joinGeofenceWithLocation instead. Campaign joining now requires geofence selection and location validation.')
  Future<CampaignResult> joinCampaign(String campaignId) async {
    return const CampaignResult(
      success: false,
      error: 'Campaign joining now requires geofence selection and location validation. Please use joinGeofenceWithLocation method.',
    );
  }

  Future<CampaignResult> leaveCampaign(String campaignId) async {
    try {
      final response = await _apiService.post('/campaigns/$campaignId/leave/', data: {});
      
      if (response.statusCode == 200) {
        return CampaignResult(
          success: true,
          data: response.data,
        );
      } else {
        final errorData = response.data;
        final errorMessage = _extractErrorMessage(errorData) ?? 'Failed to leave campaign';
        return CampaignResult(
          success: false,
          error: errorMessage,
        );
      }
    } on ApiException catch (e) {
      return CampaignResult(
        success: false,
        error: e.message,
      );
    } catch (e) {
      return CampaignResult(
        success: false,
        error: 'Failed to leave campaign: $e',
      );
    }
  }

  /// Validate GPS permissions and location services before joining geofence
  Future<CampaignResult> validateLocationForGeofenceJoin() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const CampaignResult(
            success: false,
            error: 'Location permission is required to join geofences. Please enable location access.',
          );
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return const CampaignResult(
          success: false,
          error: 'Location permission is permanently denied. Please enable it in app settings.',
        );
      }
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const CampaignResult(
          success: false,
          error: 'Location services are disabled. Please enable GPS to join geofences.',
        );
      }
      
      return const CampaignResult(success: true);
    } catch (e) {
      return CampaignResult(
        success: false,
        error: 'Failed to validate location services: $e',
      );
    }
  }
  
  /// Get current location for geofence joining
  Future<CampaignResult> getCurrentLocationForJoin() async {
    try {
      // First validate location permissions
      final validation = await validateLocationForGeofenceJoin();
      if (!validation.success) {
        return validation;
      }
      
      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );
      
      print('📍 LOCATION: Current position: ${position.latitude}, ${position.longitude}');
      print('📍 LOCATION: Accuracy: ${position.accuracy}m');
      
      // Check accuracy - warn if too low
      if (position.accuracy > 50) {
        print('⚠️ LOCATION: Low accuracy (${position.accuracy}m), continuing anyway');
      }
      
      return CampaignResult(
        success: true,
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp.toIso8601String(),
        },
      );
    } catch (e) {
      print('📍 LOCATION ERROR: Failed to get current location: $e');
      return const CampaignResult(
        success: false,
        error: 'Failed to get your current location. Please ensure GPS is enabled and try again.',
      );
    }
  }
  
  /// Join a specific geofence with automatic location detection
  /// This method automatically gets the current location and validates it
  Future<CampaignResult> joinGeofenceAtCurrentLocation(String geofenceId) async {
    try {
      print('🎯 GEOFENCE JOIN: Starting location-based join for $geofenceId');
      
      // Get current location
      final locationResult = await getCurrentLocationForJoin();
      if (!locationResult.success) {
        return locationResult;
      }
      
      final locationData = locationResult.data!;
      final latitude = locationData['latitude'] as double;
      final longitude = locationData['longitude'] as double;
      
      // Join with location validation
      return await joinGeofenceWithLocation(
        geofenceId: geofenceId,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      print('🎯 GEOFENCE JOIN ERROR: $e');
      return CampaignResult(
        success: false,
        error: 'Failed to join geofence: $e',
      );
    }
  }
  
  /// Join a specific geofence with location validation
  /// Requires the rider to be physically within the geofence area
  Future<CampaignResult> joinGeofenceWithLocation({
    required String geofenceId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('🎯 GEOFENCE API: Joining geofence $geofenceId at location ($latitude, $longitude)');
      
      final response = await _apiService.post(
        '/campaigns/geofences/join/',
        data: {
          'geofence_id': geofenceId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('🎯 GEOFENCE API SUCCESS: Joined geofence successfully');
        return CampaignResult(
          success: true,
          data: response.data,
        );
      } else {
        final errorData = response.data;
        final errorMessage = _extractErrorMessage(errorData) ?? 'Failed to join geofence';
        print('🎯 GEOFENCE API ERROR: $errorMessage');
        print('🎯 GEOFENCE API ERROR DATA: $errorData');
        return CampaignResult(
          success: false,
          error: errorMessage,
        );
      }
    } on ApiException catch (e) {
      // Handle ApiException specifically - the error message is already extracted
      print('🎯 GEOFENCE API EXCEPTION: ${e.message}');
      return CampaignResult(
        success: false,
        error: e.message,
      );
    } catch (e) {
      print('🎯 GEOFENCE API EXCEPTION: Failed to join geofence: $e');
      return CampaignResult(
        success: false,
        error: 'Failed to join geofence: $e',
      );
    }
  }
  
  @Deprecated('Use joinGeofenceWithLocation instead for location validation')
  Future<CampaignResult> joinGeofence(String campaignId, String geofenceId) async {
    return const CampaignResult(
      success: false,
      error: 'This method is deprecated. Use joinGeofenceWithLocation for location validation.',
    );
  }

  /// Leave a specific geofence
  Future<CampaignResult> leaveGeofence(String geofenceId) async {
    try {
      print('🎯 GEOFENCE API: Leaving geofence $geofenceId');
      
      final response = await _apiService.post(
        '/campaigns/geofences/leave/',
        data: {
          'geofence_id': geofenceId,
        },
      );
      
      if (response.statusCode == 200) {
        print('🎯 GEOFENCE API SUCCESS: Left geofence successfully');
        return CampaignResult(
          success: true,
          data: response.data,
        );
      } else {
        final errorData = response.data;
        final errorMessage = _extractErrorMessage(errorData) ?? 'Failed to leave geofence';
        print('🎯 GEOFENCE API ERROR: $errorMessage');
        return CampaignResult(
          success: false,
          error: errorMessage,
        );
      }
    } on ApiException catch (e) {
      print('🎯 GEOFENCE API EXCEPTION: ${e.message}');
      return CampaignResult(
        success: false,
        error: e.message,
      );
    } catch (e) {
      print('🎯 GEOFENCE API EXCEPTION: Failed to leave geofence: $e');
      return CampaignResult(
        success: false,
        error: 'Failed to leave geofence: $e',
      );
    }
  }

  /// Get details of a specific geofence
  Future<Geofence?> getGeofenceDetails(String campaignId, String geofenceId) async {
    try {
      print('🎯 GEOFENCE API: Fetching details for geofence $geofenceId');
      
      final response = await _apiService.get('/campaigns/$campaignId/geofences/$geofenceId/');
      
      if (response.statusCode == 200) {
        print('🎯 GEOFENCE API SUCCESS: Fetched geofence details');
        return Geofence.fromJson(response.data as Map<String, dynamic>);
      } else {
        print('🎯 GEOFENCE API ERROR: Failed to fetch geofence details');
        return null;
      }
    } catch (e) {
      print('🎯 GEOFENCE API EXCEPTION: Failed to fetch geofence details: $e');
      return null;
    }
  }

  /// Get all geofences for a campaign
  Future<List<Geofence>> getCampaignGeofences(String campaignId) async {
    try {
      print('🎯 GEOFENCE API: Fetching all geofences for campaign $campaignId');
      
      final response = await _apiService.get('/campaigns/$campaignId/geofences/');
      
      if (response.statusCode == 200) {
        final List<dynamic> geofencesJson = response.data['results'] ?? response.data;
        print('🎯 GEOFENCE API SUCCESS: Fetched ${geofencesJson.length} geofences');
        
        return geofencesJson
            .map((json) => Geofence.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load campaign geofences');
      }
    } catch (e) {
      print('🎯 GEOFENCE API EXCEPTION: Failed to fetch campaign geofences: $e');
      throw Exception('Failed to fetch campaign geofences: $e');
    }
  }

  Future<List<Campaign>> getMyCampaigns() async {
    try {
      final response = await _apiService.get('/campaigns/my-campaigns/');
      
      if (response.statusCode == 200) {
        final List<dynamic> campaignsJson = response.data as List;
        return campaignsJson
            .map((json) => Campaign.fromMyCampaignsJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load my campaigns');
      }
    } catch (e) {
      throw Exception('Failed to fetch my campaigns: $e');
    }
  }

  Future<Campaign?> getCurrentCampaign() async {
    try {
      print('🎯 CURRENT CAMPAIGN API: Fetching current campaign');
      final response = await _apiService.get('/campaigns/current/');
      
      if (response.statusCode == 200 && response.data != null) {
        print('🎯 CURRENT CAMPAIGN API SUCCESS: Found current campaign');
        return Campaign.fromJson(response.data as Map<String, dynamic>);
      } else {
        print('🎯 CURRENT CAMPAIGN API: No current campaign found');
        return null; // No current campaign
      }
    } catch (e) {
      print('🎯 CURRENT CAMPAIGN API ERROR: $e');
      return null; // No current campaign or error
    }
  }

  /// Enhanced method to load current campaign details by ID
  /// Used when we know the rider has a currentCampaignId but need the full details
  Future<Campaign?> getCurrentCampaignById(String campaignId) async {
    try {
      print('🎯 CAMPAIGN BY ID API: Fetching campaign $campaignId');
      final response = await _apiService.get('/campaigns/$campaignId/');
      
      if (response.statusCode == 200) {
        print('🎯 CAMPAIGN BY ID API SUCCESS: Found campaign $campaignId');
        return Campaign.fromJson(response.data as Map<String, dynamic>);
      } else {
        print('🎯 CAMPAIGN BY ID API ERROR: Campaign $campaignId not found');
        return null;
      }
    } catch (e) {
      print('🎯 CAMPAIGN BY ID API EXCEPTION: Failed to fetch campaign $campaignId: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getCampaignStats(String campaignId) async {
    try {
      final response = await _apiService.get('/campaigns/$campaignId/stats/');
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load campaign stats');
      }
    } catch (e) {
      throw Exception('Failed to fetch campaign stats: $e');
    }
  }

  /// Join a specific geofence with verification (photo required)
  /// This is the new preferred method for geofence joining with enhanced security
  Future<CampaignResult> joinGeofenceWithVerification({
    required String geofenceId,
    required String imagePath,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    try {
      print('🎯 GEOFENCE VERIFICATION JOIN: Starting verification-based join for $geofenceId');
      
      // Truncate accuracy to 8 digits maximum
      final truncatedAccuracy = _truncateAccuracy(accuracy);
      
      // Prepare form data with verification image
      final formData = FormData.fromMap({
        'geofence_id': geofenceId,
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: 'geofence_join_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'accuracy': truncatedAccuracy.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      final response = await _apiService.post(
        '/campaigns/geofences/join-with-verification/',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('🎯 GEOFENCE VERIFICATION JOIN SUCCESS: Joined with verification successfully');
        return CampaignResult(
          success: true,
          data: response.data,
        );
      } else {
        final errorData = response.data;
        final errorMessage = _extractErrorMessage(errorData) ?? 'Failed to join geofence with verification';
        print('🎯 GEOFENCE VERIFICATION JOIN ERROR: $errorMessage');
        return CampaignResult(
          success: false,
          error: errorMessage,
        );
      }
    } on ApiException catch (e) {
      print('🎯 GEOFENCE VERIFICATION JOIN API EXCEPTION: ${e.message}');
      return CampaignResult(
        success: false,
        error: e.message,
      );
    } catch (e) {
      print('🎯 GEOFENCE VERIFICATION JOIN EXCEPTION: $e');
      return CampaignResult(
        success: false,
        error: 'Failed to join geofence with verification: $e',
      );
    }
  }

  /// Check if rider is eligible to join a geofence (including cooldown check)
  Future<CampaignResult> checkGeofenceJoinEligibility({
    required String geofenceId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('🎯 GEOFENCE ELIGIBILITY: Checking join eligibility for $geofenceId');
      
      final response = await _apiService.post(
        '/campaigns/geofences/check-join-eligibility/',
        data: {
          'geofence_id': geofenceId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>?;
        final canJoin = responseData?['can_join'] ?? false;
        
        if (canJoin) {
          print('🎯 GEOFENCE ELIGIBILITY SUCCESS: Rider is eligible');
          return CampaignResult(
            success: true,
            data: response.data,
          );
        } else {
          // 200 status but can_join is false - extract error from reasons
          final reasons = responseData?['reasons'] as List<dynamic>?;
          final errorMessage = reasons?.isNotEmpty == true 
              ? reasons!.first.toString()
              : 'Not eligible to join geofence';
          print('🎯 GEOFENCE ELIGIBILITY ERROR: $errorMessage');
          return CampaignResult(
            success: false,
            error: errorMessage,
          );
        }
      } else {
        final errorData = response.data;
        final errorMessage = _extractErrorMessage(errorData) ?? 'Not eligible to join geofence';
        print('🎯 GEOFENCE ELIGIBILITY ERROR: $errorMessage');
        return CampaignResult(
          success: false,
          error: errorMessage,
        );
      }
    } on ApiException catch (e) {
      print('🎯 GEOFENCE ELIGIBILITY API EXCEPTION: ${e.message}');
      return CampaignResult(
        success: false,
        error: e.message,
      );
    } catch (e) {
      print('🎯 GEOFENCE ELIGIBILITY EXCEPTION: $e');
      return CampaignResult(
        success: false,
        error: 'Failed to check eligibility: $e',
      );
    }
  }

  Future<List<Campaign>> searchCampaigns({
    String? query,
    String? area,
    double? minRate,
    double? maxRate,
    String? campaignType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (query != null && query.isNotEmpty) {
        queryParams['search'] = query;
      }
      if (area != null && area.isNotEmpty) {
        queryParams['area'] = area;
      }
      if (minRate != null) {
        queryParams['min_rate'] = minRate.toString();
      }
      if (maxRate != null) {
        queryParams['max_rate'] = maxRate.toString();
      }
      if (campaignType != null && campaignType.isNotEmpty) {
        queryParams['campaign_type'] = campaignType;
      }

      final response = await _apiService.get(
        '/campaigns/search/',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> campaignsJson = response.data['results'] ?? response.data;
        return campaignsJson
            .map((json) => Campaign.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to search campaigns');
      }
    } catch (e) {
      throw Exception('Failed to search campaigns: $e');
    }
  }

  // Check if rider meets campaign requirements
  Future<Map<String, dynamic>> checkEligibility(String campaignId) async {
    try {
      final response = await _apiService.get('/campaigns/$campaignId/check-eligibility/');
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to check eligibility');
      }
    } catch (e) {
      throw Exception('Failed to check eligibility: $e');
    }
  }

  // Get campaign performance for rider
  Future<Map<String, dynamic>> getCampaignPerformance(String campaignId) async {
    try {
      final response = await _apiService.get('/campaigns/$campaignId/my-performance/');
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load performance data');
      }
    } catch (e) {
      throw Exception('Failed to fetch performance data: $e');
    }
  }

  /// Get tracking status - whether rider should be tracking based on active geofence assignments
  Future<Map<String, dynamic>> getTrackingStatus() async {
    try {
      print('🎯 TRACKING STATUS API: Fetching tracking status');
      
      final response = await _apiService.get('/campaigns/tracking-status/');
      
      if (response.statusCode == 200) {
        print('🎯 TRACKING STATUS API SUCCESS: ${response.data}');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load tracking status');
      }
    } catch (e) {
      print('🎯 TRACKING STATUS API EXCEPTION: $e');
      throw Exception('Failed to fetch tracking status: $e');
    }
  }

  /// Formats accuracy to 8 digits total with 2 decimal places for consistency with server validation
  static double _truncateAccuracy(double accuracy) {
    String accString = accuracy.toStringAsFixed(2); // Start with 2 decimal places
    
    if (accString.replaceAll('.', '').length > 8) {
      // If total digits exceed 8, truncate
      // Find how many digits we need to keep before the decimal point
      int decimalIndex = accString.indexOf('.');
      int integerPartLength = decimalIndex == -1 ? accString.length : decimalIndex;
      int digitsToKeep = 8;
      
      if (decimalIndex != -1) { // If there's a decimal point, it counts as one of the 8 digits
        digitsToKeep--; // For the decimal point itself
        if (integerPartLength >= digitsToKeep) {
          // Integer part is too long, truncate to fit
          accString = '${accString.substring(0, digitsToKeep)}.00';
        } else {
          // Keep integer part and limit decimal places
          int maxDecimalPlaces = digitsToKeep - integerPartLength;
          String integerPart = accString.substring(0, decimalIndex);
          String decimalPart = accString.substring(decimalIndex + 1);
          if (decimalPart.length > maxDecimalPlaces) {
            decimalPart = decimalPart.substring(0, maxDecimalPlaces);
          }
          accString = '$integerPart.$decimalPart';
        }
      } else {
        accString = accString.substring(0, min(accString.length, 8));
      }
    }
    
    return double.parse(accString);
  }
}
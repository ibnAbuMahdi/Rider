import 'dart:io';
import 'package:dio/dio.dart';
import '../models/verification_request.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

class VerificationResult {
  final bool success;
  final String? error;
  final VerificationRequest? request;
  final Map<String, dynamic>? data;

  const VerificationResult({
    required this.success,
    this.error,
    this.request,
    this.data,
  });
}

class VerificationService {
  final ApiService _apiService = ApiService();

  Future<List<VerificationRequest>> getVerificationRequests() async {
    try {
      final response = await _apiService.get('/verifications/my-requests/');
      
      if (response.statusCode == 200) {
        final List<dynamic> requestsJson = response.data['results'] ?? response.data;
        return requestsJson
            .map((json) => VerificationRequest.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load verification requests');
      }
    } catch (e) {
      throw Exception('Failed to fetch verification requests: $e');
    }
  }

  Future<VerificationResult> submitVerification({
    required String campaignId,
    required String imagePath,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    try {
      // Compress image before uploading
      final compressedImagePath = await _compressImage(imagePath);
      
      // Prepare form data
      final formData = FormData.fromMap({
        'campaign_id': campaignId,
        'image': await MultipartFile.fromFile(
          compressedImagePath,
          filename: 'verification_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'accuracy': accuracy.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': _buildImageMetadata(imagePath),
      });

      final response = await _apiService.post(
        '/verifications/submit/',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return VerificationResult(
          success: true,
          data: response.data,
          request: response.data != null 
              ? VerificationRequest.fromJson(response.data as Map<String, dynamic>)
              : null,
        );
      } else {
        final errorData = response.data;
        return VerificationResult(
          success: false,
          error: errorData['message'] ?? errorData['error'] ?? 'Verification submission failed',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        return VerificationResult(
          success: false,
          error: errorData['message'] ?? 'Invalid verification data',
        );
      } else if (e.response?.statusCode == 413) {
        return const VerificationResult(
          success: false,
          error: 'Image file too large. Please try again.',
        );
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit verification: $e');
    }
  }

  Future<VerificationRequest> getVerificationStatus(String requestId) async {
    try {
      final response = await _apiService.get('/verifications/$requestId/');
      
      if (response.statusCode == 200) {
        return VerificationRequest.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Verification request not found');
      }
    } catch (e) {
      throw Exception('Failed to get verification status: $e');
    }
  }

  Future<List<VerificationRequest>> getVerificationHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '/verifications/history/',
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> requestsJson = response.data['results'] ?? response.data;
        return requestsJson
            .map((json) => VerificationRequest.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load verification history');
      }
    } catch (e) {
      throw Exception('Failed to fetch verification history: $e');
    }
  }

  // Image compression to meet size requirements
  Future<String> _compressImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      // If image is already under the limit, return original
      if (bytes.length <= AppConstants.maxImageSizeKB * 1024) {
        return imagePath;
      }
      
      // For now, return original path
      // In a real implementation, you would use image compression library
      // like flutter_image_compress
      return imagePath;
    } catch (e) {
      // If compression fails, return original
      return imagePath;
    }
  }

  String _buildImageMetadata(String imagePath) {
    try {
      final file = File(imagePath);
      final stat = file.statSync();
      
      return '''
      {
        "file_size": ${stat.size},
        "created_at": "${DateTime.now().toIso8601String()}",
        "device_info": "android",
        "app_version": "${AppConstants.appVersion}"
      }
      ''';
    } catch (e) {
      return '{}';
    }
  }

  // Anti-gaming validation
  Future<bool> validateVerificationImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      // Check file size
      if (bytes.length > AppConstants.maxImageSizeKB * 1024) {
        return false;
      }
      
      // Check if file exists and is readable
      if (!await file.exists()) {
        return false;
      }
      
      // Additional validation can be added here
      // - Check EXIF data
      // - Validate image format
      // - Check for screenshot indicators
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Calculate verification statistics
  Future<Map<String, dynamic>> getVerificationStats() async {
    try {
      final response = await _apiService.get('/verifications/stats/');
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load verification stats');
      }
    } catch (e) {
      throw Exception('Failed to fetch verification stats: $e');
    }
  }

  // Report suspicious verification activity
  Future<void> reportSuspiciousActivity(String activityType, Map<String, dynamic> details) async {
    try {
      await _apiService.post('/verifications/report-suspicious/', data: {
        'activity_type': activityType,
        'details': details,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail for reporting - don't block user flow
    }
  }

  // Random verification methods for geofence-aware implementation

  Future<VerificationResult> createRandomVerification({
    required double latitude,
    required double longitude,
    required double accuracy,
    String? campaignId,
  }) async {
    try {
      final formData = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'accuracy': double.parse(accuracy.toStringAsFixed(2)),
        if (campaignId != null) 'campaign_id': campaignId,
      };

      final response = await _apiService.post(
        '/verifications/create-random/',
        data: formData,
      );

      if (response.statusCode == 201) {
        return VerificationResult(
          success: true,
          data: response.data,
          request: response.data['verification'] != null 
              ? VerificationRequest.fromJson(response.data['verification'])
              : null,
        );
      } else {
        return VerificationResult(
          success: false,
          error: response.data['message'] ?? 'Failed to create verification',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        String errorMessage = 'Invalid request';
        
        if (errorData != null) {
          if (errorData['reason'] == 'no_active_geofence_assignment') {
            errorMessage = 'No active geofence assignment found';
          } else if (errorData['reason'] == 'out_of_assigned_geofence') {
            final assignedGeofences = errorData['assigned_geofences'] as List?;
            if (assignedGeofences != null && assignedGeofences.isNotEmpty) {
              errorMessage = 'You must be within your assigned geofence area: ${assignedGeofences.join(', ')}';
            } else {
              errorMessage = 'You must be within your assigned geofence area';
            }
          } else {
            errorMessage = errorData['message'] ?? errorMessage;
          }
        }
        
        return VerificationResult(
          success: false,
          error: errorMessage,
        );
      } else if (e.response?.statusCode == 429) {
        final errorData = e.response?.data;
        final retryAfter = errorData?['retry_after_seconds'] ?? 60;
        return VerificationResult(
          success: false,
          error: 'Please wait $retryAfter seconds before requesting another verification',
        );
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create random verification: $e');
    }
  }

  Future<VerificationRequest?> checkPendingVerifications() async {
    try {
      final response = await _apiService.get('/verifications/pending/');
      
      if (response.statusCode == 200 && response.data['has_pending'] == true) {
        return VerificationRequest.fromJson(response.data['verification']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to check pending verifications: $e');
    }
  }

  Future<VerificationResult> submitRandomVerification({
    required String verificationId,
    required String imagePath,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    try {
      final compressedImagePath = await _compressImage(imagePath);
      
      final formData = FormData.fromMap({
        'verification_id': verificationId,
        'image': await MultipartFile.fromFile(
          compressedImagePath,
          filename: 'verification_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'accuracy': accuracy.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      final response = await _apiService.post(
        '/verifications/submit/',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.statusCode == 200) {
        return VerificationResult(
          success: true,
          data: response.data,
        );
      } else {
        return VerificationResult(
          success: false,
          error: response.data['message'] ?? 'Verification failed',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        return VerificationResult(
          success: false,
          error: errorData['message'] ?? 'Verification submission failed',
        );
      } else if (e.response?.statusCode == 413) {
        return const VerificationResult(
          success: false,
          error: 'Image file too large. Please try again.',
        );
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit verification: $e');
    }
  }
}
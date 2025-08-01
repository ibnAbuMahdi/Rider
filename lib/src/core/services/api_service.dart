import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../storage/hive_service.dart';
import '../services/auth_service.dart';

class ApiService {
  late final Dio _dio;
  static ApiService? _instance;
  bool _isRefreshing = false;
  final List<RequestOptions> _failedQueue = [];

  ApiService._internal() {
    _dio = Dio();
    _setupInterceptors();
  }

  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  void _setupInterceptors() {
    _dio.options = BaseOptions(
      baseUrl: '${AppConstants.baseUrl}/api/${AppConstants.apiVersion}',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'StikaRider/${AppConstants.appVersion} (${Platform.operatingSystem})',
      },
    );

    // Request interceptor for auth token and logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Enhanced logging for API requests
          if (kDebugMode) {
            print('🔵 API REQUEST START: ${options.method} ${options.path}');
            print('🔵 Timestamp: ${DateTime.now().toIso8601String()}');
            print('🔵 Base URL: ${options.baseUrl}');
            print('🔵 Query Parameters: ${options.queryParameters}');
            print('🔵 Headers: ${options.headers}');
            if (options.data != null) {
              print('🔵 Request Data: ${options.data}');
            }
          }
          
          // Get auth token synchronously from HiveService
          // Skip adding Authorization header for refresh token requests
          if (options.path != '/auth/refresh/') {
            final token = HiveService.getAuthToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              if (kDebugMode) {
                print('🔵 Auth token added (length: ${token.length})');
              }
            } else {
              if (kDebugMode) {
                print('🔵 No auth token available');
              }
            }
          } else {
            if (kDebugMode) {
              print('🔵 Skipping auth header for refresh token request');
            }
          }
          
          // Add request ID for tracking
          options.headers['X-Request-ID'] = _generateRequestId();
          
          if (kDebugMode) {
            print('🚀 REQUEST: ${options.method} ${options.path}');
            print('📝 Headers: ${options.headers}');
            if (options.data != null) {
              print('📝 Data: ${options.data}');
            }
          }
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('🟢 API RESPONSE SUCCESS: ${response.requestOptions.method} ${response.requestOptions.path}');
            print('🟢 Status Code: ${response.statusCode}');
            print('🟢 Response Headers: ${response.headers}');
            print('🟢 Response Data: ${response.data}');
            print('🟢 Response Type: ${response.data.runtimeType}');
            if (response.requestOptions.headers['X-Request-ID'] != null) {
              print('🟢 Request ID: ${response.requestOptions.headers['X-Request-ID']}');
            }
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            print('🔴 API REQUEST ERROR: ${error.requestOptions.method} ${error.requestOptions.path}');
            print('🔴 Error Type: ${error.type}');
            print('🔴 Status Code: ${error.response?.statusCode}');
            print('🔴 Error Message: ${error.message}');
            print('🔴 Response Data: ${error.response?.data}');
            print('🔴 Response Headers: ${error.response?.headers}');
            if (error.requestOptions.headers['X-Request-ID'] != null) {
              print('🔴 Request ID: ${error.requestOptions.headers['X-Request-ID']}');
            }
            print('🔴 Stack Trace: ${error.stackTrace}');
          }
          
          // Handle 401 - token expired, try refresh
          if (error.response?.statusCode == 401) {
            final refreshResult = await _handleTokenExpiry(error.requestOptions);
            if (refreshResult != null) {
              handler.resolve(refreshResult);
              return;
            }
          }
          
          handler.next(error);
        },
      ),
    );

    // Retry interceptor for failed requests
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldRetry(error)) {
            try {
              final response = await _retry(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              if (kDebugMode) {
                print('🔄 RETRY FAILED: $e');
              }
            }
          }
          handler.next(error);
        },
      ),
    );

    // Logging interceptor (only in debug mode)
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        error: true,
      ));
    }
  }

  bool _shouldRetry(DioException error) {
    // Don't retry once any response has been received (regardless of status code)
    if (error.response?.statusCode != null) {
      return false;
    }

    // Only retry for network/timeout errors where no response was received
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.connectionError;
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    // Wait before retry
    await Future.delayed(const Duration(seconds: 2));
    
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
      sendTimeout: requestOptions.sendTimeout,
      receiveTimeout: requestOptions.receiveTimeout,
    );

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<Response?> _handleTokenExpiry(RequestOptions failedRequest) async {
    if (_isRefreshing) {
      // If already refreshing, queue this request
      _failedQueue.add(failedRequest);
      return null;
    }

    _isRefreshing = true;

    try {
      // Try to refresh token
      final authService = AuthService();
      final refreshResult = await authService.refreshToken();

      if (refreshResult.success && refreshResult.token != null) {
        // Token refreshed successfully, retry all queued requests
        await _retryQueuedRequests(refreshResult.token!);
        
        // Retry the original request
        failedRequest.headers['Authorization'] = 'Bearer ${refreshResult.token}';
        final response = await _dio.request(
          failedRequest.path,
          data: failedRequest.data,
          queryParameters: failedRequest.queryParameters,
          options: Options(
            method: failedRequest.method,
            headers: failedRequest.headers,
          ),
        );
        
        return response;
      } else {
        // Refresh failed, clear tokens and redirect to login
        await _clearAuthData();
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Token refresh failed: $e');
      }
      await _clearAuthData();
      return null;
    } finally {
      _isRefreshing = false;
      _failedQueue.clear();
    }
  }

  Future<void> _retryQueuedRequests(String newToken) async {
    for (final request in _failedQueue) {
      try {
        request.headers['Authorization'] = 'Bearer $newToken';
        await _dio.request(
          request.path,
          data: request.data,
          queryParameters: request.queryParameters,
          options: Options(
            method: request.method,
            headers: request.headers,
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Failed to retry queued request: $e');
        }
      }
    }
  }

  Future<void> _clearAuthData() async {
    // Use the comprehensive auth data clearing method
    await HiveService.clearAuthData();
    
    // Notify about authentication failure
    // You might want to use a state management solution here
    // or emit an event that the UI can listen to
    if (kDebugMode) {
      print('🧹 Auth data cleared due to token expiry');
    }
  }

  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // HTTP Methods with better error handling
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Enhanced file upload with progress and validation
  Future<Response> uploadFile(
    String path,
    String filePath, {
    Map<String, dynamic>? data,
    String fieldName = 'file',
    ProgressCallback? onProgress,
    List<String>? allowedExtensions,
    int? maxFileSizeBytes,
  }) async {
    try {
      // Validate file if constraints provided
      if (allowedExtensions != null || maxFileSizeBytes != null) {
        await _validateFile(filePath, allowedExtensions, maxFileSizeBytes);
      }

      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
        ...?data,
      });

      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          sendTimeout: const Duration(minutes: 5), // Longer timeout for uploads
        ),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> _validateFile(
    String filePath,
    List<String>? allowedExtensions,
    int? maxFileSizeBytes,
  ) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }

    // Check file size
    if (maxFileSizeBytes != null) {
      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) {
        throw Exception('File too large. Maximum size: ${maxFileSizeBytes ~/ (1024 * 1024)}MB');
      }
    }

    // Check file extension
    if (allowedExtensions != null) {
      final extension = filePath.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        throw Exception('File type not allowed. Allowed: ${allowedExtensions.join(', ')}');
      }
    }
  }

  /// Extract user-friendly error message from API response
  /// Prioritizes detailed nested errors over generic messages
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
    
    // Check for detail field (common in DRF)
    if (errorData['detail'] != null) {
      return errorData['detail'];
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

  // Enhanced error handling with more specific error types
  ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: AppConstants.networkErrorMessage,
          type: ApiErrorType.timeout,
          statusCode: null,
        );
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String message = 'Server error occurred';
        
        if (responseData is Map<String, dynamic>) {
          message = _extractErrorMessage(responseData) ?? message;
        }
        
        ApiErrorType errorType;
        if (statusCode == 401) {
          message = 'Authentication failed. Please login again.';
          errorType = ApiErrorType.unauthorized;
        } else if (statusCode == 403) {
          message = 'Access denied.';
          errorType = ApiErrorType.forbidden;
        } else if (statusCode == 404) {
          message = 'Resource not found.';
          errorType = ApiErrorType.notFound;
        } else if (statusCode == 422) {
          message = 'Invalid data provided.';
          errorType = ApiErrorType.validation;
        } else if (statusCode != null && statusCode >= 500) {
          message = AppConstants.serverErrorMessage;
          errorType = ApiErrorType.server;
        } else {
          errorType = ApiErrorType.client;
        }
        
        return ApiException(
          message: message,
          type: errorType,
          statusCode: statusCode,
          response: responseData,
        );
      
      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request was cancelled',
          type: ApiErrorType.cancelled,
          statusCode: null,
        );
      
      case DioExceptionType.connectionError:
        return const ApiException(
          message: AppConstants.networkErrorMessage,
          type: ApiErrorType.network,
          statusCode: null,
        );
      
      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Security certificate error',
          type: ApiErrorType.security,
          statusCode: null,
        );
      
      case DioExceptionType.unknown:
      default:
        return const ApiException(
          message: 'An unexpected error occurred',
          type: ApiErrorType.unknown,
          statusCode: null,
        );
    }
  }

  // Helper methods for common API patterns
  Future<List<T>> getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await get(path, queryParameters: queryParameters);
    final dynamic responseData = response.data;
    
    if (responseData is Map<String, dynamic>) {
      final List<dynamic> list = responseData['results'] ?? 
                                responseData['data'] ?? 
                                responseData['items'] ?? 
                                [];
      return list.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } else if (responseData is List) {
      return responseData.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    }
    
    return [];
  }

  Future<T?> getItem<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await get(path, queryParameters: queryParameters);
      final responseData = response.data;
      
      if (responseData is Map<String, dynamic>) {
        return fromJson(responseData);
      }
      return null;
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        return null; // Item not found
      }
      rethrow;
    }
  }

  // Enhanced pagination support
  Future<PaginatedResponse<T>> getPaginated<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await get(path, queryParameters: queryParameters);
    final data = response.data as Map<String, dynamic>;
    
    return PaginatedResponse<T>(
      results: (data['results'] as List<dynamic>)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList(),
      count: data['count'] as int? ?? 0,
      next: data['next'] as String?,
      previous: data['previous'] as String?,
      pageSize: data['page_size'] as int?,
      currentPage: data['current_page'] as int?,
      totalPages: data['total_pages'] as int?,
    );
  }

  // Safe notification polling methods
  Future<Map<String, dynamic>> checkVerificationRequest() async {
    try {
      final response = await get('/riders/verification-check/');
      return response.data as Map<String, dynamic>? ?? {'hasRequest': false};
    } catch (e) {
      if (kDebugMode) {
        print('Verification check failed: $e');
      }
      return {'hasRequest': false};
    }
  }

  Future<Map<String, dynamic>> checkPaymentStatus() async {
    try {
      final response = await get('/riders/payment-check/');
      return response.data as Map<String, dynamic>? ?? {'hasUpdate': false};
    } catch (e) {
      if (kDebugMode) {
        print('Payment check failed: $e');
      }
      return {'hasUpdate': false};
    }
  }

  Future<Map<String, dynamic>> checkCampaignStatus() async {
    try {
      final response = await get('/riders/campaign-check/');
      return response.data as Map<String, dynamic>? ?? {'hasUpdate': false};
    } catch (e) {
      if (kDebugMode) {
        print('Campaign check failed: $e');
      }
      return {'hasUpdate': false};
    }
  }

  // Health check method
  Future<bool> isApiHealthy() async {
    try {
      final response = await get('/health/', queryParameters: {'timestamp': DateTime.now().millisecondsSinceEpoch});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Sync methods for offline storage
  Future<Map<String, dynamic>> submitVerification(verification) async {
    try {
      final response = await post('/riders/verifications/', data: verification.toJson());
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Submit verification failed: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> syncLocationBatch(List<dynamic> locations, String batchId) async {
    try {
      final data = {
        'batch_id': batchId,
        'batch_created_at': DateTime.now().toIso8601String(),
        'locations': locations.map((loc) => loc.toJson()).toList(),
      };
      final response = await post('/tracking/sync/', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Sync location batch failed: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> syncEarning(earning) async {
    try {
      final response = await post('/riders/earnings/', data: earning.toJson());
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Sync earning failed: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> syncSMSLog(smsLog) async {
    try {
      final response = await post('/riders/sms-logs/', data: smsLog.toJson());
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Sync SMS log failed: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  // New tracking endpoints
  Future<Map<String, dynamic>> getTrackingStats() async {
    try {
      final response = await get('/tracking/stats/');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Get tracking stats failed: $e');
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
      final data = {
        'mobile_id': mobileId,
        'geofence_id': geofenceId,
        'earnings_type': earningsType,
        'distance_km': distanceKm,
        'duration_hours': durationHours,
        'verifications_completed': verificationsCompleted,
        'earned_at': earnedAt.toIso8601String(),
        'metadata': metadata ?? {},
      };
      final response = await post('/tracking/earnings/calculate/', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Calculate earnings failed: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getLocationRecords({Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await get('/tracking/locations/', queryParameters: queryParameters);
      final data = response.data;
      if (data is Map<String, dynamic> && data['results'] is List) {
        return List<Map<String, dynamic>>.from(data['results']);
      } else if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Get location records failed: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getGeofenceEvents({Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await get('/tracking/geofence-events/', queryParameters: queryParameters);
      final data = response.data;
      if (data is Map<String, dynamic> && data['results'] is List) {
        return List<Map<String, dynamic>>.from(data['results']);
      } else if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Get geofence events failed: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRiderSessions({Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await get('/tracking/sessions/', queryParameters: queryParameters);
      final data = response.data;
      if (data is Map<String, dynamic> && data['results'] is List) {
        return List<Map<String, dynamic>>.from(data['results']);
      } else if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Get rider sessions failed: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEarningsCalculations({Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await get('/tracking/earnings/', queryParameters: queryParameters);
      final data = response.data;
      if (data is Map<String, dynamic> && data['results'] is List) {
        return List<Map<String, dynamic>>.from(data['results']);
      } else if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Get earnings calculations failed: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDailyTrackingSummaries({Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await get('/tracking/summaries/', queryParameters: queryParameters);
      final data = response.data;
      if (data is Map<String, dynamic> && data['results'] is List) {
        return List<Map<String, dynamic>>.from(data['results']);
      } else if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Get daily tracking summaries failed: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSyncBatches({Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await get('/tracking/sync-batches/', queryParameters: queryParameters);
      final data = response.data;
      if (data is Map<String, dynamic> && data['results'] is List) {
        return List<Map<String, dynamic>>.from(data['results']);
      } else if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Get sync batches failed: $e');
      }
      return [];
    }
  }

  // Cleanup method
  void dispose() {
    _dio.close();
  }
}

// Custom exception class for better error handling
class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  final int? statusCode;
  final dynamic response;

  const ApiException({
    required this.message,
    required this.type,
    this.statusCode,
    this.response,
  });

  @override
  String toString() {
    return 'ApiException: $message (${type.name}${statusCode != null ? ', status: $statusCode' : ''})';
  }
}

enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  client,
  cancelled,
  security,
  unknown,
}

// Request ID generation for API tracking
String _generateRequestId() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = (timestamp % 10000).toString().padLeft(4, '0');
  return 'req_$timestamp$random';
}

// Enhanced pagination response
class PaginatedResponse<T> {
  final List<T> results;
  final int count;
  final String? next;
  final String? previous;
  final int? pageSize;
  final int? currentPage;
  final int? totalPages;

  const PaginatedResponse({
    required this.results,
    required this.count,
    this.next,
    this.previous,
    this.pageSize,
    this.currentPage,
    this.totalPages,
  });

  bool get hasNext => next != null && next!.isNotEmpty;
  bool get hasPrevious => previous != null && previous!.isNotEmpty;
  bool get isEmpty => results.isEmpty;
  int get resultCount => results.length;
  
  double get progress {
    if (totalPages == null || currentPage == null || totalPages == 0) {
      return 1.0;
    }
    return currentPage! / totalPages!;
  }
}
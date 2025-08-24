import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/rider.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import '../storage/hive_service.dart'; // Updated import

class AuthResult {
  final bool success;
  final String? token;
  final String? refreshToken;
  final Rider? rider;
  final String? error;
  final String? errorCode;
  final bool isNewUser;
  final String? sessionType; // 'signup' or 'login'

  const AuthResult({
    required this.success,
    this.token,
    this.refreshToken,
    this.rider,
    this.error,
    this.errorCode,
    this.isNewUser = false,
    this.sessionType,
  });
}

class OTPResult {
  final bool success;
  final String? error;
  final String? errorCode;
  final int? expiresInMinutes;

  const OTPResult({
    required this.success,
    this.error,
    this.errorCode,
    this.expiresInMinutes,
  });
}

class AuthService {
  final ApiService _apiService = ApiService();
  
  // OTP cache for local validation (backup)
  final Map<String, Map<String, dynamic>> _otpCache = {};
  
  /// Send OTP using Kudisms SMS service via backend
  Future<OTPResult> sendOTP(String phoneNumber) async {
    try {
      // Format phone number for Nigerian context
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      
      // Validate phone number format
      if (!isValidNigerianPhone(formattedPhone)) {
        return const OTPResult(
          success: false,
          error: 'Please enter a valid Nigerian phone number (e.g., 08031234567)',
          errorCode: 'INVALID_PHONE',
        );
      }

      if (kDebugMode) {
        print('📱 Sending OTP to: $formattedPhone');
      }

      // Send OTP via backend (which uses Kudisms)
      final response = await _apiService.post(AppConstants.sendOtpEndpoint, data: {
        'phone_number': formattedPhone,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (kDebugMode) {
          print('✅ OTP sent successfully: $data');
        }

        // Cache phone for validation (don't cache actual OTP for security)
        _otpCache[formattedPhone] = {
          'sent_at': DateTime.now().toIso8601String(),
          'attempts': 0,
        };

        return OTPResult(
          success: true,
          expiresInMinutes: data['expires_in_minutes'] ?? 5,
        );
      } else {
        return const OTPResult(
          success: false,
          error: 'Failed to send verification code',
          errorCode: 'SEND_FAILED',
        );
      }
    } on ApiException catch (e) {
      return _handleOTPError(e);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Send OTP error: $e');
      }
      return OTPResult(
        success: false,
        error: 'Failed to send verification code: $e',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Resend OTP with rate limiting
  Future<OTPResult> resendOTP(String phoneNumber) async {
    try {
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      
      // Check if we can resend (rate limiting)
      if (HiveService.isOTPRateLimited(formattedPhone)) {
        return const OTPResult(
          success: false,
          error: 'Please wait 60 seconds before requesting again',
          errorCode: 'RATE_LIMITED',
        );
      }

      // Store timestamp for rate limiting
      await HiveService.setOTPRateLimit(formattedPhone);

      return await sendOTP(phoneNumber);
    } catch (e) {
      return OTPResult(
        success: false,
        error: 'Failed to resend code: $e',
        errorCode: 'RESEND_FAILED',
      );
    }
  }

  /// Verify OTP and authenticate user
  Future<AuthResult> verifyOTP(String phoneNumber, String otp) async {
    try {
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      
      // Validate OTP format (4 digits for Kudisms)
      if (otp.length != AppConstants.otpLength || !RegExp(r'^\d{4}$').hasMatch(otp)) {
        return const AuthResult(
          success: false,
          error: 'Please enter a valid ${AppConstants.otpLength}-digit code',
          errorCode: 'INVALID_OTP_FORMAT',
        );
      }

      if (kDebugMode) {
        print('🔐 Verifying OTP: $otp for $formattedPhone');
      }

      // Check local cache for attempt limiting
      final cachedOTP = _otpCache[formattedPhone];
      if (cachedOTP != null) {
        final attempts = cachedOTP['attempts'] as int;
        
        // Check attempt limit (Kudisms allows 2 attempts)
        if (attempts >= AppConstants.maxOtpAttempts) {
          _otpCache.remove(formattedPhone);
          return const AuthResult(
            success: false,
            error: 'Too many failed attempts. Request a new code.',
            errorCode: 'TOO_MANY_ATTEMPTS',
          );
        }
        
        // Update attempts
        _otpCache[formattedPhone]!['attempts'] = attempts + 1;
      }

      // Verify with backend
      final response = await _apiService.post(AppConstants.verifyOtpEndpoint, data: {
        'phone_number': formattedPhone,
        'otp': otp,
        'device_info': await _getDeviceInfo(),
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (kDebugMode) {
          print('✅ OTP verified successfully: $data');
        }
        
        // Clear OTP cache on success
        _otpCache.remove(formattedPhone);
        
        // Store auth tokens - using correct response keys
        await HiveService.saveAuthToken(data['access'] ?? data['access_token']);
        await HiveService.saveRefreshToken(data['refresh'] ?? data['refresh_token']);
        
        // Store rider data
        if (data['rider'] != null) {
          await HiveService.saveRiderData(jsonEncode(data['rider']));
        }
        
        return AuthResult(
          success: true,
          token: data['access'] ?? data['access_token'],
          refreshToken: data['refresh'] ?? data['refresh_token'],
          rider: data['rider'] != null ? Rider.fromJson(data['rider']) : null,
          isNewUser: data['is_new_user'] ?? false,
        );
      } else {
        return const AuthResult(
          success: false,
          error: 'Invalid verification code',
          errorCode: 'INVALID_OTP',
        );
      }
    } on ApiException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Verify OTP error: $e');
      }
      return AuthResult(
        success: false,
        error: 'Verification failed: $e',
        errorCode: 'VERIFICATION_FAILED',
      );
    }
  }

  /// Refresh authentication token
  Future<AuthResult> refreshToken() async {
    try {
      final refreshToken = HiveService.getRefreshToken();
      
      if (refreshToken == null) {
        return const AuthResult(
          success: false,
          error: 'No refresh token available',
          errorCode: 'NO_REFRESH_TOKEN',
        );
      }

      if (kDebugMode) {
        print('🔄 Refreshing token...');
      }

      final response = await _apiService.post(AppConstants.refreshTokenEndpoint, data: {
        'refresh': refreshToken,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Update stored tokens - using correct response keys
        await HiveService.saveAuthToken(data['access']);
        if (data['refresh'] != null) {
          await HiveService.saveRefreshToken(data['refresh']);
        }
        
        // Update rider data if provided
        if (data['rider'] != null) {
          await HiveService.saveRiderData(jsonEncode(data['rider']));
        }
        
        if (kDebugMode) {
          print('✅ Token refreshed successfully');
          print('🔄 New access token: ${data['access']?.substring(0, 20)}...');
          print('🔄 New refresh token: ${data['refresh']?.substring(0, 20)}...');
        }
        
        return AuthResult(
          success: true,
          token: data['access'],
          refreshToken: data['refresh'],
          rider: data['rider'] != null ? Rider.fromJson(data['rider']) : null,
        );
      } else {
        return const AuthResult(
          success: false,
          error: 'Failed to refresh session',
          errorCode: 'REFRESH_FAILED',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Token refresh error: $e');
      }
      return AuthResult(
        success: false,
        error: 'Token refresh failed: $e',
        errorCode: 'REFRESH_ERROR',
      );
    }
  }

  /// Logout user and clear stored data
  Future<void> logout() async {
    try {
      // Get refresh token for logout
      final refreshToken = HiveService.getRefreshToken();
      
      // Notify backend about logout
      if (refreshToken != null) {
        await _apiService.post(AppConstants.logoutEndpoint, data: {
          'refresh': refreshToken,
        });
      }
      
      if (kDebugMode) {
        print('✅ Logout API call successful');
      }
    } catch (e) {
      // Ignore logout errors - clear local data anyway
      if (kDebugMode) {
        print('⚠️ Logout API call failed: $e');
      }
    } finally {
      // Clear all stored auth data
      await HiveService.clearAuthData();
      
      // Clear OTP cache
      _otpCache.clear();
      
      if (kDebugMode) {
        print('🧹 Auth data cleared locally');
      }
    }
  }

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    final token = HiveService.getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Get stored authentication token
  Future<String?> getAuthToken() async {
    return HiveService.getAuthToken();
  }

  /// Get stored rider data
  Future<Rider?> getStoredRider() async {
    final riderJson = HiveService.getRiderData();
    if (riderJson != null) {
      try {
        return Rider.fromJson(jsonDecode(riderJson));
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error parsing stored rider data: $e');
        }
      }
    }
    return null;
  }

  /// Activate rider account with plate number
  Future<AuthResult> activateRider(String plateNumber) async {
    try {
      // Validate plate number format (8 characters: ABC123DD)
      if (!_isValidPlateNumber(plateNumber)) {
        return const AuthResult(
          success: false,
          error: 'Invalid plate number format. Use format ABC123DD',
          errorCode: 'INVALID_PLATE_FORMAT',
        );
      }

      if (kDebugMode) {
        print('🚗 Activating rider with plate: $plateNumber');
      }

      // Send activation request to backend
      final response = await _apiService.patch('/riders/activate/', data: {
        'plate_number': plateNumber.toUpperCase(),
        'device_info': await _getDeviceInfo(),
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (kDebugMode) {
          print('✅ Rider activated successfully: $data');
        }
        
        // Update stored rider data
        if (data['rider'] != null) {
          await HiveService.saveRiderData(jsonEncode(data['rider']));
        }
        
        return AuthResult(
          success: true,
          rider: data['rider'] != null ? Rider.fromJson(data['rider']) : null,
        );
      } else {
        return const AuthResult(
          success: false,
          error: 'Failed to activate account',
          errorCode: 'ACTIVATION_FAILED',
        );
      }
    } on ApiException catch (e) {
      return _handleActivationError(e);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Rider activation error: $e');
      }
      return AuthResult(
        success: false,
        error: 'Activation failed: $e',
        errorCode: 'ACTIVATION_ERROR',
      );
    }
  }

  /// Validate plate number format (Nigerian format: ABC123DD)
  bool _isValidPlateNumber(String plateNumber) {
    if (plateNumber.length != 8) return false;
    
    // Nigerian plate format: 3 letters + 3 numbers + 2 letters
    final regex = RegExp(r'^[A-Z]{3}[0-9]{3}[A-Z]{2}$');
    return regex.hasMatch(plateNumber.toUpperCase());
  }

  /// Format phone number for Nigerian context
  String _formatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Handle Nigerian phone number formatting
    if (cleaned.startsWith('234')) {
      // Already has country code
      return '+$cleaned';
    } else if (cleaned.startsWith('0')) {
      // Local format (e.g., 08031234567)
      return '+234${cleaned.substring(1)}';
    } else if (cleaned.length == 10) {
      // Without leading zero (e.g., 8031234567)
      return '+234$cleaned';
    }
    
    // Assume it needs +234 prefix
    return '+234$cleaned';
  }

  /// Validate Nigerian phone number format
  bool isValidNigerianPhone(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check various formats
    if (cleaned.startsWith('+234') && cleaned.length == 14) {
      final number = cleaned.substring(4);
      return _isValidMobilePrefix(number);
    } else if (cleaned.startsWith('234') && cleaned.length == 13) {
      final number = cleaned.substring(3);
      return _isValidMobilePrefix(number);
    } else if (cleaned.startsWith('0') && cleaned.length == 11) {
      final number = cleaned.substring(1);
      return _isValidMobilePrefix(number);
    } else if (cleaned.length == 10) {
      return _isValidMobilePrefix(cleaned);
    }
    
    return false;
  }

  /// Check if mobile number has valid Nigerian prefix
  bool _isValidMobilePrefix(String number) {
    if (number.length != 10) return false;
    
    final prefix = number.substring(0, 3);
    return AppConstants.validNigerianPrefixes.contains(prefix);
  }

  /// Get device information for security
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // Get or create device ID
    String? deviceId = HiveService.getDeviceId();
    if (deviceId == null) {
      // Generate unique device ID
      deviceId = _generateDeviceId();
      await HiveService.saveDeviceId(deviceId);
    }

    // Get platform info
    String platform = 'android'; // Default to android
    String deviceName = 'Unknown Device';
    String osVersion = 'Unknown';
    
    try {
      // You can enhance this with device_info_plus package
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        platform = 'ios';
        deviceName = 'iPhone/iPad';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        platform = 'android';
        deviceName = 'Android Device';
      }
    } catch (e) {
      // Fallback to defaults
    }

    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
      'os_version': osVersion,
      'app_version': AppConstants.appVersion,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Generate a unique device ID
  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    final hash = sha256.convert('${timestamp}_${random}_stika_rider'.codeUnits);
    return 'stika_${hash.toString().substring(0, 16)}';
  }

  /// Handle OTP-related errors
  OTPResult _handleOTPError(ApiException e) {
    if (e.statusCode == 400) {
      final errorData = e.response;
      final errorCode = errorData is Map ? errorData['code'] : null;
      
      switch (errorCode) {
        case 'INVALID_PHONE':
          return OTPResult(
            success: false,
            error: 'Please enter a valid Nigerian phone number',
            errorCode: errorCode,
          );
        case 'RATE_LIMITED':
          return OTPResult(
            success: false,
            error: 'Too many requests. Please wait before trying again.',
            errorCode: errorCode,
          );
        case 'SMS_FAILED':
          return OTPResult(
            success: false,
            error: 'Failed to send SMS. Please try again.',
            errorCode: errorCode,
          );
        default:
          final message = errorData is Map ? errorData['message'] : null;
          return OTPResult(
            success: false,
            error: message ?? 'Failed to send verification code',
            errorCode: errorCode,
          );
      }
    } else if (e.statusCode == 500) {
      return const OTPResult(
        success: false,
        error: 'Server error. Please try again later.',
        errorCode: 'SERVER_ERROR',
      );
    }
    
    return const OTPResult(
      success: false,
      error: 'Network error. Please check your connection.',
      errorCode: 'NETWORK_ERROR',
    );
  }

  /// Handle authentication-related errors
  AuthResult _handleAuthError(ApiException e) {
    if (e.statusCode == 400) {
      final errorData = e.response;
      final errorCode = errorData is Map ? errorData['code'] : null;
      
      switch (errorCode) {
        case 'INVALID_OTP':
          final attemptsRemaining = errorData is Map ? errorData['attempts_remaining'] : null;
          String message = 'Invalid verification code. Please try again.';
          if (attemptsRemaining != null) {
            message = 'Invalid verification code. $attemptsRemaining attempts remaining.';
          }
          return AuthResult(
            success: false,
            error: message,
            errorCode: errorCode,
          );
        case 'OTP_EXPIRED':
          return AuthResult(
            success: false,
            error: 'Verification code has expired. Request a new one.',
            errorCode: errorCode,
          );
        case 'TOO_MANY_ATTEMPTS':
          return AuthResult(
            success: false,
            error: 'Too many failed attempts. Request a new code.',
            errorCode: errorCode,
          );
        default:
          final message = errorData is Map ? errorData['message'] : null;
          return AuthResult(
            success: false,
            error: message ?? 'Authentication failed',
            errorCode: errorCode,
          );
      }
    }
    
    return const AuthResult(
      success: false,
      error: 'Network error. Please try again.',
      errorCode: 'NETWORK_ERROR',
    );
  }

  /// Handle activation-related errors
  AuthResult _handleActivationError(ApiException e) {
    if (e.statusCode == 400) {
      final errorData = e.response;
      final errorCode = errorData is Map ? errorData['code'] : null;
      
      switch (errorCode) {
        case 'INVALID_PLATE':
          return AuthResult(
            success: false,
            error: 'Invalid plate number format. Please use format ABC123DD',
            errorCode: errorCode,
          );
        case 'PLATE_ALREADY_EXISTS':
          return AuthResult(
            success: false,
            error: 'This plate number is already registered by another rider',
            errorCode: errorCode,
          );
        case 'RIDER_ALREADY_ACTIVE':
          return AuthResult(
            success: false,
            error: 'Your account is already activated',
            errorCode: errorCode,
          );
        case 'RIDER_NOT_FOUND':
          return AuthResult(
            success: false,
            error: 'Rider account not found. Please contact support.',
            errorCode: errorCode,
          );
        default:
          final message = errorData is Map ? errorData['message'] : null;
          return AuthResult(
            success: false,
            error: message ?? 'Activation failed',
            errorCode: errorCode,
          );
      }
    } else if (e.statusCode == 403) {
      return const AuthResult(
        success: false,
        error: 'You are not authorized to activate this account',
        errorCode: 'FORBIDDEN',
      );
    } else if (e.statusCode == 500) {
      return const AuthResult(
        success: false,
        error: 'Server error. Please try again later.',
        errorCode: 'SERVER_ERROR',
      );
    }
    
    return const AuthResult(
      success: false,
      error: 'Network error. Please check your connection.',
      errorCode: 'NETWORK_ERROR',
    );
  }

  // === NEW FLEXIBLE AUTH METHODS ===

  /// Combined signup with phone + optional plate number
  Future<AuthResult> signup({
    required String phone,
    String? plate,
  }) async {
    try {
      final formattedPhone = _formatPhoneNumber(phone);
      
      // Validate phone number
      if (!isValidNigerianPhone(formattedPhone)) {
        return const AuthResult(
          success: false,
          error: 'Please enter a valid Nigerian phone number',
          errorCode: 'INVALID_PHONE',
        );
      }

      // Validate plate number if provided
      if (plate != null && plate.isNotEmpty && !_isValidPlateNumber(plate)) {
        return const AuthResult(
          success: false,
          error: 'Invalid plate number format. Use format ABC123DD',
          errorCode: 'INVALID_PLATE_FORMAT',
        );
      }

      if (kDebugMode) {
        print('🔧 Starting signup for phone: $formattedPhone, plate: $plate');
      }

      final response = await _apiService.post(AppConstants.signupEndpoint, data: {
        'phone_number': formattedPhone,
        if (plate != null && plate.isNotEmpty) 'plate_number': plate.toUpperCase(),
      });

      if (response.statusCode == 201) {
        final data = response.data;
        
        if (kDebugMode) {
          print('✅ Signup initiated successfully: $data');
        }
        
        // Store signup context for OTP verification
        await HiveService.saveSignupContext({
          'phone_number': formattedPhone,
          'plate_number': plate,
          'session_type': 'signup',
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        return const AuthResult(
          success: true,
          isNewUser: true,
          sessionType: 'signup',
        );
      } else {
        final data = response.data;
        return AuthResult(
          success: false,
          error: data['message'] ?? 'Signup failed',
          errorCode: data['code'] ?? 'SIGNUP_FAILED',
        );
      }
    } on ApiException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Signup error: $e');
      }
      return AuthResult(
        success: false,
        error: 'Signup failed: $e',
        errorCode: 'SIGNUP_ERROR',
      );
    }
  }

  /// Login with phone number or plate number
  Future<OTPResult> sendLoginOTP(String identifier) async {
    try {
      if (kDebugMode) {
        print('🔐 Attempting login with identifier: $identifier');
      }

      final response = await _apiService.post(AppConstants.loginEndpoint, data: {
        'identifier': identifier.trim(),
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (kDebugMode) {
          print('✅ Login OTP sent: $data');
        }
        
        // Store login context
        await HiveService.saveSignupContext({
          'session_type': 'login',
          'identifier': identifier,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        return OTPResult(
          success: true,
          expiresInMinutes: data['expires_in_minutes'] ?? 5,
        );
      } else {
        final data = response.data;
        return OTPResult(
          success: false,
          error: data['message'] ?? 'Login failed',
          errorCode: data['code'] ?? 'LOGIN_FAILED',
        );
      }
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return const OTPResult(
          success: false, 
          error: 'Account not found',
          errorCode: 'ACCOUNT_NOT_FOUND',
        );
      }
      return _handleOTPError(e);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Login error: $e');
      }
      return OTPResult(
        success: false,
        error: 'Login failed: $e',
        errorCode: 'LOGIN_ERROR',
      );
    }
  }


  /// Resend OTP with enhanced rate limiting
  Future<OTPResult> resendOTP(String phoneNumber) async {
    try {
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      
      if (kDebugMode) {
        print('🔄 Resending OTP to: $formattedPhone');
      }

      final response = await _apiService.post(AppConstants.resendOtpEndpoint, data: {
        'phone_number': formattedPhone,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (kDebugMode) {
          print('✅ OTP resent successfully: $data');
        }
        
        return OTPResult(
          success: true,
          expiresInMinutes: data['expires_in_minutes'] ?? 5,
        );
      } else {
        final data = response.data;
        return OTPResult(
          success: false,
          error: data['message'] ?? 'Failed to resend code',
          errorCode: data['code'] ?? 'RESEND_FAILED',
        );
      }
    } on ApiException catch (e) {
      return _handleOTPError(e);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Resend OTP error: $e');
      }
      return OTPResult(
        success: false,
        error: 'Failed to resend code: $e',
        errorCode: 'RESEND_ERROR',
      );
    }
  }

  /// Add plate number to existing phone-only account
  Future<AuthResult> addPlateNumber(String plateNumber) async {
    try {
      if (!_isValidPlateNumber(plateNumber)) {
        return const AuthResult(
          success: false,
          error: 'Invalid plate number format. Use format ABC123DD',
          errorCode: 'INVALID_PLATE_FORMAT',
        );
      }

      if (kDebugMode) {
        print('🚗 Adding plate number: $plateNumber');
      }

      final response = await _apiService.post(AppConstants.addPlateEndpoint, data: {
        'plate_number': plateNumber.toUpperCase(),
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (kDebugMode) {
          print('✅ Plate number added successfully: $data');
        }
        
        // Update stored rider data
        if (data['rider'] != null) {
          await HiveService.saveRiderData(jsonEncode(data['rider']));
        }
        
        return AuthResult(
          success: true,
          rider: data['rider'] != null ? Rider.fromJson(data['rider']) : null,
        );
      } else {
        final data = response.data;
        return AuthResult(
          success: false,
          error: data['message'] ?? 'Failed to add plate number',
          errorCode: data['code'] ?? 'ADD_PLATE_FAILED',
        );
      }
    } on ApiException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Add plate number error: $e');
      }
      return AuthResult(
        success: false,
        error: 'Failed to add plate number: $e',
        errorCode: 'ADD_PLATE_ERROR',
      );
    }
  }

  /// Check if identifier (phone/plate) exists
  Future<bool> checkIdentifierExists(String identifier) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.checkIdentifierEndpoint}?identifier=${Uri.encodeComponent(identifier)}',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['exists'] == true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Check identifier error: $e');
      }
      return false;
    }
  }

  /// Enhanced logout with refresh token blacklisting
  @override
  Future<void> logout() async {
    try {
      // Get refresh token for logout
      final refreshToken = HiveService.getRefreshToken();
      
      // Notify backend about logout
      if (refreshToken != null) {
        await _apiService.post(AppConstants.logoutEndpoint, data: {
          'refresh': refreshToken,
        });
      }
      
      if (kDebugMode) {
        print('✅ Logout API call successful');
      }
    } catch (e) {
      // Ignore logout errors - clear local data anyway
      if (kDebugMode) {
        print('⚠️ Logout API call failed: $e');
      }
    } finally {
      // Clear all stored auth data
      await HiveService.clearAuthData();
      
      // Clear OTP cache
      _otpCache.clear();
      
      if (kDebugMode) {
        print('🧹 Auth data cleared locally');
      }
    }
  }

  // === UTILITY METHODS ===

  /// Check if input is a valid phone number format
  bool isPhoneNumber(String input) {
    if (input.isEmpty) return false;
    
    // Remove all non-digit characters except +
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check various Nigerian phone number formats
    final patterns = [
      r'^\+234[789][01]\d{8}$',  // +2348012345678
      r'^234[789][01]\d{8}$',   // 2348012345678
      r'^0[789][01]\d{8}$',     // 08012345678
      r'^[789][01]\d{8}$',      // 8012345678
    ];
    
    return patterns.any((pattern) => RegExp(pattern).hasMatch(cleaned));
  }

  /// Check if input is a valid plate number format
  bool isPlateNumber(String input) {
    if (input.isEmpty) return false;
    
    // Remove spaces and convert to uppercase
    final cleaned = input.replaceAll(' ', '').toUpperCase();
    
    // Nigerian plate format: ABC123DD (3 letters, 3 numbers, 2 letters)
    return RegExp(r'^[A-Z]{3}[0-9]{3}[A-Z]{2}$').hasMatch(cleaned);
  }

  /// Get input type for validation feedback
  String getInputType(String input) {
    if (isPhoneNumber(input)) return 'phone';
    if (isPlateNumber(input)) return 'plate';
    
    // Check partial patterns for UI feedback
    if (input.startsWith('0') || input.startsWith('+')) return 'phone_partial';
    if (RegExp(r'^[A-Za-z]{1,3}[0-9]*[A-Za-z]*$').hasMatch(input)) return 'plate_partial';
    
    return 'unknown';
  }
}
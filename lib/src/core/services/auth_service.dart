import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../models/rider.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthResult {
  final bool success;
  final String? token;
  final Rider? rider;
  final String? error;
  final String? errorCode;

  const AuthResult({
    required this.success,
    this.token,
    this.rider,
    this.error,
    this.errorCode,
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
  final StorageService _storage = StorageService();
  
  // OTP cache for validation
  final Map<String, Map<String, dynamic>> _otpCache = {};
  
  /// Send OTP using Kudisms SMS service
  Future<OTPResult> sendOTP(String phoneNumber) async {
    try {
      // Format phone number for Nigerian context
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      
      // Validate phone number format
      if (!isValidNigerianPhone(formattedPhone)) {
        return OTPResult(
          success: false,
          error: 'Please enter a valid Nigerian phone number',
          errorCode: 'INVALID_PHONE',
        );
      }

      // Generate 6-digit OTP
      final otp = _generateOTP();
      final expiresAt = DateTime.now().add(Duration(minutes: 5));
      
      // Send OTP via backend (which uses Kudisms)
      final response = await _apiService.post('/auth/send-otp/', data: {
        'phone_number': formattedPhone,
        'otp': otp, // Backend will use this specific OTP
      });

      if (response.statusCode == 200) {
        // Cache OTP locally for validation (backup)
        _otpCache[formattedPhone] = {
          'otp': otp,
          'expires_at': expiresAt.toIso8601String(),
          'attempts': 0,
        };

        return OTPResult(
          success: true,
          expiresInMinutes: 5,
        );
      } else {
        return OTPResult(
          success: false,
          error: 'Failed to send verification code',
          errorCode: 'SEND_FAILED',
        );
      }
    } on DioException catch (e) {
      return _handleOTPError(e);
    } catch (e) {
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
      final lastSent = await _storage.getString('last_otp_sent_$formattedPhone');
      if (lastSent != null) {
        final lastSentTime = DateTime.parse(lastSent);
        final timeDiff = DateTime.now().difference(lastSentTime).inSeconds;
        
        if (timeDiff < 60) { // 1 minute rate limit
          return OTPResult(
            success: false,
            error: 'Please wait ${60 - timeDiff} seconds before requesting again',
            errorCode: 'RATE_LIMITED',
          );
        }
      }

      // Store timestamp for rate limiting
      await _storage.setString(
        'last_otp_sent_$formattedPhone',
        DateTime.now().toIso8601String(),
      );

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
      
      // Validate OTP format
      if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
        return AuthResult(
          success: false,
          error: 'Please enter a valid 6-digit code',
          errorCode: 'INVALID_OTP_FORMAT',
        );
      }

      // Check local cache first (for immediate validation)
      final cachedOTP = _otpCache[formattedPhone];
      if (cachedOTP != null) {
        final expiresAt = DateTime.parse(cachedOTP['expires_at']);
        final attempts = cachedOTP['attempts'] as int;
        
        // Check if expired
        if (DateTime.now().isAfter(expiresAt)) {
          _otpCache.remove(formattedPhone);
          return AuthResult(
            success: false,
            error: 'Verification code has expired. Request a new one.',
            errorCode: 'OTP_EXPIRED',
          );
        }
        
        // Check attempt limit
        if (attempts >= 3) {
          _otpCache.remove(formattedPhone);
          return AuthResult(
            success: false,
            error: 'Too many failed attempts. Request a new code.',
            errorCode: 'TOO_MANY_ATTEMPTS',
          );
        }
        
        // Update attempts
        _otpCache[formattedPhone]!['attempts'] = attempts + 1;
      }

      // Verify with backend
      final response = await _apiService.post('/auth/verify-otp/', data: {
        'phone_number': formattedPhone,
        'otp': otp,
        'device_info': await _getDeviceInfo(),
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Clear OTP cache on success
        _otpCache.remove(formattedPhone);
        
        // Store auth token
        await _storage.setString('auth_token', data['access_token']);
        await _storage.setString('refresh_token', data['refresh_token']);
        
        return AuthResult(
          success: true,
          token: data['access_token'],
          rider: Rider.fromJson(data['rider']),
        );
      } else {
        return AuthResult(
          success: false,
          error: 'Invalid verification code',
          errorCode: 'INVALID_OTP',
        );
      }
    } on DioException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
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
      final refreshToken = await _storage.getString('refresh_token');
      
      if (refreshToken == null) {
        return AuthResult(
          success: false,
          error: 'No refresh token available',
          errorCode: 'NO_REFRESH_TOKEN',
        );
      }

      final response = await _apiService.post('/auth/refresh/', data: {
        'refresh_token': refreshToken,
        'device_info': await _getDeviceInfo(),
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Update stored tokens
        await _storage.setString('auth_token', data['access_token']);
        if (data['refresh_token'] != null) {
          await _storage.setString('refresh_token', data['refresh_token']);
        }
        
        return AuthResult(
          success: true,
          token: data['access_token'],
          rider: data['rider'] != null ? Rider.fromJson(data['rider']) : null,
        );
      } else {
        return AuthResult(
          success: false,
          error: 'Failed to refresh session',
          errorCode: 'REFRESH_FAILED',
        );
      }
    } catch (e) {
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
      // Notify backend about logout
      await _apiService.post('/auth/logout/', data: {});
    } catch (e) {
      // Ignore logout errors - clear local data anyway
      print('Logout API call failed: $e');
    } finally {
      // Clear all stored auth data
      await _storage.remove('auth_token');
      await _storage.remove('refresh_token');
      await _storage.remove('rider_data');
      
      // Clear OTP cache
      _otpCache.clear();
    }
  }

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storage.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  /// Get stored authentication token
  Future<String?> getAuthToken() async {
    return await _storage.getString('auth_token');
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
    
    // Valid Nigerian mobile prefixes
    final validPrefixes = [
      '803', '806', '813', '814', '816', '903', '906', // MTN
      '802', '808', '812', '701', '902', '904', '907', '912', // Airtel
      '805', '807', '815', '811', '905', // Glo
      '809', '818', '817', '908', '909', // 9mobile
    ];
    
    final prefix = number.substring(0, 3);
    return validPrefixes.contains(prefix);
  }

  /// Generate secure 6-digit OTP
  String _generateOTP() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Get device information for security
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // This would typically use device_info_plus package
    return {
      'platform': 'flutter',
      'timestamp': DateTime.now().toIso8601String(),
      // Add more device info as needed for security
    };
  }

  /// Handle OTP-related errors
  OTPResult _handleOTPError(DioException e) {
    if (e.response?.statusCode == 400) {
      final errorData = e.response?.data;
      final errorCode = errorData['code'];
      
      switch (errorCode) {
        case 'INVALID_PHONE':
          return OTPResult(
            success: false,
            error: 'Please enter a valid phone number',
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
          return OTPResult(
            success: false,
            error: errorData['message'] ?? 'Failed to send verification code',
            errorCode: errorCode,
          );
      }
    } else if (e.response?.statusCode == 500) {
      return OTPResult(
        success: false,
        error: 'Server error. Please try again later.',
        errorCode: 'SERVER_ERROR',
      );
    }
    
    return OTPResult(
      success: false,
      error: 'Network error. Please check your connection.',
      errorCode: 'NETWORK_ERROR',
    );
  }

  /// Handle authentication-related errors
  AuthResult _handleAuthError(DioException e) {
    if (e.response?.statusCode == 400) {
      final errorData = e.response?.data;
      final errorCode = errorData['code'];
      
      switch (errorCode) {
        case 'INVALID_OTP':
          return AuthResult(
            success: false,
            error: 'Invalid verification code. Please try again.',
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
          return AuthResult(
            success: false,
            error: errorData['message'] ?? 'Authentication failed',
            errorCode: errorCode,
          );
      }
    }
    
    return AuthResult(
      success: false,
      error: 'Network error. Please try again.',
      errorCode: 'NETWORK_ERROR',
    );
  }
}
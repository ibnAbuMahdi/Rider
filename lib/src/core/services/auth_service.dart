import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/rider.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import '../storage/hive_service.dart'; // Updated import

class AuthResult {
  final bool success;
  final String? token;
  final String? refreshToken; // Added refresh token
  final Rider? rider;
  final String? error;
  final String? errorCode;
  final bool isNewUser; // Added to track new registrations

  const AuthResult({
    required this.success,
    this.token,
    this.refreshToken,
    this.rider,
    this.error,
    this.errorCode,
    this.isNewUser = false,
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
        return OTPResult(
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
        return OTPResult(
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
        return OTPResult(
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
        return AuthResult(
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
        
        // Store auth tokens
        await HiveService.saveAuthToken(data['access_token']);
        await HiveService.saveRefreshToken(data['refresh_token']);
        
        // Store rider data
        if (data['rider'] != null) {
          await HiveService.saveRiderData(jsonEncode(data['rider']));
        }
        
        return AuthResult(
          success: true,
          token: data['access_token'],
          refreshToken: data['refresh_token'],
          rider: data['rider'] != null ? Rider.fromJson(data['rider']) : null,
          isNewUser: data['is_new_user'] ?? false,
        );
      } else {
        return AuthResult(
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
        return AuthResult(
          success: false,
          error: 'No refresh token available',
          errorCode: 'NO_REFRESH_TOKEN',
        );
      }

      if (kDebugMode) {
        print('🔄 Refreshing token...');
      }

      final response = await _apiService.post(AppConstants.refreshTokenEndpoint, data: {
        'refresh_token': refreshToken,
        'device_info': await _getDeviceInfo(),
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Update stored tokens
        await HiveService.saveAuthToken(data['access_token']);
        if (data['refresh_token'] != null) {
          await HiveService.saveRefreshToken(data['refresh_token']);
        }
        
        // Update rider data if provided
        if (data['rider'] != null) {
          await HiveService.saveRiderData(jsonEncode(data['rider']));
        }
        
        if (kDebugMode) {
          print('✅ Token refreshed successfully');
        }
        
        return AuthResult(
          success: true,
          token: data['access_token'],
          refreshToken: data['refresh_token'],
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
          'refresh_token': refreshToken,
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
    // Basic device info - you can enhance this with device_info_plus
    return {
      'platform': 'flutter',
      'app_version': AppConstants.appVersion,
      'timestamp': DateTime.now().toIso8601String(),
      // Add more device info as needed for security
    };
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
    
    return AuthResult(
      success: false,
      error: 'Network error. Please try again.',
      errorCode: 'NETWORK_ERROR',
    );
  }
}
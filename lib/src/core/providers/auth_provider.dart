import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rider.dart';
import '../services/auth_service.dart';
import '../storage/hive_service.dart';

// Auth state class
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final Rider? rider;
  final String? error;
  final String? phone_number;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.rider,
    this.error,
    this.phone_number,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    Rider? rider,
    String? error,
    String? phone_number,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      rider: rider ?? this.rider,
      error: error,
      phone_number: phone_number,
    );
  }
}

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = HiveService.getAuthToken();
    final rider = HiveService.getRider();
    
    if (token != null && rider != null) {
      state = state.copyWith(
        isAuthenticated: true,
        rider: rider,
      );
    }
  }

  // === NEW FLEXIBLE AUTH METHODS ===

  /// Combined signup with phone + optional plate
  Future<bool> signup({required String phone, String? plate}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _authService.signup(phone: phone, plate: plate);
      
      if (result.success) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Send login OTP for phone or plate number
  Future<bool> sendLoginOTP(String identifier) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _authService.sendLoginOTP(identifier);
      
      if (result.success) {
        state = state.copyWith(isLoading: false, phone_number: result.phone_number);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Legacy OTP sending method for backward compatibility
  Future<void> sendOTP(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authService.sendOTP(phoneNumber);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Enhanced OTP verification with signup completion handling
  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _authService.verifyOTP(phoneNumber, otp);
      
      if (result.success) {
        // Tokens are already saved by AuthService
        if (result.rider != null) {
          await HiveService.saveUserId(result.rider!.id);
          await HiveService.saveRider(result.rider!);
        }
        
        if (kDebugMode) {
          print('🎯 AUTH SUCCESS: ${result.sessionType} completed');
          print('🎯 AUTH: Is New User: ${result.isNewUser}');
          if (result.rider != null) {
            print('🎯 AUTH: Rider ID: ${result.rider!.id}');
            print('🎯 AUTH: Rider Phone: ${result.rider!.phoneNumber}');
            print('🎯 AUTH: Current Campaign ID: ${result.rider!.currentCampaignId}');
            print('🎯 AUTH: Has Completed Onboarding: ${result.rider!.hasCompletedOnboarding}');
            print('🎯 AUTH: Is Active: ${result.rider!.isActive}');
            print('🎯 AUTH: Status: ${result.rider!.status}');
          }
        }
        
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          rider: result.rider,
        );
        
        // Handle post-auth actions based on session type
        if (result.sessionType == 'signup') {
          _handleSignupCompletion(result.rider);
        }
        
        // Trigger my-campaigns refresh to get geofence assignments
        if (kDebugMode) {
          print('🎯 AUTH SUCCESS: Triggering my-campaigns refresh to load geofence assignments');
        }
        
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Verification failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void _handleSignupCompletion(Rider? rider) {
    // Additional logic for new user onboarding
    if (rider?.plateNumber != null) {
      // User signed up with plate - they're ready to ride
      if (kDebugMode) {
        print('🎯 New user with plate number - ready to ride');
      }
    } else {
      // User signed up with phone only - may need plate activation later
      if (kDebugMode) {
        print('🎯 New user with phone only - may need plate activation');
      }
    }
  }

  Future<void> logout() async {
    // Use AuthService logout for comprehensive cleanup
    await _authService.logout();
    
    // Reset auth provider state
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<bool> activateRider(String plateNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _authService.activateRider(plateNumber);
      
      if (result.success && result.rider != null) {
        // Update local storage with new rider data
        await HiveService.saveRider(result.rider!);
        
        state = state.copyWith(
          isLoading: false,
          rider: result.rider,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Activation failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

// Providers
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Helper providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentRiderProvider = Provider<Rider?>((ref) {
  return ref.watch(authProvider).rider;
});
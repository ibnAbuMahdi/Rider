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

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.rider,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    Rider? rider,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      rider: rider ?? this.rider,
      error: error,
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

  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _authService.verifyOTP(phoneNumber, otp);
      
      if (result.success) {
        await HiveService.saveAuthToken(result.token!);
        await HiveService.saveUserId(result.rider!.id);
        await HiveService.saveRider(result.rider!);
        
        if (kDebugMode) {
          print('🎯 AUTH SUCCESS: Saved rider data');
          print('🎯 AUTH: Rider ID: ${result.rider!.id}');
          print('🎯 AUTH: Rider Phone: ${result.rider!.phoneNumber}');
          print('🎯 AUTH: Current Campaign ID: ${result.rider!.currentCampaignId}');
          print('🎯 AUTH: Has Completed Onboarding: ${result.rider!.hasCompletedOnboarding}');
          print('🎯 AUTH: Is Active: ${result.rider!.isActive}');
          print('🎯 AUTH: Status: ${result.rider!.status}');
        }
        
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          rider: result.rider,
        );
        
        // Trigger my-campaigns refresh to get geofence assignments
        // This is crucial for geofence-aware random verification
        if (kDebugMode) {
          print('🎯 AUTH SUCCESS: Triggering my-campaigns refresh to load geofence assignments');
        }
        // Note: We'll trigger this through a provider ref in the calling widget
        // since we can't directly access other providers from here
        
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

  Future<void> logout() async {
    await HiveService.clearAuthToken();
    await HiveService.clearRider();
    
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
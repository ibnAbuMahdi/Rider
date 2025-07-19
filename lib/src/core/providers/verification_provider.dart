import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/verification_request.dart';
import '../services/verification_service.dart';
import '../storage/hive_service.dart';

// Verification state class
class VerificationState {
  final List<VerificationRequest> requests;
  final VerificationRequest? currentRequest;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const VerificationState({
    this.requests = const [],
    this.currentRequest,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  VerificationState copyWith({
    List<VerificationRequest>? requests,
    VerificationRequest? currentRequest,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return VerificationState(
      requests: requests ?? this.requests,
      currentRequest: currentRequest ?? this.currentRequest,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

// Verification state notifier
class VerificationNotifier extends StateNotifier<VerificationState> {
  final VerificationService _verificationService;

  VerificationNotifier(this._verificationService) : super(const VerificationState()) {
    _loadCachedRequests();
  }

  void _loadCachedRequests() {
    final requests = HiveService.getVerificationRequests();
    final currentRequest = requests
        .where((r) => r.isPending && !r.isExpired)
        .firstOrNull;

    state = state.copyWith(
      requests: requests,
      currentRequest: currentRequest,
    );
  }

  Future<void> loadVerificationRequests() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final requests = await _verificationService.getVerificationRequests();
      
      // Cache requests locally
      for (final request in requests) {
        await HiveService.saveVerificationRequest(request);
      }
      
      final currentRequest = requests
          .where((r) => r.isPending && !r.isExpired)
          .firstOrNull;
      
      state = state.copyWith(
        requests: requests,
        currentRequest: currentRequest,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> submitVerification({
    required String campaignId,
    required String imagePath,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    
    try {
      final result = await _verificationService.submitVerification(
        campaignId: campaignId,
        imagePath: imagePath,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );
      
      if (result.success) {
        // Update local request if it exists
        if (state.currentRequest != null) {
          final updatedRequest = state.currentRequest!.copyWith(
            status: VerificationStatus.processing,
            localImagePath: imagePath,
            isSynced: true,
          );
          
          await HiveService.updateVerificationRequest(updatedRequest);
          
          state = state.copyWith(
            currentRequest: null,
            isSubmitting: false,
          );
        }
        
        return true;
      } else {
        state = state.copyWith(
          isSubmitting: false,
          error: result.error ?? 'Verification failed',
        );
        return false;
      }
    } catch (e) {
      // Store for offline retry
      await _storeOfflineVerification(
        campaignId: campaignId,
        imagePath: imagePath,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );
      
      state = state.copyWith(
        isSubmitting: false,
        error: 'Stored for retry when online',
      );
      return false;
    }
  }

  Future<void> _storeOfflineVerification({
    required String campaignId,
    required String imagePath,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    final now = DateTime.now();
    final request = VerificationRequest(
      id: '${now.millisecondsSinceEpoch}',
      riderId: HiveService.getUserId() ?? '',
      campaignId: campaignId,
      localImagePath: imagePath,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: now,
      deadline: now.add(const Duration(minutes: 10)),
      createdAt: now,
      status: VerificationStatus.pending,
      isSynced: false,
    );
    
    await HiveService.saveVerificationRequest(request);
  }

  Future<void> retryFailedVerifications() async {
    final pendingRequests = HiveService.getPendingVerifications();
    
    for (final request in pendingRequests) {
      if (request.localImagePath != null && !request.isExpired) {
        try {
          final result = await _verificationService.submitVerification(
            campaignId: request.campaignId,
            imagePath: request.localImagePath!,
            latitude: request.latitude,
            longitude: request.longitude,
            accuracy: request.accuracy,
          );
          
          if (result.success) {
            final updatedRequest = request.copyWith(
              status: VerificationStatus.processing,
              isSynced: true,
            );
            await HiveService.updateVerificationRequest(updatedRequest);
          }
        } catch (e) {
          // Continue with other requests
        }
      }
    }
    
    // Reload requests after retry
    _loadCachedRequests();
  }

  Future<void> markVerificationComplete(String requestId, VerificationStatus status) async {
    final request = state.requests.where((r) => r.id == requestId).firstOrNull;
    if (request != null) {
      final updatedRequest = request.copyWith(
        status: status,
        processedAt: DateTime.now(),
      );
      
      await HiveService.updateVerificationRequest(updatedRequest);
      
      // Update state
      final updatedRequests = state.requests.map((r) {
        return r.id == requestId ? updatedRequest : r;
      }).toList();
      
      state = state.copyWith(requests: updatedRequests);
    }
  }

  void clearCurrentRequest() {
    state = state.copyWith(currentRequest: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Helper getters
  List<VerificationRequest> get pendingRequests {
    return state.requests
        .where((r) => r.isPending && !r.isExpired)
        .toList();
  }

  List<VerificationRequest> get completedRequests {
    return state.requests
        .where((r) => r.isPassed || r.isFailed)
        .toList();
  }

  bool get hasActiveRequest {
    return state.currentRequest != null && !state.currentRequest!.isExpired;
  }
}

// Providers
final verificationServiceProvider = Provider<VerificationService>((ref) {
  return VerificationService();
});

final verificationProvider = StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  final verificationService = ref.watch(verificationServiceProvider);
  return VerificationNotifier(verificationService);
});

// Helper providers
final currentVerificationRequestProvider = Provider<VerificationRequest?>((ref) {
  return ref.watch(verificationProvider).currentRequest;
});

final hasActiveVerificationProvider = Provider<bool>((ref) {
  return ref.watch(verificationProvider.notifier).hasActiveRequest;
});

final pendingVerificationCountProvider = Provider<int>((ref) {
  return ref.watch(verificationProvider.notifier).pendingRequests.length;
});
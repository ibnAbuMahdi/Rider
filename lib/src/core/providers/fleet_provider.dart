import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/fleet_status.dart';
import '../services/fleet_service.dart';

// Fleet service provider
final fleetServiceProvider = Provider<FleetService>((ref) {
  return FleetService();
});

// Current fleet status provider
final fleetStatusProvider = StateNotifierProvider<FleetStatusNotifier, AsyncValue<FleetStatus?>>((ref) {
  final fleetService = ref.watch(fleetServiceProvider);
  return FleetStatusNotifier(fleetService);
});

// Fleet lookup state provider (for the lookup process)
final fleetLookupProvider = StateNotifierProvider<FleetLookupNotifier, AsyncValue<FleetLookupResult?>>((ref) {
  final fleetService = ref.watch(fleetServiceProvider);
  return FleetLookupNotifier(fleetService);
});

// Fleet join state provider
final fleetJoinProvider = StateNotifierProvider<FleetJoinNotifier, AsyncValue<FleetJoinResult?>>((ref) {
  final fleetService = ref.watch(fleetServiceProvider);
  return FleetJoinNotifier(fleetService);
});

// Fleet leave state provider
final fleetLeaveProvider = StateNotifierProvider<FleetLeaveNotifier, AsyncValue<FleetLeaveResult?>>((ref) {
  final fleetService = ref.watch(fleetServiceProvider);
  return FleetLeaveNotifier(fleetService);
});

class FleetStatusNotifier extends StateNotifier<AsyncValue<FleetStatus?>> {
  final FleetService _fleetService;

  FleetStatusNotifier(this._fleetService) : super(const AsyncValue.loading()) {
    loadFleetStatus();
  }

  Future<void> loadFleetStatus() async {
    try {
      state = const AsyncValue.loading();
      final status = await _fleetService.getFleetStatus();
      state = AsyncValue.data(status);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Fleet status load error: $e');
      }
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshFleetStatus() async {
    await loadFleetStatus();
  }

  // Helper getters for common checks
  bool get isInFleet {
    final statusValue = state.valueOrNull;
    return statusValue?.isInFleet ?? false;
  }

  bool get canJoinFleet {
    final statusValue = state.valueOrNull;
    return statusValue?.rider.isIndependentRider ?? true;
  }

  bool get canLeaveFleet {
    final statusValue = state.valueOrNull;
    if (statusValue?.isInFleet == true) {
      return statusValue!.fleet!.lockedRiders != true;
    }
    return false;
  }

  String get statusDisplay {
    final statusValue = state.valueOrNull;
    return statusValue?.statusDisplay ?? 'Status Unknown';
  }
}

class FleetLookupNotifier extends StateNotifier<AsyncValue<FleetLookupResult?>> {
  final FleetService _fleetService;

  FleetLookupNotifier(this._fleetService) : super(const AsyncValue.data(null));

  Future<void> lookupFleet(String fleetCode) async {
    try {
      state = const AsyncValue.loading();
      final result = await _fleetService.lookupFleetByCode(fleetCode);
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Fleet lookup error: $e');
      }
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clearLookup() {
    state = const AsyncValue.data(null);
  }
}

class FleetJoinNotifier extends StateNotifier<AsyncValue<FleetJoinResult?>> {
  final FleetService _fleetService;

  FleetJoinNotifier(this._fleetService) : super(const AsyncValue.data(null));

  Future<void> joinFleet(String fleetCode, WidgetRef ref) async {
    try {
      state = const AsyncValue.loading();
      final result = await _fleetService.joinFleet(fleetCode);
      state = AsyncValue.data(result);
      
      // Refresh fleet status after successful join
      if (result.success) {
        ref.read(fleetStatusProvider.notifier).refreshFleetStatus();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Fleet join error: $e');
      }
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clearJoinResult() {
    state = const AsyncValue.data(null);
  }
}

class FleetLeaveNotifier extends StateNotifier<AsyncValue<FleetLeaveResult?>> {
  final FleetService _fleetService;

  FleetLeaveNotifier(this._fleetService) : super(const AsyncValue.data(null));

  Future<void> leaveFleet(WidgetRef ref, {String? reason}) async {
    try {
      state = const AsyncValue.loading();
      final result = await _fleetService.leaveFleet(reason: reason);
      state = AsyncValue.data(result);
      
      // Refresh fleet status after successful leave
      if (result.success) {
        ref.read(fleetStatusProvider.notifier).refreshFleetStatus();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Fleet leave error: $e');
      }
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clearLeaveResult() {
    state = const AsyncValue.data(null);
  }
}

// Convenience provider for checking if user can perform fleet actions
final fleetActionsProvider = Provider<FleetActions>((ref) {
  final fleetStatus = ref.watch(fleetStatusProvider);
  return FleetActions(fleetStatus);
});

class FleetActions {
  final AsyncValue<FleetStatus?> fleetStatus;

  FleetActions(this.fleetStatus);

  bool get canJoinFleet {
    final status = fleetStatus.valueOrNull;
    return status?.rider.isIndependentRider ?? true;
  }

  bool get canLeaveFleet {
    final status = fleetStatus.valueOrNull;
    if (status?.isInFleet == true) {
      return status!.fleet!.lockedRiders != true;
    }
    return false;
  }

  bool get isInFleet {
    final status = fleetStatus.valueOrNull;
    return status?.isInFleet ?? false;
  }

  String get currentFleetName {
    final status = fleetStatus.valueOrNull;
    return status?.fleet?.name ?? 'No Fleet';
  }

  String get statusDisplay {
    final status = fleetStatus.valueOrNull;
    return status?.statusDisplay ?? 'Status Unknown';
  }

  double get commissionRate {
    final status = fleetStatus.valueOrNull;
    return status?.rider.fleetCommissionRate ?? 0.0;
  }
}
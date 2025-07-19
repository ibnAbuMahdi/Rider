import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/earning.dart';
import '../models/location_record.dart';
import '../models/payment_summary.dart';
import '../services/earnings_service.dart';
import '../services/api_service.dart';
import '../storage/hive_service.dart';

// Earnings state
class EarningsState {
  final List<Earning> earnings;
  final PaymentSummary? paymentSummary;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const EarningsState({
    this.earnings = const [],
    this.paymentSummary,
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  EarningsState copyWith({
    List<Earning>? earnings,
    PaymentSummary? paymentSummary,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return EarningsState(
      earnings: earnings ?? this.earnings,
      paymentSummary: paymentSummary ?? this.paymentSummary,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Earnings provider
class EarningsNotifier extends StateNotifier<EarningsState> {
  final EarningsService _earningsService;

  EarningsNotifier(this._earningsService) : super(const EarningsState());

  // Load earnings from local storage first
  Future<void> loadLocalEarnings() async {
    try {
      final localEarningsRecords = HiveService.getEarningsRecords();
      // Convert EarningsRecord to Earning
      final localEarnings = localEarningsRecords.map((record) => Earning(
        id: record.id,
        riderId: record.riderId,
        campaignId: record.campaignId ?? '',
        campaignTitle: record.campaignName ?? '',
        amount: record.amount,
        currency: record.currency,
        earningType: record.type.toString(),
        periodStart: record.earnedAt,
        periodEnd: record.earnedAt,
        status: 'completed', // Default status
        metadata: const {},
        createdAt: record.earnedAt,
      )).toList();
      state = state.copyWith(earnings: localEarnings);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load local earnings: $e');
      }
    }
  }

  // Fetch earnings from API
  Future<void> fetchEarnings({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    try {
      if (refresh) {
        state = state.copyWith(
          isLoading: true,
          error: null,
          currentPage: 1,
          hasMore: true,
        );
      } else {
        state = state.copyWith(isLoading: true, error: null);
      }

      final response = await _earningsService.getEarnings(
        page: refresh ? 1 : state.currentPage,
      );

      if (response != null) {
        final newEarnings = response['earnings'] as List<Earning>;
        final hasMore = response['has_more'] as bool;

        // Save to local storage
        for (final earning in newEarnings) {
          final earningsRecord = EarningsRecord(
            id: earning.id,
            riderId: earning.riderId,
            campaignId: earning.campaignId.isEmpty ? null : earning.campaignId,
            campaignName: earning.campaignTitle.isEmpty ? null : earning.campaignTitle,
            amount: earning.amount,
            currency: earning.currency,
            type: EarningsType.campaign, // Default type, you may want to map this properly
            earnedAt: earning.createdAt,
            createdAt: earning.createdAt,
          );
          await HiveService.saveEarningsRecord(earningsRecord);
        }

        final updatedEarnings = refresh 
          ? newEarnings 
          : [...state.earnings, ...newEarnings];

        state = state.copyWith(
          earnings: updatedEarnings,
          isLoading: false,
          hasMore: hasMore,
          currentPage: refresh ? 2 : state.currentPage + 1,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch earnings',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      if (kDebugMode) {
        print('❌ Failed to fetch earnings: $e');
      }
    }
  }

  // Fetch payment summary
  Future<void> fetchPaymentSummary() async {
    try {
      final summary = await _earningsService.getPaymentSummary();
      if (summary != null) {
        state = state.copyWith(paymentSummary: summary);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch payment summary: $e');
      }
    }
  }

  // Load more earnings (pagination)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await fetchEarnings();
  }

  // Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      fetchEarnings(refresh: true),
      fetchPaymentSummary(),
    ]);
  }

  // Filter earnings by status
  List<Earning> getEarningsByStatus(String status) {
    return state.earnings.where((e) => e.status == status).toList();
  }

  // Filter earnings by campaign
  List<Earning> getEarningsByCampaign(String campaignId) {
    return state.earnings.where((e) => e.campaignId == campaignId).toList();
  }

  // Filter earnings by date range
  List<Earning> getEarningsByDateRange(DateTime start, DateTime end) {
    return state.earnings.where((e) => 
      e.createdAt.isAfter(start) && e.createdAt.isBefore(end)
    ).toList();
  }

  // Get earnings for current week
  List<Earning> get thisWeekEarnings {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return getEarningsByDateRange(startOfWeek, endOfWeek);
  }

  // Get earnings for current month
  List<Earning> get thisMonthEarnings {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return getEarningsByDateRange(startOfMonth, endOfMonth);
  }

  // Calculate total pending amount
  double get totalPendingAmount {
    return getEarningsByStatus('pending')
        .fold(0.0, (sum, earning) => sum + earning.amount);
  }

  // Calculate total paid amount
  double get totalPaidAmount {
    return getEarningsByStatus('paid')
        .fold(0.0, (sum, earning) => sum + earning.amount);
  }

  // Calculate total earnings amount
  double get totalEarningsAmount {
    return state.earnings.fold(0.0, (sum, earning) => sum + earning.amount);
  }

  // Request payment
  Future<bool> requestPayment({
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final success = await _earningsService.requestPayment(
        amount: amount,
        paymentMethod: paymentMethod,
        notes: notes,
      );

      if (success) {
        // Refresh earnings to show updated status
        await fetchEarnings(refresh: true);
        await fetchPaymentSummary();
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to request payment: $e');
      }
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final earningsServiceProvider = Provider<EarningsService>((ref) {
  return EarningsService(ApiService());
});

final earningsProvider = StateNotifierProvider.autoDispose<EarningsNotifier, EarningsState>((ref) {
  final earningsService = ref.watch(earningsServiceProvider);
  return EarningsNotifier(earningsService);
});

// Convenience providers
final pendingEarningsProvider = Provider<List<Earning>>((ref) {
  return ref.watch(earningsProvider.notifier).getEarningsByStatus('pending');
});

final paidEarningsProvider = Provider<List<Earning>>((ref) {
  return ref.watch(earningsProvider.notifier).getEarningsByStatus('paid');
});

final totalPendingAmountProvider = Provider<double>((ref) {
  return ref.watch(earningsProvider.notifier).totalPendingAmount;
});

final totalPaidAmountProvider = Provider<double>((ref) {
  return ref.watch(earningsProvider.notifier).totalPaidAmount;
});

final paymentSummaryProvider = Provider<PaymentSummary?>((ref) {
  return ref.watch(earningsProvider).paymentSummary;
});
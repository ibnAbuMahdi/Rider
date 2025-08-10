import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/earnings_service.dart';
import '../services/api_service.dart';
import '../services/location_api_service.dart';
import '../models/campaign_earnings.dart';
// Import existing earnings service provider
import 'earnings_provider.dart' show earningsServiceProvider;

// Enhanced earnings providers for new design

// Earnings overview provider
final earningsOverviewProvider = StateNotifierProvider<EarningsOverviewNotifier, EarningsOverview?>((ref) {
  final earningsService = ref.watch(earningsServiceProvider);
  return EarningsOverviewNotifier(earningsService);
});

// Campaign assignments provider
final campaignAssignmentsProvider = StateNotifierProvider<CampaignAssignmentsNotifier, List<CampaignEarnings>>((ref) {
  final earningsService = ref.watch(earningsServiceProvider);
  return CampaignAssignmentsNotifier(earningsService);
});

// Loading state provider
final earningsLoadingProvider = StateProvider<bool>((ref) => false);

// Campaign summaries provider (grouped by campaign)
final campaignSummariesProvider = StateNotifierProvider<CampaignSummariesNotifier, List<CampaignSummary>>((ref) {
  final earningsService = ref.watch(earningsServiceProvider);
  return CampaignSummariesNotifier(earningsService);
});

// Earnings overview notifier
class EarningsOverviewNotifier extends StateNotifier<EarningsOverview?> {
  final EarningsService _earningsService;
  
  EarningsOverviewNotifier(this._earningsService) : super(null) {
    refresh();
  }
  
  Future<void> refresh() async {
    final overview = await _earningsService.getEarningsOverview();
    state = overview;
  }
}

// Campaign assignments notifier
class CampaignAssignmentsNotifier extends StateNotifier<List<CampaignEarnings>> {
  final EarningsService _earningsService;
  int _currentPage = 1;
  bool _hasMore = true;
  String _currentFilter = 'all';
  bool _isLoading = false;
  
  CampaignAssignmentsNotifier(this._earningsService) : super([]) {
    refresh();
  }
  
  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    _isLoading = true;
    
    final assignments = await _earningsService.getGeofenceAssignmentEarnings(
      status: _currentFilter == 'all' ? null : _currentFilter,
      page: 1,
      limit: 20,
    );
    
    state = assignments ?? [];
    _isLoading = false;
    
    if (assignments == null || assignments.length < 20) {
      _hasMore = false;
    }
  }
  
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    
    _isLoading = true;
    _currentPage++;
    
    final moreAssignments = await _earningsService.getGeofenceAssignmentEarnings(
      status: _currentFilter == 'all' ? null : _currentFilter,
      page: _currentPage,
      limit: 20,
    );
    
    if (moreAssignments != null && moreAssignments.isNotEmpty) {
      state = [...state, ...moreAssignments];
      
      if (moreAssignments.length < 20) {
        _hasMore = false;
      }
    } else {
      _hasMore = false;
    }
    
    _isLoading = false;
  }
  
  void applyFilter(String filter) {
    _currentFilter = filter;
    refresh();
  }
  
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
}

// Campaign summaries notifier
class CampaignSummariesNotifier extends StateNotifier<List<CampaignSummary>> {
  final EarningsService _earningsService;
  
  CampaignSummariesNotifier(this._earningsService) : super([]) {
    refresh();
  }
  
  Future<void> refresh() async {
    final summaries = await _earningsService.getCampaignSummaries();
    state = summaries ?? [];
  }
}
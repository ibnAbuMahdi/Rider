import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/campaign.dart';
import '../services/campaign_service.dart';
import '../storage/hive_service.dart';

// Campaign state class
class CampaignState {
  final List<Campaign> campaigns;
  final Campaign? currentCampaign;
  final bool isLoading;
  final bool isJoining;
  final String? error;

  const CampaignState({
    this.campaigns = const [],
    this.currentCampaign,
    this.isLoading = false,
    this.isJoining = false,
    this.error,
  });

  CampaignState copyWith({
    List<Campaign>? campaigns,
    Campaign? currentCampaign,
    bool? isLoading,
    bool? isJoining,
    String? error,
  }) {
    return CampaignState(
      campaigns: campaigns ?? this.campaigns,
      currentCampaign: currentCampaign ?? this.currentCampaign,
      isLoading: isLoading ?? this.isLoading,
      isJoining: isJoining ?? this.isJoining,
      error: error,
    );
  }
}

// Campaign state notifier
class CampaignNotifier extends StateNotifier<CampaignState> {
  final CampaignService _campaignService;

  CampaignNotifier(this._campaignService) : super(const CampaignState()) {
    _loadCachedData();
  }

  void _loadCachedData() {
    // Load cached campaigns from Hive
    final campaigns = HiveService.getCampaigns();
    final rider = HiveService.getRider();
    
    Campaign? currentCampaign;
    if (rider?.currentCampaignId != null) {
      currentCampaign = campaigns
          .where((c) => c.id == rider!.currentCampaignId)
          .firstOrNull;
    }

    state = state.copyWith(
      campaigns: campaigns,
      currentCampaign: currentCampaign,
    );
  }

  Future<void> loadAvailableCampaigns() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final campaigns = await _campaignService.getAvailableCampaigns();
      
      // Cache campaigns locally
      await HiveService.saveCampaigns(campaigns);
      
      state = state.copyWith(
        campaigns: campaigns,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadAvailableCampaigns();
  }

  Future<bool> joinCampaign(String campaignId) async {
    state = state.copyWith(isJoining: true, error: null);
    
    try {
      final result = await _campaignService.joinCampaign(campaignId);
      
      if (result.success) {
        // Update current campaign
        final campaign = state.campaigns
            .where((c) => c.id == campaignId)
            .firstOrNull;
        
        if (campaign != null) {
          // Update rider's current campaign
          final rider = HiveService.getRider();
          if (rider != null) {
            final updatedRider = rider.copyWith(currentCampaignId: campaignId);
            await HiveService.saveRider(updatedRider);
          }
          
          // Update local campaign data
          final updatedCampaign = campaign.copyWith(
            currentRiders: campaign.currentRiders + 1,
          );
          await HiveService.saveCampaign(updatedCampaign);
          
          // Update state
          final updatedCampaigns = state.campaigns.map((c) {
            return c.id == campaignId ? updatedCampaign : c;
          }).toList();
          
          state = state.copyWith(
            campaigns: updatedCampaigns,
            currentCampaign: updatedCampaign,
            isJoining: false,
          );
          
          return true;
        }
      }
      
      state = state.copyWith(
        isJoining: false,
        error: result.error ?? 'Failed to join campaign',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isJoining: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> leaveCampaign() async {
    if (state.currentCampaign == null) return false;
    
    state = state.copyWith(isJoining: true, error: null);
    
    try {
      final result = await _campaignService.leaveCampaign(state.currentCampaign!.id);
      
      if (result.success) {
        // Update rider's current campaign
        final rider = HiveService.getRider();
        if (rider != null) {
          final updatedRider = rider.copyWith(currentCampaignId: null);
          await HiveService.saveRider(updatedRider);
        }
        
        // Update local campaign data
        final campaign = state.currentCampaign!;
        final updatedCampaign = campaign.copyWith(
          currentRiders: (campaign.currentRiders - 1).clamp(0, campaign.maxRiders),
        );
        await HiveService.saveCampaign(updatedCampaign);
        
        // Update state
        final updatedCampaigns = state.campaigns.map((c) {
          return c.id == campaign.id ? updatedCampaign : c;
        }).toList();
        
        state = state.copyWith(
          campaigns: updatedCampaigns,
          currentCampaign: null,
          isJoining: false,
        );
        
        return true;
      }
      
      state = state.copyWith(
        isJoining: false,
        error: result.error ?? 'Failed to leave campaign',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isJoining: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> refreshCampaigns() async {
    await loadAvailableCampaigns();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Get campaigns by status
  List<Campaign> get availableCampaigns {
    return state.campaigns
        .where((c) => c.canJoin)
        .toList();
  }

  List<Campaign> get runningCampaigns {
    return state.campaigns
        .where((c) => c.isRunning)
        .toList();
  }

  List<Campaign> get upcomingCampaigns {
    return state.campaigns
        .where((c) => c.isUpcoming)
        .toList();
  }
}

// Providers
final campaignServiceProvider = Provider<CampaignService>((ref) {
  return CampaignService();
});

final campaignProvider = StateNotifierProvider<CampaignNotifier, CampaignState>((ref) {
  final campaignService = ref.watch(campaignServiceProvider);
  return CampaignNotifier(campaignService);
});

// Helper providers
final availableCampaignsProvider = Provider<List<Campaign>>((ref) {
  return ref.watch(campaignProvider.notifier).availableCampaigns;
});

final currentCampaignProvider = Provider<Campaign?>((ref) {
  return ref.watch(campaignProvider).currentCampaign;
});

final hasCurrentCampaignProvider = Provider<bool>((ref) {
  return ref.watch(campaignProvider).currentCampaign != null;
});
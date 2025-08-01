import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/campaign_provider.dart';
import '../../../core/models/campaign.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../shared/widgets/loading_button.dart';
import '../widgets/campaign_card.dart';
import '../widgets/current_campaign_card.dart';
import 'campaign_details_screen.dart';

class CampaignListScreen extends ConsumerStatefulWidget {
  const CampaignListScreen({super.key});

  @override
  ConsumerState<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends ConsumerState<CampaignListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load campaigns when screen opens - but only if cache is stale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(campaignProvider.notifier).loadAvailableCampaigns(); // Will check cache freshness internally
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaignState = ref.watch(campaignProvider);
    final currentCampaign = campaignState.currentCampaign;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaigns'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(campaignProvider.notifier).refreshCampaigns();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(campaignProvider.notifier).loadAvailableCampaigns(forceRefresh: true);
        },
        child: Column(
          children: [
            // Current campaign section
            if (currentCampaign != null) ...[
              CurrentCampaignCard(
                campaign: currentCampaign,
                onLeaveGeofence: _showLeaveGeofenceDialog,
              ),
              const Divider(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Available Campaigns',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        ref.read(campaignProvider.notifier).refreshCampaigns();
                      },
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ],
            
            // Campaign list
            Expanded(
              child: _buildCampaignList(),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search campaigns...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: AppColors.inputBackground,
        ),
        onChanged: (value) {
          setState(() {});
          // Implement search functionality
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Available'),
        Tab(text: 'Running'),
        Tab(text: 'Upcoming'),
      ],
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.primary,
    );
  }

  Widget _buildCampaignList() {
    final campaignState = ref.watch(campaignProvider);
    final currentCampaign = campaignState.currentCampaign;
    
    if (campaignState.isLoading && campaignState.campaigns.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (campaignState.error != null && campaignState.campaigns.isEmpty) {
      return _buildErrorState(campaignState.error!);
    }
    
    // If user has current campaign, show simple list
    if (currentCampaign != null) {
      final availableCampaigns = ref.read(campaignProvider.notifier).availableCampaigns;
      return _buildCampaignTab(availableCampaigns);
    }
    
    // If no current campaign, show tabs with search
    return Column(
      children: [
        // Search bar
        _buildSearchBar(),
        // Tabs
        _buildTabBar(),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCampaignTab(ref.read(campaignProvider.notifier).availableCampaigns),
              _buildCampaignTab(ref.read(campaignProvider.notifier).runningCampaigns),
              _buildCampaignTab(ref.read(campaignProvider.notifier).upcomingCampaigns),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCampaignTab(List<Campaign> campaigns) {
    if (campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No campaigns available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull to refresh or check back later',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        final campaign = campaigns[index];
        return CampaignCard(
          campaign: campaign,
          onViewDetails: () => _showCampaignDetails(campaign),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load campaigns',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(campaignProvider.notifier).refreshCampaigns();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }


  void _showLeaveGeofenceDialog() {
    final currentCampaign = ref.read(campaignProvider).currentCampaign;
    final currentGeofence = ref.read(campaignProvider).currentGeofence;
    if (currentCampaign == null || currentGeofence == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Geofence'),
        content: Text(
          'Are you sure you want to leave "${currentGeofence.name ?? 'this geofence'}" in "${currentCampaign.name ?? 'this campaign'}"?\n\n'
          'You will stop earning from this geofence area and may need to reapply to join again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Consumer(
            builder: (context, ref, child) {
              final isJoining = ref.watch(campaignProvider).isJoining;
              return LoadingButton(
                onPressed: () async {
                  final success = await ref
                      .read(campaignProvider.notifier)
                      .leaveCurrentGeofence();
                  
                  if (success && mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully left geofence'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                isLoading: isJoining,
                backgroundColor: AppColors.error,
                minimumSize: const Size(100, 40),
                child: const Text('Leave'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCampaignDetails(Campaign campaign) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CampaignDetailsScreen(campaign: campaign),
      ),
    );
  }


  Widget _buildDetailedCampaignInfo(Campaign campaign) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campaign image/sticker preview
        if (campaign.stickerImageUrl?.isNotEmpty ?? false)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(campaign.stickerImageUrl ?? ''),
                fit: BoxFit.cover,
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Campaign name and description
        Text(
          campaign.name ?? 'Unnamed Campaign',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          campaign.description??'',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        
        const SizedBox(height: 24),
        
        // Key details
        _buildDetailRow('Rate per KM', '${AppConstants.currencySymbol}${(campaign.ratePerKm ?? 0.0).toStringAsFixed(0)}'),
        _buildDetailRow('Area', campaign.area??''),
        _buildDetailRow('Duration', '${campaign.startDate?.day ?? 'TBD'}/${campaign.startDate?.month ?? 'TBD'} - ${campaign.endDate?.day ?? 'TBD'}/${campaign.endDate?.month ?? 'TBD'}'),
        _buildDetailRow('Available Slots', '${campaign.availableSlots ?? 0} of ${campaign.maxRiders ?? 0}'),
        _buildDetailRow('Estimated Weekly Earnings', '${AppConstants.currencySymbol}${(campaign.estimatedWeeklyEarnings ?? 0.0).toStringAsFixed(0)}'),
        
        const SizedBox(height: 24),
        
        // Join button
        //if (campaign.canJoin)
          //LoadingButton(
            //onPressed: () async {
              //Navigator.of(context).pop();
              //_showJoinCampaignDialog(campaign);
            //},
            //child: const Text('JOIN THIS CAMPAIGN'),
          //),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
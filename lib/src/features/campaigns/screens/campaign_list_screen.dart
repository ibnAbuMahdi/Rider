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
            // Current campaign section - only show if campaign has active geofences
            if (currentCampaign != null && currentCampaign.hasActiveGeofenceAssignments) ...[
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
    
    print('🎯 DEBUG: _showLeaveGeofenceDialog called');
    print('🎯 DEBUG: currentCampaign = ${currentCampaign?.name ?? 'null'}');
    print('🎯 DEBUG: currentGeofence = ${currentGeofence?.name ?? 'null'}');
    
    if (currentCampaign == null) {
      print('🎯 DEBUG: Dialog blocked - no currentCampaign');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active campaign found. Please refresh.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (currentGeofence == null) {
      print('🎯 DEBUG: No currentGeofence found');
      print('🎯 DEBUG: currentCampaign activeGeofences: ${currentCampaign.activeGeofences.map((g) => g.geofenceName).toList()}');
      
      // Try to get the first active geofence from the campaign if currentGeofence is null
      if (currentCampaign.activeGeofences.isNotEmpty) {
        print('🎯 DEBUG: Using first active geofence from campaign');
        final firstActiveGeofenceAssignment = currentCampaign.activeGeofences.first;
        _showGeofenceLeaveDialogByAssignment(currentCampaign, firstActiveGeofenceAssignment);
        return;
      }
      
      print('🎯 DEBUG: No active geofences found - showing generic campaign leave dialog');
      // Fallback: Show campaign leave dialog instead of geofence-specific dialog
      //_showLeaveCampaignDialog(currentCampaign);
      return;
    }
    
    _showGeofenceLeaveDialog(currentCampaign, currentGeofence);
  }

  void _showGeofenceLeaveDialogByAssignment(Campaign campaign, GeofenceAssignment geofenceAssignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Geofence'),
        content: Text(
          'Are you sure you want to leave "${geofenceAssignment.geofenceName}" in "${campaign.name ?? 'this campaign'}"?\n\n'
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
              print('🎯 UI DEBUG: Button builder - isJoining = $isJoining');
              return ElevatedButton(
                onPressed: isJoining ? null : () async {
                  try {
                    print('🎯 UI DEBUG: Leave button pressed');
                    // Use the geofence ID from the assignment
                    final campaignNotifier = ref.read(campaignProvider.notifier);
                    print('🎯 UI DEBUG: About to call leaveSpecificGeofence');
                    final success = await campaignNotifier.leaveSpecificGeofence(geofenceAssignment.geofenceId);
                    print('🎯 UI DEBUG: leaveSpecificGeofence call completed');
                    
                    print('🎯 UI DEBUG: leaveSpecificGeofence returned success = $success');
                    print('🎯 UI DEBUG: mounted = $mounted');
                    
                    if (success && mounted) {
                      print('🎯 UI DEBUG: Closing dialog and showing success snackbar');
                      Navigator.of(context).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully left geofence'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      
                      // Force UI rebuild by calling setState if needed
                      if (mounted) {
                        setState(() {});
                      }
                    } else {
                      print('🎯 UI DEBUG: Dialog NOT closing - success=$success, mounted=$mounted');
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to leave geofence'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print('🎯 UI DEBUG: Exception in leave button callback: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  minimumSize: const Size(100, 40),
                ),
                child: isJoining 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Leave', style: TextStyle(color: Colors.white)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showGeofenceLeaveDialog(Campaign campaign, Geofence geofence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Geofence'),
        content: Text(
          'Are you sure you want to leave "${geofence.name ?? 'this geofence'}" in "${campaign.name ?? 'this campaign'}"?\n\n'
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
              print('🎯 UI DEBUG: Dialog button builder - isJoining = $isJoining');
              return ElevatedButton(
                onPressed: isJoining ? null : () async {
                  try {
                    print('🎯 UI DEBUG: Leave button pressed in _showGeofenceLeaveDialog');
                    // Create a temporary state with the geofence we want to leave
                    final campaignNotifier = ref.read(campaignProvider.notifier);
                    print('🎯 UI DEBUG: About to call leaveSpecificGeofence with ${geofence.id}');
                    final success = await campaignNotifier.leaveSpecificGeofence(geofence.id);
                    print('🎯 UI DEBUG: leaveSpecificGeofence call completed with success = $success');
                    
                    print('🎯 UI DEBUG: mounted = $mounted');
                    
                    if (success && mounted) {
                      print('🎯 UI DEBUG: Closing dialog and showing success snackbar');
                      Navigator.of(context).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully left geofence'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      
                      // Force UI rebuild by calling setState if needed
                      if (mounted) {
                        setState(() {});
                      }
                    } else {
                      print('🎯 UI DEBUG: Dialog NOT closing - success=$success, mounted=$mounted');
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to leave geofence'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print('🎯 UI DEBUG: Exception in leave button callback: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  minimumSize: const Size(100, 40),
                ),
                child: isJoining 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Leave', style: TextStyle(color: Colors.white)),
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

  void _showLeaveCampaignDialog(Campaign campaign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Campaign'),
        content: Text(
          'Are you sure you want to leave "${campaign.name ?? 'this campaign'}"?\n\n'
          'You will stop earning from this campaign and may need to reapply to join again.',
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
                      .leaveCampaign();
                  
                  if (success && mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully left campaign'),
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/enhanced_earnings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/campaign_earnings.dart';
import '../widgets/earnings_summary_card.dart';
import '../widgets/campaign_assignment_card.dart';
import '../widgets/payment_request_bottom_sheet.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'all'; // 'all', 'active', 'completed'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Load data on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshEarnings();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Load more assignments when scrolling near the end
      ref.read(campaignAssignmentsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final earningsOverview = ref.watch(earningsOverviewProvider);
    final campaignAssignments = ref.watch(campaignAssignmentsProvider);
    final isLoading = ref.watch(earningsLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Earnings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          // Filter button
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
              _applyFilter(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Assignments'),
              ),
              const PopupMenuItem(
                value: 'active',
                child: Text('Active Only'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Completed'),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _refreshEarnings(),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEarnings,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Summary Card
            if (earningsOverview != null)
              SliverToBoxAdapter(
                child: EarningsSummaryCard(overview: earningsOverview),
              ),
            
            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Campaign Earnings History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (campaignAssignments.isNotEmpty)
                      Text(
                        '${campaignAssignments.length} assignments',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Campaign assignments list
            if (isLoading && campaignAssignments.isEmpty)
              SliverToBoxAdapter(
                child: _buildLoadingState(),
              )
            else if (campaignAssignments.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == campaignAssignments.length) {
                      // Loading indicator at the end
                      return isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : const SizedBox.shrink();
                    }

                    final assignment = campaignAssignments[index];
                    return CampaignAssignmentCard(
                      assignment: assignment,
                      onTap: () => _showAssignmentDetails(context, assignment),
                    );
                  },
                  childCount: campaignAssignments.length + (isLoading ? 1 : 0),
                ),
              ),
            
            // Bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(earningsOverview, isLoading),
    );
  }

  Future<void> _refreshEarnings() async {
    await Future.wait([
      ref.read(earningsOverviewProvider.notifier).refresh(),
      ref.read(campaignAssignmentsProvider.notifier).refresh(),
    ]);
  }

  void _applyFilter(String filter) {
    ref.read(campaignAssignmentsProvider.notifier).applyFilter(filter);
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(64),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'active' 
                ? 'No Active Assignments'
                : _selectedFilter == 'completed'
                    ? 'No Completed Assignments'
                    : 'No Earnings Yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'active' 
                ? 'You currently have no active geofence assignments.'
                : _selectedFilter == 'completed'
                    ? 'You haven\'t completed any assignments yet.'
                    : 'Join campaigns and start earning!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_selectedFilter != 'completed')
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/campaigns'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Browse Campaigns'),
            ),
        ],
      ),
    );
  }

  void _showAssignmentDetails(BuildContext context, CampaignEarnings assignment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title and amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.campaignTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        assignment.geofenceName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  assignment.formattedTotalEarnings,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Details
            _buildDetailRow('Status', assignment.statusDisplay),
            _buildDetailRow('Rate', assignment.rateDisplay),
            _buildDetailRow('Time Worked', assignment.formattedTimeWorked),
            _buildDetailRow('Distance', assignment.formattedDistance),
            _buildDetailRow('Verifications', '${assignment.verificationsCompleted}'),
            _buildDetailRow('Joined', _formatDate(assignment.assignmentStartDate)),
            if (assignment.assignmentEndDate != null)
              _buildDetailRow('Left', _formatDate(assignment.assignmentEndDate!)),
            _buildDetailRow('Pending', assignment.formattedPendingAmount),
            _buildDetailRow('Paid', '₦${assignment.paidAmount.toStringAsFixed(2)}'),
            
            const SizedBox(height: 24),
            
            // Actions
            if (assignment.isCurrentlyActive) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/campaign-detail', arguments: assignment.campaignId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('View Campaign'),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showReportIssueDialog(context, assignment);
                      },
                      child: const Text('Report Issue'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/campaign-detail', arguments: assignment.campaignId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('View Campaign'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentRequestBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentRequestBottomSheet(
        availableAmount: ref.read(earningsOverviewProvider)?.pendingEarnings ?? 0.0,
      ),
    );
  }

  void _showReportIssueDialog(BuildContext context, CampaignEarnings assignment) {
    final TextEditingController descriptionController = TextEditingController();
    String selectedIssueType = 'incorrect_amount';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedIssueType,
              onChanged: (value) => selectedIssueType = value!,
              items: const [
                DropdownMenuItem(value: 'incorrect_amount', child: Text('Incorrect Amount')),
                DropdownMenuItem(value: 'missing_hours', child: Text('Missing Hours')),
                DropdownMenuItem(value: 'wrong_campaign', child: Text('Wrong Campaign')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              decoration: const InputDecoration(
                labelText: 'Issue Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'Describe the issue...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Submit issue report
              // ref.read(earningsServiceProvider).reportEarningIssue(...)
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(dynamic earningsOverview, bool isLoading) {
    // Don't show FAB while loading to prevent layout issues
    if (isLoading) {
      return null;
    }
    
    // Ensure earningsOverview is not null and has the required property
    if (earningsOverview == null) {
      return null;
    }
    
    // Safely check for pending payments with additional null safety
    try {
      if (earningsOverview.hasPendingPayments != true) {
        return null;
      }
    } catch (e) {
      // If there's any error accessing the property, don't show FAB
      return null;
    }
    
    return FloatingActionButton.extended(
      onPressed: () => _showPaymentRequestBottomSheet(context),
      backgroundColor: AppColors.success,
      icon: const Icon(Icons.payments, color: Colors.white),
      label: const Text(
        'Request Payment',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
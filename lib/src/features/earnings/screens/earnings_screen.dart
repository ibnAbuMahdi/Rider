import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/earnings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/earning.dart';
import '../widgets/earnings_summary_card.dart';
import '../widgets/earning_item_tile.dart';
import '../widgets/payment_request_bottom_sheet.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    
    // Load data on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(earningsProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(earningsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final earningsState = ref.watch(earningsProvider);
    final paymentSummary = ref.watch(paymentSummaryProvider);

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
          IconButton(
            onPressed: () => ref.read(earningsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(earningsProvider.notifier).refresh(),
        child: Column(
          children: [
            // Summary Section
            if (paymentSummary != null)
              EarningsSummaryCard(summary: paymentSummary),
            
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Paid'),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEarningsList(earningsState.earnings),
                  _buildEarningsList(ref.watch(pendingEarningsProvider)),
                  _buildEarningsList(ref.watch(paidEarningsProvider)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: paymentSummary != null && paymentSummary.pendingEarnings > 0
          ? FloatingActionButton.extended(
              onPressed: () => _showPaymentRequestBottomSheet(context),
              backgroundColor: AppColors.success,
              icon: const Icon(Icons.payments, color: Colors.white),
              label: const Text(
                'Request Payment',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildEarningsList(List<Earning> earnings) {
    if (earnings.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: earnings.length + 1, // +1 for loading indicator
      itemBuilder: (context, index) {
        if (index == earnings.length) {
          // Loading indicator at the end
          final earningsState = ref.watch(earningsProvider);
          return earningsState.isLoading && earningsState.hasMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox.shrink();
        }

        final earning = earnings[index];
        return EarningItemTile(
          earning: earning,
          onTap: () => _showEarningDetails(context, earning),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Earnings Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join campaigns and start earning!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
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

  void _showEarningDetails(BuildContext context, Earning earning) {
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
                Text(
                  earning.earningTypeDisplayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  earning.formattedAmount,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: earning.isPaid ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Details
            _buildDetailRow('Campaign', earning.campaignTitle),
            _buildDetailRow('Status', earning.statusDisplayName),
            _buildDetailRow('Period', 
              '${earning.periodStart.day}/${earning.periodStart.month} - ${earning.periodEnd.day}/${earning.periodEnd.month}'
            ),
            if (earning.hoursWorked != null)
              _buildDetailRow('Hours Worked', '${earning.hoursWorked!.toStringAsFixed(1)}h'),
            if (earning.verificationsCompleted != null)
              _buildDetailRow('Verifications', '${earning.verificationsCompleted}'),
            if (earning.paidAt != null)
              _buildDetailRow('Paid On', '${earning.paidAt!.day}/${earning.paidAt!.month}/${earning.paidAt!.year}'),
            if (earning.notes != null && earning.notes!.isNotEmpty)
              _buildDetailRow('Notes', earning.notes!),
            
            const SizedBox(height: 24),
            
            // Actions
            if (earning.isPending) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Report issue with earning
                    _showReportIssueDialog(context, earning);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Report Issue'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
        availableAmount: ref.read(totalPendingAmountProvider),
      ),
    );
  }

  void _showReportIssueDialog(BuildContext context, Earning earning) {
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
}
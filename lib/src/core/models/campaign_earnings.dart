import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'campaign_earnings.g.dart';

/// Enhanced earnings summary grouped by campaign geofence assignment
@HiveType(typeId: 10)
@JsonSerializable()
class CampaignEarnings {
  @HiveField(0)
  final String campaignId;
  
  @HiveField(1)
  final String campaignTitle;
  
  @HiveField(2)
  final String? campaignImageUrl;
  
  @HiveField(3)
  final String geofenceId;
  
  @HiveField(4)
  final String geofenceName;
  
  @HiveField(5)
  final String assignmentId; // Unique assignment ID for this geofence session
  
  @HiveField(6)
  final double totalEarned;
  
  @HiveField(7)
  final double thisWeekEarned;
  
  @HiveField(8)
  final double thisMonthEarned;
  
  @HiveField(9)
  final double pendingAmount;
  
  @HiveField(10)
  final double paidAmount;
  
  @HiveField(11)
  final int totalSessions;
  
  @HiveField(12)
  final Duration totalTimeWorked;
  
  @HiveField(13)
  final double totalDistanceCovered;
  
  @HiveField(14)
  final int verificationsCompleted;
  
  @HiveField(15)
  final DateTime assignmentStartDate; // When joined this geofence
  
  @HiveField(16)
  final DateTime? assignmentEndDate; // When left this geofence (null if still active)
  
  @HiveField(17)
  final DateTime? lastActiveDate;
  
  @HiveField(18)
  final DateTime? lastPaymentDate;
  
  @HiveField(19)
  final String rateType; // 'per_km', 'per_hour', 'fixed_daily', 'hybrid'
  
  @HiveField(20)
  final double ratePerKm;
  
  @HiveField(21)
  final double ratePerHour;
  
  @HiveField(22)
  final double fixedDailyRate;
  
  @HiveField(23)
  final String status; // 'active', 'completed', 'paused', 'left'
  
  @HiveField(24)
  final DateTime createdAt;
  
  @HiveField(25)
  final DateTime updatedAt;

  const CampaignEarnings({
    required this.campaignId,
    required this.campaignTitle,
    this.campaignImageUrl,
    required this.geofenceId,
    required this.geofenceName,
    required this.assignmentId,
    required this.totalEarned,
    required this.thisWeekEarned,
    required this.thisMonthEarned,
    required this.pendingAmount,
    required this.paidAmount,
    required this.totalSessions,
    required this.totalTimeWorked,
    required this.totalDistanceCovered,
    required this.verificationsCompleted,
    required this.assignmentStartDate,
    this.assignmentEndDate,
    this.lastActiveDate,
    this.lastPaymentDate,
    required this.rateType,
    required this.ratePerKm,
    required this.ratePerHour,
    required this.fixedDailyRate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CampaignEarnings.fromJson(Map<String, dynamic> json) =>
      _$CampaignEarningsFromJson(json);

  Map<String, dynamic> toJson() => _$CampaignEarningsToJson(this);

  /// Get formatted total earnings
  String get formattedTotalEarnings => '₦${totalEarned.toStringAsFixed(2)}';
  
  /// Get formatted pending amount
  String get formattedPendingAmount => '₦${pendingAmount.toStringAsFixed(2)}';
  
  /// Get formatted this week earnings
  String get formattedWeeklyEarnings => '₦${thisWeekEarned.toStringAsFixed(2)}';
  
  /// Get formatted this month earnings
  String get formattedMonthlyEarnings => '₦${thisMonthEarned.toStringAsFixed(2)}';
  
  /// Get formatted time worked
  String get formattedTimeWorked {
    final hours = totalTimeWorked.inHours;
    final minutes = totalTimeWorked.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
  
  /// Get formatted distance
  String get formattedDistance => '${totalDistanceCovered.toStringAsFixed(1)} km';
  
  /// Check if campaign is currently active
  bool get isActive => status == 'active';
  
  /// Check if assignment is currently active
  bool get isCurrentlyActive => status == 'active' && assignmentEndDate == null;
  
  /// Check if has recent activity (last 7 days)
  bool get hasRecentActivity {
    if (lastActiveDate == null) return false;
    return DateTime.now().difference(lastActiveDate!).inDays <= 7;
  }
  
  /// Get assignment duration
  Duration get assignmentDuration {
    final endDate = assignmentEndDate ?? DateTime.now();
    return endDate.difference(assignmentStartDate);
  }
  
  /// Get formatted assignment duration
  String get formattedAssignmentDuration {
    final duration = assignmentDuration;
    final days = duration.inDays;
    if (days > 0) {
      return '${days}d';
    } else {
      final hours = duration.inHours;
      return '${hours}h';
    }
  }
  
  /// Get earnings rate per hour
  double get earningsPerHour {
    final hours = totalTimeWorked.inHours;
    if (hours == 0) return 0;
    return totalEarned / hours;
  }
  
  /// Get formatted earnings rate
  String get formattedEarningsRate => '₦${earningsPerHour.toStringAsFixed(0)}/hr';
  
  /// Get verification completion rate
  double get verificationRate {
    if (totalSessions == 0) return 0;
    return verificationsCompleted / totalSessions;
  }
  
  /// Get rate display based on rate type
  String get rateDisplay {
    switch (rateType) {
      case 'per_km':
        return '₦${ratePerKm.toStringAsFixed(0)}/km';
      case 'per_hour':
        return '₦${ratePerHour.toStringAsFixed(0)}/hr';
      case 'fixed_daily':
        return '₦${fixedDailyRate.toStringAsFixed(0)}/day';
      case 'hybrid':
        return '₦${ratePerKm.toStringAsFixed(0)}/km + ₦${ratePerHour.toStringAsFixed(0)}/hr';
      default:
        return 'Mixed rates';
    }
  }
  
  /// Get status display text
  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'paused':
        return 'Paused';
      case 'left':
        return 'Left';
      default:
        return 'Unknown';
    }
  }
  
  /// Get status color
  String get statusColor {
    switch (status) {
      case 'active':
        return 'green';
      case 'completed':
        return 'blue';
      case 'paused':
        return 'orange';
      case 'left':
        return 'grey';
      default:
        return 'grey';
    }
  }
}

/// Summary of all earnings from a campaign across all geofence assignments
@HiveType(typeId: 12)
@JsonSerializable()
class CampaignSummary {
  @HiveField(0)
  final String campaignId;
  
  @HiveField(1)
  final String campaignTitle;
  
  @HiveField(2)
  final String? campaignImageUrl;
  
  @HiveField(3)
  final double totalEarned;
  
  @HiveField(4)
  final double pendingAmount;
  
  @HiveField(5)
  final double paidAmount;
  
  @HiveField(6)
  final int totalAssignments; // Number of geofence assignments
  
  @HiveField(7)
  final int activeAssignments; // Currently active assignments
  
  @HiveField(8)
  final List<CampaignEarnings> geofenceAssignments;
  
  @HiveField(9)
  final DateTime firstJoinedDate;
  
  @HiveField(10)
  final DateTime? lastActiveDate;
  
  @HiveField(11)
  final String status; // 'active', 'completed', 'inactive'
  
  @HiveField(12)
  final DateTime updatedAt;

  const CampaignSummary({
    required this.campaignId,
    required this.campaignTitle,
    this.campaignImageUrl,
    required this.totalEarned,
    required this.pendingAmount,
    required this.paidAmount,
    required this.totalAssignments,
    required this.activeAssignments,
    required this.geofenceAssignments,
    required this.firstJoinedDate,
    this.lastActiveDate,
    required this.status,
    required this.updatedAt,
  });

  factory CampaignSummary.fromJson(Map<String, dynamic> json) =>
      _$CampaignSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$CampaignSummaryToJson(this);

  /// Get formatted total earnings
  String get formattedTotalEarnings => '₦${totalEarned.toStringAsFixed(2)}';
  
  /// Get formatted pending amount
  String get formattedPendingAmount => '₦${pendingAmount.toStringAsFixed(2)}';
  
  /// Check if campaign has active assignments
  bool get hasActiveAssignments => activeAssignments > 0;
  
  /// Get unique geofences the rider has worked in
  List<String> get uniqueGeofences {
    final geofenceIds = <String>{};
    for (final assignment in geofenceAssignments) {
      geofenceIds.add(assignment.geofenceId);
    }
    return geofenceIds.toList();
  }
  
  /// Get current active geofence assignments
  List<CampaignEarnings> get currentActiveAssignments {
    return geofenceAssignments.where((assignment) => assignment.isCurrentlyActive).toList();
  }
  
  /// Get completed assignments
  List<CampaignEarnings> get completedAssignments {
    return geofenceAssignments.where((assignment) => assignment.status == 'completed' || assignment.status == 'left').toList();
  }
  
  /// Get most profitable assignment
  CampaignEarnings? get mostProfitableAssignment {
    if (geofenceAssignments.isEmpty) return null;
    return geofenceAssignments.reduce((a, b) => a.totalEarned > b.totalEarned ? a : b);
  }
  
  /// Get status display text
  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'inactive':
        return 'Inactive';
      default:
        return 'Unknown';
    }
  }
}

/// Enhanced earnings overview with analytics
@HiveType(typeId: 11)
@JsonSerializable()
class EarningsOverview {
  @HiveField(0)
  final double totalEarnings;
  
  @HiveField(1)
  final double pendingEarnings;
  
  @HiveField(2)
  final double paidEarnings;
  
  @HiveField(3)
  final double thisWeekEarnings;
  
  @HiveField(4)
  final double thisMonthEarnings;
  
  @HiveField(5)
  final double lastWeekEarnings;
  
  @HiveField(6)
  final double lastMonthEarnings;
  
  @HiveField(7)
  final int activeCampaignsCount;
  
  @HiveField(8)
  final int totalCampaignsCount;
  
  @HiveField(9)
  final Duration totalTimeWorked;
  
  @HiveField(10)
  final double totalDistanceCovered;
  
  @HiveField(11)
  final int totalVerifications;
  
  @HiveField(12)
  final int totalSessions;
  
  @HiveField(13)
  final DateTime? nextPaymentDate;
  
  @HiveField(14)
  final String topPerformingCampaign;
  
  @HiveField(15)
  final double averageDailyEarnings;
  
  @HiveField(16)
  final List<double> weeklyTrend; // Last 7 days earnings
  
  @HiveField(17)
  final DateTime updatedAt;

  const EarningsOverview({
    required this.totalEarnings,
    required this.pendingEarnings,
    required this.paidEarnings,
    required this.thisWeekEarnings,
    required this.thisMonthEarnings,
    required this.lastWeekEarnings,
    required this.lastMonthEarnings,
    required this.activeCampaignsCount,
    required this.totalCampaignsCount,
    required this.totalTimeWorked,
    required this.totalDistanceCovered,
    required this.totalVerifications,
    required this.totalSessions,
    this.nextPaymentDate,
    required this.topPerformingCampaign,
    required this.averageDailyEarnings,
    required this.weeklyTrend,
    required this.updatedAt,
  });

  factory EarningsOverview.fromJson(Map<String, dynamic> json) =>
      _$EarningsOverviewFromJson(json);

  Map<String, dynamic> toJson() => _$EarningsOverviewToJson(this);

  /// Get formatted total earnings
  String get formattedTotalEarnings => '₦${totalEarnings.toStringAsFixed(2)}';
  
  /// Get formatted pending earnings
  String get formattedPendingEarnings => '₦${pendingEarnings.toStringAsFixed(2)}';
  
  /// Get weekly growth percentage
  double get weeklyGrowthPercentage {
    if (lastWeekEarnings == 0) return thisWeekEarnings > 0 ? 100 : 0;
    return ((thisWeekEarnings - lastWeekEarnings) / lastWeekEarnings) * 100;
  }
  
  /// Get monthly growth percentage
  double get monthlyGrowthPercentage {
    if (lastMonthEarnings == 0) return thisMonthEarnings > 0 ? 100 : 0;
    return ((thisMonthEarnings - lastMonthEarnings) / lastMonthEarnings) * 100;
  }
  
  /// Check if weekly earnings are growing
  bool get isWeeklyGrowing => weeklyGrowthPercentage > 0;
  
  /// Check if monthly earnings are growing
  bool get isMonthlyGrowing => monthlyGrowthPercentage > 0;
  
  /// Get earnings rate per hour
  double get earningsPerHour {
    final hours = totalTimeWorked.inHours;
    if (hours == 0) return 0;
    return totalEarnings / hours;
  }
  
  /// Get verification completion rate
  double get verificationRate {
    if (totalSessions == 0) return 0;
    return totalVerifications / totalSessions;
  }
  
  /// Check if has pending payments
  bool get hasPendingPayments => pendingEarnings > 0;
  
  /// Get days until next payment
  int? get daysUntilNextPayment {
    if (nextPaymentDate == null) return null;
    return nextPaymentDate!.difference(DateTime.now()).inDays;
  }
}
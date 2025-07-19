import 'earning.dart';

class PaymentSummary {
  final double totalEarnings;
  final double pendingEarnings;
  final double paidEarnings;
  final double thisWeekEarnings;
  final double thisMonthEarnings;
  final int totalHours;
  final int totalVerifications;
  final int activeCampaigns;
  final DateTime lastPayment;
  final String preferredPaymentMethod;
  final List<Earning> recentEarnings;

  const PaymentSummary({
    required this.totalEarnings,
    required this.pendingEarnings,
    required this.paidEarnings,
    required this.thisWeekEarnings,
    required this.thisMonthEarnings,
    required this.totalHours,
    required this.totalVerifications,
    required this.activeCampaigns,
    required this.lastPayment,
    required this.preferredPaymentMethod,
    required this.recentEarnings,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      pendingEarnings: (json['pending_earnings'] as num?)?.toDouble() ?? 0.0,
      paidEarnings: (json['paid_earnings'] as num?)?.toDouble() ?? 0.0,
      thisWeekEarnings: (json['this_week_earnings'] as num?)?.toDouble() ?? 0.0,
      thisMonthEarnings: (json['this_month_earnings'] as num?)?.toDouble() ?? 0.0,
      totalHours: json['total_hours'] as int? ?? 0,
      totalVerifications: json['total_verifications'] as int? ?? 0,
      activeCampaigns: json['active_campaigns'] as int? ?? 0,
      lastPayment: DateTime.tryParse(json['last_payment']?.toString() ?? '') ?? DateTime.now(),
      preferredPaymentMethod: json['preferred_payment_method']?.toString() ?? 'bank_transfer',
      recentEarnings: (json['recent_earnings'] as List?)
          ?.map((e) => Earning.fromJson(e))
          .toList() ?? [],
    );
  }

  String get formattedTotalEarnings => '₦${totalEarnings.toStringAsFixed(0)}';
  String get formattedPendingEarnings => '₦${pendingEarnings.toStringAsFixed(0)}';
  String get formattedPaidEarnings => '₦${paidEarnings.toStringAsFixed(0)}';
  String get formattedThisWeekEarnings => '₦${thisWeekEarnings.toStringAsFixed(0)}';
  String get formattedThisMonthEarnings => '₦${thisMonthEarnings.toStringAsFixed(0)}';

  double get averageHourlyRate => totalHours > 0 ? totalEarnings / totalHours : 0.0;
  String get formattedAverageHourlyRate => '₦${averageHourlyRate.toStringAsFixed(0)}/hr';
}
import 'package:hive/hive.dart';

part 'earning.g.dart';

@HiveType(typeId: 6)
class Earning extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String riderId;

  @HiveField(2)
  final String campaignId;

  @HiveField(3)
  final String campaignTitle;

  @HiveField(4)
  final double amount;

  @HiveField(5)
  final String currency;

  @HiveField(6)
  final String earningType; // 'hourly', 'verification', 'bonus', 'penalty'

  @HiveField(7)
  final DateTime periodStart;

  @HiveField(8)
  final DateTime periodEnd;

  @HiveField(9)
  final String status; // 'pending', 'processing', 'paid', 'cancelled'

  @HiveField(10)
  final Map<String, dynamic> metadata;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime? paidAt;

  @HiveField(13)
  final String? paymentMethod;

  @HiveField(14)
  final String? paymentReference;

  @HiveField(15)
  final String? notes;

  @HiveField(16)
  final double? hoursWorked;

  @HiveField(17)
  final int? verificationsCompleted;

  @HiveField(18)
  final double? distanceCovered;

  @HiveField(19)
  final bool isSynced;

  Earning({
    required this.id,
    required this.riderId,
    required this.campaignId,
    required this.campaignTitle,
    required this.amount,
    this.currency = 'NGN',
    required this.earningType,
    required this.periodStart,
    required this.periodEnd,
    this.status = 'pending',
    this.metadata = const {},
    required this.createdAt,
    this.paidAt,
    this.paymentMethod,
    this.paymentReference,
    this.notes,
    this.hoursWorked,
    this.verificationsCompleted,
    this.distanceCovered,
    this.isSynced = false,
  });

  factory Earning.fromJson(Map<String, dynamic> json) {
    return Earning(
      id: json['id']?.toString() ?? '',
      riderId: json['rider_id']?.toString() ?? '',
      campaignId: json['campaign_id']?.toString() ?? '',
      campaignTitle: json['campaign_title']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'NGN',
      earningType: json['earning_type']?.toString() ?? 'hourly',
      periodStart: DateTime.tryParse(json['period_start']?.toString() ?? '') ?? DateTime.now(),
      periodEnd: DateTime.tryParse(json['period_end']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'].toString()) : null,
      paymentMethod: json['payment_method']?.toString(),
      paymentReference: json['payment_reference']?.toString(),
      notes: json['notes']?.toString(),
      hoursWorked: (json['hours_worked'] as num?)?.toDouble(),
      verificationsCompleted: json['verifications_completed'] as int?,
      distanceCovered: (json['distance_covered'] as num?)?.toDouble(),
      isSynced: json['is_synced'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rider_id': riderId,
      'campaign_id': campaignId,
      'campaign_title': campaignTitle,
      'amount': amount,
      'currency': currency,
      'earning_type': earningType,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'status': status,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'notes': notes,
      'hours_worked': hoursWorked,
      'verifications_completed': verificationsCompleted,
      'distance_covered': distanceCovered,
      'is_synced': isSynced,
    };
  }

  Earning copyWith({
    String? id,
    String? riderId,
    String? campaignId,
    String? campaignTitle,
    double? amount,
    String? currency,
    String? earningType,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? status,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? paidAt,
    String? paymentMethod,
    String? paymentReference,
    String? notes,
    double? hoursWorked,
    int? verificationsCompleted,
    double? distanceCovered,
    bool? isSynced,
  }) {
    return Earning(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      campaignId: campaignId ?? this.campaignId,
      campaignTitle: campaignTitle ?? this.campaignTitle,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      earningType: earningType ?? this.earningType,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      notes: notes ?? this.notes,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      verificationsCompleted: verificationsCompleted ?? this.verificationsCompleted,
      distanceCovered: distanceCovered ?? this.distanceCovered,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // Helper getters
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isPaid => status == 'paid';
  bool get isCancelled => status == 'cancelled';

  String get formattedAmount => '₦${amount.toStringAsFixed(0)}';
  
  String get earningTypeDisplayName {
    switch (earningType) {
      case 'hourly':
        return 'Hourly Rate';
      case 'verification':
        return 'Verification';
      case 'bonus':
        return 'Bonus';
      case 'penalty':
        return 'Penalty';
      default:
        return earningType;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'paid':
        return 'Paid';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Duration get periodDuration => periodEnd.difference(periodStart);

  @override
  String toString() {
    return 'Earning{id: $id, campaignTitle: $campaignTitle, amount: $formattedAmount, status: $status}';
  }
}
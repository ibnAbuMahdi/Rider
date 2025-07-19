import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rider.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Rider {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String phoneNumber;
  
  @HiveField(2)
  final String? firstName;
  
  @HiveField(3)
  final String? lastName;
  
  @HiveField(4)
  final String? profileImageUrl;
  
  @HiveField(5)
  final bool isActive;
  
  @HiveField(6)
  final bool isVerified;
  
  @HiveField(7)
  final String? fleetOwnerId;
  
  @HiveField(8)
  final String? deviceId;
  
  @HiveField(9)
  final DateTime createdAt;
  
  @HiveField(10)
  final DateTime? lastActiveAt;
  
  @HiveField(11)
  final double totalEarnings;
  
  @HiveField(12)
  final double availableBalance;
  
  @HiveField(13)
  final double pendingBalance;
  
  @HiveField(14)
  final int totalCampaigns;
  
  @HiveField(15)
  final int totalVerifications;
  
  @HiveField(16)
  final double averageRating;
  
  @HiveField(17)
  final String? referralCode;
  
  @HiveField(18)
  final Map<String, dynamic>? settings;
  
  @HiveField(19)
  final bool hasCompletedOnboarding;
  
  @HiveField(20)
  final String? currentCampaignId;
  
  @HiveField(21)
  final DateTime? lastSyncAt;
  
  @HiveField(22)
  final List<String> suspiciousActivities;
  
  @HiveField(23)
  final double riskScore;
  
  @HiveField(24)
  final String? bankAccountNumber;
  
  @HiveField(25)
  final String? bankCode;
  
  @HiveField(26)
  final String? bankAccountName;

  const Rider({
    required this.id,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
    this.profileImageUrl,
    this.isActive = false,
    this.isVerified = false,
    this.fleetOwnerId,
    this.deviceId,
    required this.createdAt,
    this.lastActiveAt,
    this.totalEarnings = 0.0,
    this.availableBalance = 0.0,
    this.pendingBalance = 0.0,
    this.totalCampaigns = 0,
    this.totalVerifications = 0,
    this.averageRating = 0.0,
    this.referralCode,
    this.settings,
    this.hasCompletedOnboarding = false,
    this.currentCampaignId,
    this.lastSyncAt,
    this.suspiciousActivities = const [],
    this.riskScore = 0.0,
    this.bankAccountNumber,
    this.bankCode,
    this.bankAccountName,
  });

  factory Rider.fromJson(Map<String, dynamic> json) => _$RiderFromJson(json);
  Map<String, dynamic> toJson() => _$RiderToJson(this);

  Rider copyWith({
    String? id,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    bool? isActive,
    bool? isVerified,
    String? fleetOwnerId,
    String? deviceId,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    double? totalEarnings,
    double? availableBalance,
    double? pendingBalance,
    int? totalCampaigns,
    int? totalVerifications,
    double? averageRating,
    String? referralCode,
    Map<String, dynamic>? settings,
    bool? hasCompletedOnboarding,
    String? currentCampaignId,
    DateTime? lastSyncAt,
    List<String>? suspiciousActivities,
    double? riskScore,
    String? bankAccountNumber,
    String? bankCode,
    String? bankAccountName,
  }) {
    return Rider(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      fleetOwnerId: fleetOwnerId ?? this.fleetOwnerId,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalCampaigns: totalCampaigns ?? this.totalCampaigns,
      totalVerifications: totalVerifications ?? this.totalVerifications,
      averageRating: averageRating ?? this.averageRating,
      referralCode: referralCode ?? this.referralCode,
      settings: settings ?? this.settings,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      currentCampaignId: currentCampaignId ?? this.currentCampaignId,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      suspiciousActivities: suspiciousActivities ?? this.suspiciousActivities,
      riskScore: riskScore ?? this.riskScore,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankCode: bankCode ?? this.bankCode,
      bankAccountName: bankAccountName ?? this.bankAccountName,
    );
  }

  // Getters
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? 'Rider';
  }

  String get displayName => fullName;

  String get phone => phoneNumber;

  bool get hasPaymentDetails {
    return bankAccountNumber != null && 
           bankCode != null && 
           bankAccountName != null;
  }

  bool get canReceivePayments => hasPaymentDetails && isVerified;

  double get weeklyEarnings {
    // This would be calculated based on recent transactions
    // For now, return a portion of total earnings
    return totalEarnings * 0.1; // Placeholder
  }

  double get todayEarnings {
    // This would be calculated based on today's transactions
    // For now, return a portion of weekly earnings
    return weeklyEarnings * 0.2; // Placeholder
  }

  bool get hasCurrentCampaign => currentCampaignId != null;

  bool get needsSync {
    if (lastSyncAt == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(lastSyncAt!);
    return difference.inHours > 1; // Sync if not synced in last hour
  }

  bool get isHighRisk => riskScore > 0.7;

  bool get isNewRider {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays < 7;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rider && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Rider{id: $id, phoneNumber: $phoneNumber, fullName: $fullName, isActive: $isActive}';
  }
}
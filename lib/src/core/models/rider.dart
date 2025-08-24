import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rider.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Rider {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  @JsonKey(name: 'phone_number') // Map to backend field name
  final String phoneNumber;
  
  @HiveField(2)
  @JsonKey(name: 'first_name') // Map to backend field name
  final String? firstName;
  
  @HiveField(3)
  @JsonKey(name: 'last_name') // Map to backend field name
  final String? lastName;
  
  @HiveField(4)
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;
  
  @HiveField(5)
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @HiveField(6)
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  
  @HiveField(7)
  @JsonKey(name: 'fleet_owner_id')
  final String? fleetOwnerId;
  
  @HiveField(8)
  @JsonKey(name: 'device_id')
  final String? deviceId;
  
  @HiveField(9)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @HiveField(10)
  @JsonKey(name: 'last_active_at')
  final DateTime? lastActiveAt;
  
  @HiveField(11)
  @JsonKey(name: 'total_earnings')
  final double totalEarnings;
  
  @HiveField(12)
  @JsonKey(name: 'available_balance')
  final double availableBalance;
  
  @HiveField(13)
  @JsonKey(name: 'pending_balance')
  final double pendingBalance;
  
  @HiveField(14)
  @JsonKey(name: 'total_campaigns')
  final int totalCampaigns;
  
  @HiveField(15)
  @JsonKey(name: 'total_verifications')
  final int totalVerifications;
  
  @HiveField(16)
  @JsonKey(name: 'average_rating')
  final double averageRating;
  
  @HiveField(17)
  @JsonKey(name: 'referral_code')
  final String? referralCode;
  
  @HiveField(18)
  final Map<String, dynamic>? settings;
  
  @HiveField(19)
  @JsonKey(name: 'has_completed_onboarding')
  final bool hasCompletedOnboarding;
  
  @HiveField(20)
  @JsonKey(name: 'current_campaign_id')
  final String? currentCampaignId;
  
  @HiveField(21)
  @JsonKey(name: 'last_sync_at')
  final DateTime? lastSyncAt;
  
  @HiveField(22)
  @JsonKey(name: 'suspicious_activities')
  final List<String> suspiciousActivities;
  
  @HiveField(23)
  @JsonKey(name: 'risk_score')
  final double riskScore;
  
  @HiveField(24)
  @JsonKey(name: 'bank_account_number')
  final String? bankAccountNumber;
  
  @HiveField(25)
  @JsonKey(name: 'bank_code')
  final String? bankCode;
  
  @HiveField(26)
  @JsonKey(name: 'bank_account_name')
  final String? bankAccountName;

  // Additional fields that might come from backend
  @HiveField(27)
  @JsonKey(name: 'rider_id')
  final String? riderId; // Backend's STK-R-XXXXX format
  
  @HiveField(28)
  @JsonKey(name: 'status')
  final String? status; // pending, active, inactive, suspended
  
  @HiveField(29)
  @JsonKey(name: 'verification_status')
  final String? verificationStatus;
  
  @HiveField(30)
  @JsonKey(name: 'plate_number')
  final String? plateNumber;

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
    this.riderId,
    this.status,
    this.verificationStatus,
    this.plateNumber,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    // Handle date parsing with fallbacks
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    // Handle nullable DateTime parsing
    DateTime? parseNullableDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // Handle list parsing
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return [];
    }

    // Handle numeric parsing (supports both string and number inputs)
    double parseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return defaultValue;
        }
      }
      return defaultValue;
    }

    // Handle integer parsing (supports both string and number inputs)
    int parseInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toInt();
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return defaultValue;
        }
      }
      return defaultValue;
    }

    return Rider(
      id: json['id']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? json['phone']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      profileImageUrl: json['profile_image_url']?.toString(),
      isActive: json['is_active'] == true,
      isVerified: json['is_verified'] == true,
      fleetOwnerId: json['fleet_owner_id']?.toString(),
      deviceId: json['device_id']?.toString(),
      createdAt: parseDateTime(json['created_at']),
      lastActiveAt: parseNullableDateTime(json['last_active_at']),
      totalEarnings: parseDouble(json['total_earnings']),
      availableBalance: parseDouble(json['available_balance']),
      pendingBalance: parseDouble(json['pending_balance'] ?? json['pending_earnings']),
      totalCampaigns: parseInt(json['total_campaigns']),
      totalVerifications: parseInt(json['total_verifications']),
      averageRating: parseDouble(json['average_rating'] ?? json['rating']),
      referralCode: json['referral_code']?.toString(),
      settings: json['settings'] as Map<String, dynamic>?,
      hasCompletedOnboarding: json['has_completed_onboarding'] == true,
      currentCampaignId: json['current_campaign_id']?.toString(),
      lastSyncAt: parseNullableDateTime(json['last_sync_at']),
      suspiciousActivities: parseStringList(json['suspicious_activities']),
      riskScore: parseDouble(json['risk_score']),
      bankAccountNumber: json['bank_account_number']?.toString(),
      bankCode: json['bank_code']?.toString(),
      bankAccountName: json['bank_account_name']?.toString(),
      riderId: json['rider_id']?.toString(),
      status: json['status']?.toString(),
      verificationStatus: json['verification_status']?.toString(),
      plateNumber: json['plate_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'profile_image_url': profileImageUrl,
      'is_active': isActive,
      'is_verified': isVerified,
      'fleet_owner_id': fleetOwnerId,
      'device_id': deviceId,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
      'total_earnings': totalEarnings,
      'available_balance': availableBalance,
      'pending_balance': pendingBalance,
      'total_campaigns': totalCampaigns,
      'total_verifications': totalVerifications,
      'average_rating': averageRating,
      'referral_code': referralCode,
      'settings': settings,
      'has_completed_onboarding': hasCompletedOnboarding,
      'current_campaign_id': currentCampaignId,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'suspicious_activities': suspiciousActivities,
      'risk_score': riskScore,
      'bank_account_number': bankAccountNumber,
      'bank_code': bankCode,
      'bank_account_name': bankAccountName,
      'rider_id': riderId,
      'status': status,
      'verification_status': verificationStatus,
      'plate_number': plateNumber,
    };
  }

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
    String? riderId,
    String? status,
    String? verificationStatus,
    String? plateNumber,
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
      riderId: riderId ?? this.riderId,
      status: status ?? this.status,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      plateNumber: plateNumber ?? this.plateNumber,
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

  // New getters for backend integration
  bool get isReadyForOnboarding => !hasCompletedOnboarding && isVerified;
  
  bool get canStartCampaigns => hasCompletedOnboarding && isVerified && isActive;
  
  String get statusDisplay {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending Verification';
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'suspended':
        return 'Suspended';
      default:
        return 'Unknown';
    }
  }
  
  String get verificationStatusDisplay {
    switch (verificationStatus?.toLowerCase()) {
      case 'unverified':
        return 'Not Verified';
      case 'pending':
        return 'Verification Pending';
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Verification Rejected';
      default:
        return 'Unknown';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rider && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Rider{id: $id, riderId: $riderId, phoneNumber: $phoneNumber, fullName: $fullName, isActive: $isActive, hasCompletedOnboarding: $hasCompletedOnboarding}';
  }
}

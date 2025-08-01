import 'dart:math';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location_record.g.dart';

@HiveType(typeId: 9)
@JsonSerializable()
class LocationRecord {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String riderId;
  
  @HiveField(2)
  final String? campaignId;
  
  @HiveField(3)
  final double latitude;
  
  @HiveField(4)
  final double longitude;
  
  @HiveField(5)
  final double accuracy;
  
  @HiveField(6)
  final double? speed; // km/h
  
  @HiveField(7)
  final double? heading; // degrees
  
  @HiveField(8)
  final double? altitude; // meters
  
  @HiveField(9)
  final DateTime timestamp;
  
  @HiveField(10)
  final bool isWorking;
  
  @HiveField(11)
  final bool isSynced;
  
  @HiveField(12)
  final DateTime createdAt;
  
  @HiveField(13)
  final Map<String, dynamic>? metadata;

  LocationRecord({
    required this.id,
    required this.riderId,
    this.campaignId,
    required this.latitude,
    required this.longitude,
    required double accuracy,
    this.speed,
    this.heading,
    this.altitude,
    required this.timestamp,
    this.isWorking = true,
    this.isSynced = false,
    required this.createdAt,
    this.metadata,
  }) : accuracy = _truncateAccuracy(accuracy);

  factory LocationRecord.fromJson(Map<String, dynamic> json) =>
      _$LocationRecordFromJson(json);
  Map<String, dynamic> toJson() => _$LocationRecordToJson(this);

  LocationRecord copyWith({
    String? id,
    String? riderId,
    String? campaignId,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? speed,
    double? heading,
    double? altitude,
    DateTime? timestamp,
    bool? isWorking,
    bool? isSynced,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return LocationRecord(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      campaignId: campaignId ?? this.campaignId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      altitude: altitude ?? this.altitude,
      timestamp: timestamp ?? this.timestamp,
      isWorking: isWorking ?? this.isWorking,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Calculate distance from another location in meters
  double distanceFrom(LocationRecord other) {
    return _calculateDistance(latitude, longitude, other.latitude, other.longitude);
  }

  // Calculate distance from coordinates in meters
  double distanceFromCoordinates(double lat, double lng) {
    return _calculateDistance(latitude, longitude, lat, lng);
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Truncates accuracy to 8 digits maximum
  /// This ensures accuracy values stay within reasonable bounds
  static double _truncateAccuracy(double accuracy) {
    // Convert to string with maximum 8 significant digits and back to double
    // For accuracy values (typically in meters), limit to 8 total digits
    final accuracyString = accuracy.toString();
    if (accuracyString.length <= 8) {
      return accuracy;
    }
    
    // If more than 8 digits, truncate to 8 characters
    final truncated = accuracyString.substring(0, 8);
    return double.tryParse(truncated) ?? accuracy;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LocationRecord{id: $id, lat: $latitude, lng: $longitude, timestamp: $timestamp}';
  }
}

@HiveType(typeId: 10)
@JsonSerializable()
class EarningsRecord {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String riderId;
  
  @HiveField(2)
  final String? campaignId;
  
  @HiveField(3)
  final String? campaignName;
  
  @HiveField(4)
  final double amount;
  
  @HiveField(5)
  final String currency;
  
  @HiveField(6)
  final EarningsType type;
  
  @HiveField(7)
  final DateTime earnedAt;
  
  @HiveField(8)
  final DateTime createdAt;
  
  @HiveField(9)
  final PaymentStatus paymentStatus;
  
  @HiveField(10)
  final DateTime? paidAt;
  
  @HiveField(11)
  final String? paymentReference;
  
  @HiveField(12)
  final double? distanceCovered; // km
  
  @HiveField(13)
  final int? verificationsCompleted;
  
  @HiveField(14)
  final bool isSynced;
  
  @HiveField(15)
  final Map<String, dynamic>? metadata;

  const EarningsRecord({
    required this.id,
    required this.riderId,
    this.campaignId,
    this.campaignName,
    required this.amount,
    this.currency = 'NGN',
    required this.type,
    required this.earnedAt,
    required this.createdAt,
    this.paymentStatus = PaymentStatus.pending,
    this.paidAt,
    this.paymentReference,
    this.distanceCovered,
    this.verificationsCompleted,
    this.isSynced = false,
    this.metadata,
  });

  factory EarningsRecord.fromJson(Map<String, dynamic> json) =>
      _$EarningsRecordFromJson(json);
  Map<String, dynamic> toJson() => _$EarningsRecordToJson(this);

  EarningsRecord copyWith({
    String? id,
    String? riderId,
    String? campaignId,
    String? campaignName,
    double? amount,
    String? currency,
    EarningsType? type,
    DateTime? earnedAt,
    DateTime? createdAt,
    PaymentStatus? paymentStatus,
    DateTime? paidAt,
    String? paymentReference,
    double? distanceCovered,
    int? verificationsCompleted,
    bool? isSynced,
    Map<String, dynamic>? metadata,
  }) {
    return EarningsRecord(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      campaignId: campaignId ?? this.campaignId,
      campaignName: campaignName ?? this.campaignName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      earnedAt: earnedAt ?? this.earnedAt,
      createdAt: createdAt ?? this.createdAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAt: paidAt ?? this.paidAt,
      paymentReference: paymentReference ?? this.paymentReference,
      distanceCovered: distanceCovered ?? this.distanceCovered,
      verificationsCompleted: verificationsCompleted ?? this.verificationsCompleted,
      isSynced: isSynced ?? this.isSynced,
      metadata: metadata ?? this.metadata,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case EarningsType.campaign:
        return 'Campaign';
      case EarningsType.bonus:
        return 'Bonus';
      case EarningsType.referral:
        return 'Referral';
      case EarningsType.correction:
        return 'Correction';
    }
  }

  String get statusDisplayName {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarningsRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EarningsRecord{id: $id, amount: $amount, type: $type, status: $paymentStatus}';
  }
}

@HiveType(typeId: 11)
enum EarningsType {
  @HiveField(0)
  campaign,
  
  @HiveField(1)
  bonus,
  
  @HiveField(2)
  referral,
  
  @HiveField(3)
  correction;
}

@HiveType(typeId: 12)
enum PaymentStatus {
  @HiveField(0)
  pending,
  
  @HiveField(1)
  processing,
  
  @HiveField(2)
  completed,
  
  @HiveField(3)
  failed,
  
  @HiveField(4)
  cancelled;
}

@HiveType(typeId: 13)
@JsonSerializable()
class PendingAction {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final ActionType type;
  
  @HiveField(2)
  final Map<String, dynamic> data;
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
  final int retryCount;
  
  @HiveField(5)
  final int priority; // 1 = highest, 5 = lowest

  const PendingAction({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.priority = 3,
  });

  factory PendingAction.fromJson(Map<String, dynamic> json) =>
      _$PendingActionFromJson(json);
  Map<String, dynamic> toJson() => _$PendingActionToJson(this);

  PendingAction copyWith({
    String? id,
    ActionType? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    int? priority,
  }) {
    return PendingAction(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      priority: priority ?? this.priority,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingAction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 14)
enum ActionType {
  @HiveField(0)
  syncVerification,
  
  @HiveField(1)
  syncLocation,
  
  @HiveField(2)
  syncEarnings,
  
  @HiveField(3)
  syncProfile,
  
  @HiveField(4)
  joinCampaign,
  
  @HiveField(5)
  leaveCampaign;
}
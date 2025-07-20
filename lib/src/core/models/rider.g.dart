// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rider.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RiderAdapter extends TypeAdapter<Rider> {
  @override
  final int typeId = 0;

  @override
  Rider read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Rider(
      id: fields[0] as String,
      phoneNumber: fields[1] as String,
      firstName: fields[2] as String?,
      lastName: fields[3] as String?,
      profileImageUrl: fields[4] as String?,
      isActive: fields[5] as bool,
      isVerified: fields[6] as bool,
      fleetOwnerId: fields[7] as String?,
      deviceId: fields[8] as String?,
      createdAt: fields[9] as DateTime,
      lastActiveAt: fields[10] as DateTime?,
      totalEarnings: fields[11] as double,
      availableBalance: fields[12] as double,
      pendingBalance: fields[13] as double,
      totalCampaigns: fields[14] as int,
      totalVerifications: fields[15] as int,
      averageRating: fields[16] as double,
      referralCode: fields[17] as String?,
      settings: (fields[18] as Map?)?.cast<String, dynamic>(),
      hasCompletedOnboarding: fields[19] as bool,
      currentCampaignId: fields[20] as String?,
      lastSyncAt: fields[21] as DateTime?,
      suspiciousActivities: (fields[22] as List).cast<String>(),
      riskScore: fields[23] as double,
      bankAccountNumber: fields[24] as String?,
      bankCode: fields[25] as String?,
      bankAccountName: fields[26] as String?,
      riderId: fields[27] as String?,
      status: fields[28] as String?,
      verificationStatus: fields[29] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Rider obj) {
    writer
      ..writeByte(30)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.phoneNumber)
      ..writeByte(2)
      ..write(obj.firstName)
      ..writeByte(3)
      ..write(obj.lastName)
      ..writeByte(4)
      ..write(obj.profileImageUrl)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.isVerified)
      ..writeByte(7)
      ..write(obj.fleetOwnerId)
      ..writeByte(8)
      ..write(obj.deviceId)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.lastActiveAt)
      ..writeByte(11)
      ..write(obj.totalEarnings)
      ..writeByte(12)
      ..write(obj.availableBalance)
      ..writeByte(13)
      ..write(obj.pendingBalance)
      ..writeByte(14)
      ..write(obj.totalCampaigns)
      ..writeByte(15)
      ..write(obj.totalVerifications)
      ..writeByte(16)
      ..write(obj.averageRating)
      ..writeByte(17)
      ..write(obj.referralCode)
      ..writeByte(18)
      ..write(obj.settings)
      ..writeByte(19)
      ..write(obj.hasCompletedOnboarding)
      ..writeByte(20)
      ..write(obj.currentCampaignId)
      ..writeByte(21)
      ..write(obj.lastSyncAt)
      ..writeByte(22)
      ..write(obj.suspiciousActivities)
      ..writeByte(23)
      ..write(obj.riskScore)
      ..writeByte(24)
      ..write(obj.bankAccountNumber)
      ..writeByte(25)
      ..write(obj.bankCode)
      ..writeByte(26)
      ..write(obj.bankAccountName)
      ..writeByte(27)
      ..write(obj.riderId)
      ..writeByte(28)
      ..write(obj.status)
      ..writeByte(29)
      ..write(obj.verificationStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Rider _$RiderFromJson(Map<String, dynamic> json) => Rider(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      fleetOwnerId: json['fleet_owner_id'] as String?,
      deviceId: json['device_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActiveAt: json['last_active_at'] == null
          ? null
          : DateTime.parse(json['last_active_at'] as String),
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (json['pending_balance'] as num?)?.toDouble() ?? 0.0,
      totalCampaigns: (json['total_campaigns'] as num?)?.toInt() ?? 0,
      totalVerifications: (json['total_verifications'] as num?)?.toInt() ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      referralCode: json['referral_code'] as String?,
      settings: json['settings'] as Map<String, dynamic>?,
      hasCompletedOnboarding:
          json['has_completed_onboarding'] as bool? ?? false,
      currentCampaignId: json['current_campaign_id'] as String?,
      lastSyncAt: json['last_sync_at'] == null
          ? null
          : DateTime.parse(json['last_sync_at'] as String),
      suspiciousActivities: (json['suspicious_activities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankCode: json['bank_code'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      riderId: json['rider_id'] as String?,
      status: json['status'] as String?,
      verificationStatus: json['verification_status'] as String?,
    );

Map<String, dynamic> _$RiderToJson(Rider instance) => <String, dynamic>{
      'id': instance.id,
      'phone_number': instance.phoneNumber,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'profile_image_url': instance.profileImageUrl,
      'is_active': instance.isActive,
      'is_verified': instance.isVerified,
      'fleet_owner_id': instance.fleetOwnerId,
      'device_id': instance.deviceId,
      'created_at': instance.createdAt.toIso8601String(),
      'last_active_at': instance.lastActiveAt?.toIso8601String(),
      'total_earnings': instance.totalEarnings,
      'available_balance': instance.availableBalance,
      'pending_balance': instance.pendingBalance,
      'total_campaigns': instance.totalCampaigns,
      'total_verifications': instance.totalVerifications,
      'average_rating': instance.averageRating,
      'referral_code': instance.referralCode,
      'settings': instance.settings,
      'has_completed_onboarding': instance.hasCompletedOnboarding,
      'current_campaign_id': instance.currentCampaignId,
      'last_sync_at': instance.lastSyncAt?.toIso8601String(),
      'suspicious_activities': instance.suspiciousActivities,
      'risk_score': instance.riskScore,
      'bank_account_number': instance.bankAccountNumber,
      'bank_code': instance.bankCode,
      'bank_account_name': instance.bankAccountName,
      'rider_id': instance.riderId,
      'status': instance.status,
      'verification_status': instance.verificationStatus,
    };

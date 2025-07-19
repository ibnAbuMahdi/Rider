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
    );
  }

  @override
  void write(BinaryWriter writer, Rider obj) {
    writer
      ..writeByte(27)
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
      ..write(obj.bankAccountName);
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
      phoneNumber: json['phoneNumber'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      fleetOwnerId: json['fleetOwnerId'] as String?,
      deviceId: json['deviceId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: json['lastActiveAt'] == null
          ? null
          : DateTime.parse(json['lastActiveAt'] as String),
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      availableBalance: (json['availableBalance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (json['pendingBalance'] as num?)?.toDouble() ?? 0.0,
      totalCampaigns: (json['totalCampaigns'] as num?)?.toInt() ?? 0,
      totalVerifications: (json['totalVerifications'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      referralCode: json['referralCode'] as String?,
      settings: json['settings'] as Map<String, dynamic>?,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      currentCampaignId: json['currentCampaignId'] as String?,
      lastSyncAt: json['lastSyncAt'] == null
          ? null
          : DateTime.parse(json['lastSyncAt'] as String),
      suspiciousActivities: (json['suspiciousActivities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      riskScore: (json['riskScore'] as num?)?.toDouble() ?? 0.0,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankCode: json['bankCode'] as String?,
      bankAccountName: json['bankAccountName'] as String?,
    );

Map<String, dynamic> _$RiderToJson(Rider instance) => <String, dynamic>{
      'id': instance.id,
      'phoneNumber': instance.phoneNumber,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'profileImageUrl': instance.profileImageUrl,
      'isActive': instance.isActive,
      'isVerified': instance.isVerified,
      'fleetOwnerId': instance.fleetOwnerId,
      'deviceId': instance.deviceId,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastActiveAt': instance.lastActiveAt?.toIso8601String(),
      'totalEarnings': instance.totalEarnings,
      'availableBalance': instance.availableBalance,
      'pendingBalance': instance.pendingBalance,
      'totalCampaigns': instance.totalCampaigns,
      'totalVerifications': instance.totalVerifications,
      'averageRating': instance.averageRating,
      'referralCode': instance.referralCode,
      'settings': instance.settings,
      'hasCompletedOnboarding': instance.hasCompletedOnboarding,
      'currentCampaignId': instance.currentCampaignId,
      'lastSyncAt': instance.lastSyncAt?.toIso8601String(),
      'suspiciousActivities': instance.suspiciousActivities,
      'riskScore': instance.riskScore,
      'bankAccountNumber': instance.bankAccountNumber,
      'bankCode': instance.bankCode,
      'bankAccountName': instance.bankAccountName,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocationRecordAdapter extends TypeAdapter<LocationRecord> {
  @override
  final int typeId = 9;

  @override
  LocationRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationRecord(
      id: fields[0] as String,
      riderId: fields[1] as String,
      campaignId: fields[2] as String?,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      accuracy: fields[5] as double,
      speed: fields[6] as double?,
      heading: fields[7] as double?,
      altitude: fields[8] as double?,
      timestamp: fields[9] as DateTime,
      isWorking: fields[10] as bool,
      isSynced: fields[11] as bool,
      createdAt: fields[12] as DateTime,
      metadata: (fields[13] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, LocationRecord obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.riderId)
      ..writeByte(2)
      ..write(obj.campaignId)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.accuracy)
      ..writeByte(6)
      ..write(obj.speed)
      ..writeByte(7)
      ..write(obj.heading)
      ..writeByte(8)
      ..write(obj.altitude)
      ..writeByte(9)
      ..write(obj.timestamp)
      ..writeByte(10)
      ..write(obj.isWorking)
      ..writeByte(11)
      ..write(obj.isSynced)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EarningsRecordAdapter extends TypeAdapter<EarningsRecord> {
  @override
  final int typeId = 10;

  @override
  EarningsRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EarningsRecord(
      id: fields[0] as String,
      riderId: fields[1] as String,
      campaignId: fields[2] as String?,
      campaignName: fields[3] as String?,
      amount: fields[4] as double,
      currency: fields[5] as String,
      type: fields[6] as EarningsType,
      earnedAt: fields[7] as DateTime,
      createdAt: fields[8] as DateTime,
      paymentStatus: fields[9] as PaymentStatus,
      paidAt: fields[10] as DateTime?,
      paymentReference: fields[11] as String?,
      distanceCovered: fields[12] as double?,
      verificationsCompleted: fields[13] as int?,
      isSynced: fields[14] as bool,
      metadata: (fields[15] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, EarningsRecord obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.riderId)
      ..writeByte(2)
      ..write(obj.campaignId)
      ..writeByte(3)
      ..write(obj.campaignName)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.earnedAt)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.paymentStatus)
      ..writeByte(10)
      ..write(obj.paidAt)
      ..writeByte(11)
      ..write(obj.paymentReference)
      ..writeByte(12)
      ..write(obj.distanceCovered)
      ..writeByte(13)
      ..write(obj.verificationsCompleted)
      ..writeByte(14)
      ..write(obj.isSynced)
      ..writeByte(15)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarningsRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PendingActionAdapter extends TypeAdapter<PendingAction> {
  @override
  final int typeId = 13;

  @override
  PendingAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingAction(
      id: fields[0] as String,
      type: fields[1] as ActionType,
      data: (fields[2] as Map).cast<String, dynamic>(),
      createdAt: fields[3] as DateTime,
      retryCount: fields[4] as int,
      priority: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PendingAction obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.data)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.retryCount)
      ..writeByte(5)
      ..write(obj.priority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EarningsTypeAdapter extends TypeAdapter<EarningsType> {
  @override
  final int typeId = 11;

  @override
  EarningsType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EarningsType.campaign;
      case 1:
        return EarningsType.bonus;
      case 2:
        return EarningsType.referral;
      case 3:
        return EarningsType.correction;
      default:
        return EarningsType.campaign;
    }
  }

  @override
  void write(BinaryWriter writer, EarningsType obj) {
    switch (obj) {
      case EarningsType.campaign:
        writer.writeByte(0);
        break;
      case EarningsType.bonus:
        writer.writeByte(1);
        break;
      case EarningsType.referral:
        writer.writeByte(2);
        break;
      case EarningsType.correction:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarningsTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentStatusAdapter extends TypeAdapter<PaymentStatus> {
  @override
  final int typeId = 12;

  @override
  PaymentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentStatus.pending;
      case 1:
        return PaymentStatus.processing;
      case 2:
        return PaymentStatus.completed;
      case 3:
        return PaymentStatus.failed;
      case 4:
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentStatus obj) {
    switch (obj) {
      case PaymentStatus.pending:
        writer.writeByte(0);
        break;
      case PaymentStatus.processing:
        writer.writeByte(1);
        break;
      case PaymentStatus.completed:
        writer.writeByte(2);
        break;
      case PaymentStatus.failed:
        writer.writeByte(3);
        break;
      case PaymentStatus.cancelled:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActionTypeAdapter extends TypeAdapter<ActionType> {
  @override
  final int typeId = 14;

  @override
  ActionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActionType.syncVerification;
      case 1:
        return ActionType.syncLocation;
      case 2:
        return ActionType.syncEarnings;
      case 3:
        return ActionType.syncProfile;
      case 4:
        return ActionType.joinCampaign;
      case 5:
        return ActionType.leaveCampaign;
      default:
        return ActionType.syncVerification;
    }
  }

  @override
  void write(BinaryWriter writer, ActionType obj) {
    switch (obj) {
      case ActionType.syncVerification:
        writer.writeByte(0);
        break;
      case ActionType.syncLocation:
        writer.writeByte(1);
        break;
      case ActionType.syncEarnings:
        writer.writeByte(2);
        break;
      case ActionType.syncProfile:
        writer.writeByte(3);
        break;
      case ActionType.joinCampaign:
        writer.writeByte(4);
        break;
      case ActionType.leaveCampaign:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationRecord _$LocationRecordFromJson(Map<String, dynamic> json) =>
    LocationRecord(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      campaignId: json['campaignId'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isWorking: json['isWorking'] as bool? ?? true,
      isSynced: json['isSynced'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$LocationRecordToJson(LocationRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'riderId': instance.riderId,
      'campaignId': instance.campaignId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'accuracy': instance.accuracy,
      'speed': instance.speed,
      'heading': instance.heading,
      'altitude': instance.altitude,
      'timestamp': instance.timestamp.toIso8601String(),
      'isWorking': instance.isWorking,
      'isSynced': instance.isSynced,
      'createdAt': instance.createdAt.toIso8601String(),
      'metadata': instance.metadata,
    };

EarningsRecord _$EarningsRecordFromJson(Map<String, dynamic> json) =>
    EarningsRecord(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      campaignId: json['campaignId'] as String?,
      campaignName: json['campaignName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'NGN',
      type: $enumDecode(_$EarningsTypeEnumMap, json['type']),
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      paymentStatus:
          $enumDecodeNullable(_$PaymentStatusEnumMap, json['paymentStatus']) ??
              PaymentStatus.pending,
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String),
      paymentReference: json['paymentReference'] as String?,
      distanceCovered: (json['distanceCovered'] as num?)?.toDouble(),
      verificationsCompleted: (json['verificationsCompleted'] as num?)?.toInt(),
      isSynced: json['isSynced'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$EarningsRecordToJson(EarningsRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'riderId': instance.riderId,
      'campaignId': instance.campaignId,
      'campaignName': instance.campaignName,
      'amount': instance.amount,
      'currency': instance.currency,
      'type': _$EarningsTypeEnumMap[instance.type]!,
      'earnedAt': instance.earnedAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'paymentStatus': _$PaymentStatusEnumMap[instance.paymentStatus]!,
      'paidAt': instance.paidAt?.toIso8601String(),
      'paymentReference': instance.paymentReference,
      'distanceCovered': instance.distanceCovered,
      'verificationsCompleted': instance.verificationsCompleted,
      'isSynced': instance.isSynced,
      'metadata': instance.metadata,
    };

const _$EarningsTypeEnumMap = {
  EarningsType.campaign: 'campaign',
  EarningsType.bonus: 'bonus',
  EarningsType.referral: 'referral',
  EarningsType.correction: 'correction',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.processing: 'processing',
  PaymentStatus.completed: 'completed',
  PaymentStatus.failed: 'failed',
  PaymentStatus.cancelled: 'cancelled',
};

PendingAction _$PendingActionFromJson(Map<String, dynamic> json) =>
    PendingAction(
      id: json['id'] as String,
      type: $enumDecode(_$ActionTypeEnumMap, json['type']),
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      priority: (json['priority'] as num?)?.toInt() ?? 3,
    );

Map<String, dynamic> _$PendingActionToJson(PendingAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ActionTypeEnumMap[instance.type]!,
      'data': instance.data,
      'createdAt': instance.createdAt.toIso8601String(),
      'retryCount': instance.retryCount,
      'priority': instance.priority,
    };

const _$ActionTypeEnumMap = {
  ActionType.syncVerification: 'syncVerification',
  ActionType.syncLocation: 'syncLocation',
  ActionType.syncEarnings: 'syncEarnings',
  ActionType.syncProfile: 'syncProfile',
  ActionType.joinCampaign: 'joinCampaign',
  ActionType.leaveCampaign: 'leaveCampaign',
};

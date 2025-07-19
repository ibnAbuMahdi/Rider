// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VerificationRequestAdapter extends TypeAdapter<VerificationRequest> {
  @override
  final int typeId = 7;

  @override
  VerificationRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VerificationRequest(
      id: fields[0] as String,
      riderId: fields[1] as String,
      campaignId: fields[2] as String,
      campaignName: fields[3] as String?,
      imageUrl: fields[4] as String?,
      localImagePath: fields[5] as String?,
      imageMetadata: (fields[6] as Map?)?.cast<String, dynamic>(),
      latitude: fields[7] as double,
      longitude: fields[8] as double,
      accuracy: fields[9] as double,
      timestamp: fields[10] as DateTime,
      deadline: fields[11] as DateTime,
      status: fields[12] as VerificationStatus,
      confidenceScore: fields[13] as double?,
      aiAnalysis: (fields[14] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[15] as DateTime,
      processedAt: fields[16] as DateTime?,
      failureReason: fields[17] as String?,
      isManualReview: fields[18] as bool,
      isSynced: fields[19] as bool,
      retryCount: fields[20] as int,
    );
  }

  @override
  void write(BinaryWriter writer, VerificationRequest obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.riderId)
      ..writeByte(2)
      ..write(obj.campaignId)
      ..writeByte(3)
      ..write(obj.campaignName)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.localImagePath)
      ..writeByte(6)
      ..write(obj.imageMetadata)
      ..writeByte(7)
      ..write(obj.latitude)
      ..writeByte(8)
      ..write(obj.longitude)
      ..writeByte(9)
      ..write(obj.accuracy)
      ..writeByte(10)
      ..write(obj.timestamp)
      ..writeByte(11)
      ..write(obj.deadline)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.confidenceScore)
      ..writeByte(14)
      ..write(obj.aiAnalysis)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.processedAt)
      ..writeByte(17)
      ..write(obj.failureReason)
      ..writeByte(18)
      ..write(obj.isManualReview)
      ..writeByte(19)
      ..write(obj.isSynced)
      ..writeByte(20)
      ..write(obj.retryCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificationRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VerificationStatusAdapter extends TypeAdapter<VerificationStatus> {
  @override
  final int typeId = 8;

  @override
  VerificationStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return VerificationStatus.pending;
      case 1:
        return VerificationStatus.processing;
      case 2:
        return VerificationStatus.passed;
      case 3:
        return VerificationStatus.failed;
      case 4:
        return VerificationStatus.manualReview;
      default:
        return VerificationStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, VerificationStatus obj) {
    switch (obj) {
      case VerificationStatus.pending:
        writer.writeByte(0);
        break;
      case VerificationStatus.processing:
        writer.writeByte(1);
        break;
      case VerificationStatus.passed:
        writer.writeByte(2);
        break;
      case VerificationStatus.failed:
        writer.writeByte(3);
        break;
      case VerificationStatus.manualReview:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificationStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerificationRequest _$VerificationRequestFromJson(Map<String, dynamic> json) =>
    VerificationRequest(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      campaignId: json['campaignId'] as String,
      campaignName: json['campaignName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      localImagePath: json['localImagePath'] as String?,
      imageMetadata: json['imageMetadata'] as Map<String, dynamic>?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      deadline: DateTime.parse(json['deadline'] as String),
      status:
          $enumDecodeNullable(_$VerificationStatusEnumMap, json['status']) ??
              VerificationStatus.pending,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      aiAnalysis: json['aiAnalysis'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      processedAt: json['processedAt'] == null
          ? null
          : DateTime.parse(json['processedAt'] as String),
      failureReason: json['failureReason'] as String?,
      isManualReview: json['isManualReview'] as bool? ?? false,
      isSynced: json['isSynced'] as bool? ?? false,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$VerificationRequestToJson(
        VerificationRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'riderId': instance.riderId,
      'campaignId': instance.campaignId,
      'campaignName': instance.campaignName,
      'imageUrl': instance.imageUrl,
      'localImagePath': instance.localImagePath,
      'imageMetadata': instance.imageMetadata,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'accuracy': instance.accuracy,
      'timestamp': instance.timestamp.toIso8601String(),
      'deadline': instance.deadline.toIso8601String(),
      'status': _$VerificationStatusEnumMap[instance.status]!,
      'confidenceScore': instance.confidenceScore,
      'aiAnalysis': instance.aiAnalysis,
      'createdAt': instance.createdAt.toIso8601String(),
      'processedAt': instance.processedAt?.toIso8601String(),
      'failureReason': instance.failureReason,
      'isManualReview': instance.isManualReview,
      'isSynced': instance.isSynced,
      'retryCount': instance.retryCount,
    };

const _$VerificationStatusEnumMap = {
  VerificationStatus.pending: 'pending',
  VerificationStatus.processing: 'processing',
  VerificationStatus.passed: 'passed',
  VerificationStatus.failed: 'failed',
  VerificationStatus.manualReview: 'manualReview',
};

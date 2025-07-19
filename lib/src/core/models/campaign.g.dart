// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CampaignAdapter extends TypeAdapter<Campaign> {
  @override
  final int typeId = 1;

  @override
  Campaign read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Campaign(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      clientName: fields[3] as String?,
      agencyId: fields[4] as String,
      agencyName: fields[5] as String,
      stickerImageUrl: fields[6] as String,
      ratePerKm: fields[7] as double,
      ratePerHour: fields[8] as double,
      fixedDailyRate: fields[9] as double,
      startDate: fields[10] as DateTime,
      endDate: fields[11] as DateTime,
      status: fields[12] as CampaignStatus,
      geofences: (fields[13] as List).cast<Geofence>(),
      maxRiders: fields[14] as int,
      currentRiders: fields[15] as int,
      requirements: fields[16] as CampaignRequirements,
      estimatedWeeklyEarnings: fields[17] as double,
      area: fields[18] as String,
      targetAudiences: (fields[19] as List).cast<String>(),
      metadata: (fields[20] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[21] as DateTime,
      updatedAt: fields[22] as DateTime?,
      isActive: fields[23] as bool,
      totalVerifications: fields[24] as int,
      totalDistanceCovered: fields[25] as double,
      budget: fields[26] as double,
      spent: fields[27] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Campaign obj) {
    writer
      ..writeByte(28)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.clientName)
      ..writeByte(4)
      ..write(obj.agencyId)
      ..writeByte(5)
      ..write(obj.agencyName)
      ..writeByte(6)
      ..write(obj.stickerImageUrl)
      ..writeByte(7)
      ..write(obj.ratePerKm)
      ..writeByte(8)
      ..write(obj.ratePerHour)
      ..writeByte(9)
      ..write(obj.fixedDailyRate)
      ..writeByte(10)
      ..write(obj.startDate)
      ..writeByte(11)
      ..write(obj.endDate)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.geofences)
      ..writeByte(14)
      ..write(obj.maxRiders)
      ..writeByte(15)
      ..write(obj.currentRiders)
      ..writeByte(16)
      ..write(obj.requirements)
      ..writeByte(17)
      ..write(obj.estimatedWeeklyEarnings)
      ..writeByte(18)
      ..write(obj.area)
      ..writeByte(19)
      ..write(obj.targetAudiences)
      ..writeByte(20)
      ..write(obj.metadata)
      ..writeByte(21)
      ..write(obj.createdAt)
      ..writeByte(22)
      ..write(obj.updatedAt)
      ..writeByte(23)
      ..write(obj.isActive)
      ..writeByte(24)
      ..write(obj.totalVerifications)
      ..writeByte(25)
      ..write(obj.totalDistanceCovered)
      ..writeByte(26)
      ..write(obj.budget)
      ..writeByte(27)
      ..write(obj.spent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GeofenceAdapter extends TypeAdapter<Geofence> {
  @override
  final int typeId = 3;

  @override
  Geofence read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Geofence(
      id: fields[0] as String,
      name: fields[1] as String,
      centerLatitude: fields[2] as double,
      centerLongitude: fields[3] as double,
      radius: fields[4] as double,
      shape: fields[5] as GeofenceShape,
      polygonPoints: (fields[6] as List?)?.cast<LatLng>(),
    );
  }

  @override
  void write(BinaryWriter writer, Geofence obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.centerLatitude)
      ..writeByte(3)
      ..write(obj.centerLongitude)
      ..writeByte(4)
      ..write(obj.radius)
      ..writeByte(5)
      ..write(obj.shape)
      ..writeByte(6)
      ..write(obj.polygonPoints);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeofenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LatLngAdapter extends TypeAdapter<LatLng> {
  @override
  final int typeId = 5;

  @override
  LatLng read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LatLng(
      fields[0] as double,
      fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LatLng obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLngAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CampaignRequirementsAdapter extends TypeAdapter<CampaignRequirements> {
  @override
  final int typeId = 6;

  @override
  CampaignRequirements read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CampaignRequirements(
      minRating: fields[0] as int,
      minCompletedCampaigns: fields[1] as int,
      requiresVerification: fields[2] as bool,
      requiredDocuments: (fields[3] as List).cast<String>(),
      minAge: fields[4] as int,
      requiresSmartphone: fields[5] as bool,
      allowedVehicleTypes: (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CampaignRequirements obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.minRating)
      ..writeByte(1)
      ..write(obj.minCompletedCampaigns)
      ..writeByte(2)
      ..write(obj.requiresVerification)
      ..writeByte(3)
      ..write(obj.requiredDocuments)
      ..writeByte(4)
      ..write(obj.minAge)
      ..writeByte(5)
      ..write(obj.requiresSmartphone)
      ..writeByte(6)
      ..write(obj.allowedVehicleTypes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignRequirementsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CampaignStatusAdapter extends TypeAdapter<CampaignStatus> {
  @override
  final int typeId = 20;

  @override
  CampaignStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CampaignStatus.draft;
      case 1:
        return CampaignStatus.pending;
      case 2:
        return CampaignStatus.running;
      case 3:
        return CampaignStatus.paused;
      case 4:
        return CampaignStatus.completed;
      case 5:
        return CampaignStatus.cancelled;
      default:
        return CampaignStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, CampaignStatus obj) {
    switch (obj) {
      case CampaignStatus.draft:
        writer.writeByte(0);
        break;
      case CampaignStatus.pending:
        writer.writeByte(1);
        break;
      case CampaignStatus.running:
        writer.writeByte(2);
        break;
      case CampaignStatus.paused:
        writer.writeByte(3);
        break;
      case CampaignStatus.completed:
        writer.writeByte(4);
        break;
      case CampaignStatus.cancelled:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GeofenceShapeAdapter extends TypeAdapter<GeofenceShape> {
  @override
  final int typeId = 4;

  @override
  GeofenceShape read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GeofenceShape.circle;
      case 1:
        return GeofenceShape.polygon;
      default:
        return GeofenceShape.circle;
    }
  }

  @override
  void write(BinaryWriter writer, GeofenceShape obj) {
    switch (obj) {
      case GeofenceShape.circle:
        writer.writeByte(0);
        break;
      case GeofenceShape.polygon:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeofenceShapeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Campaign _$CampaignFromJson(Map<String, dynamic> json) => Campaign(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      clientName: json['clientName'] as String?,
      agencyId: json['agencyId'] as String,
      agencyName: json['agencyName'] as String,
      stickerImageUrl: json['stickerImageUrl'] as String,
      ratePerKm: (json['ratePerKm'] as num?)?.toDouble() ?? 0.0,
      ratePerHour: (json['ratePerHour'] as num?)?.toDouble() ?? 0.0,
      fixedDailyRate: (json['fixedDailyRate'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: $enumDecodeNullable(_$CampaignStatusEnumMap, json['status']) ??
          CampaignStatus.draft,
      geofences: (json['geofences'] as List<dynamic>?)
              ?.map((e) => Geofence.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      maxRiders: (json['maxRiders'] as num?)?.toInt() ?? 100,
      currentRiders: (json['currentRiders'] as num?)?.toInt() ?? 0,
      requirements: CampaignRequirements.fromJson(
          json['requirements'] as Map<String, dynamic>),
      estimatedWeeklyEarnings:
          (json['estimatedWeeklyEarnings'] as num?)?.toDouble() ?? 0.0,
      area: json['area'] as String,
      targetAudiences: (json['targetAudiences'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? false,
      totalVerifications: (json['totalVerifications'] as num?)?.toInt() ?? 0,
      totalDistanceCovered:
          (json['totalDistanceCovered'] as num?)?.toDouble() ?? 0.0,
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$CampaignToJson(Campaign instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'clientName': instance.clientName,
      'agencyId': instance.agencyId,
      'agencyName': instance.agencyName,
      'stickerImageUrl': instance.stickerImageUrl,
      'ratePerKm': instance.ratePerKm,
      'ratePerHour': instance.ratePerHour,
      'fixedDailyRate': instance.fixedDailyRate,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'status': _$CampaignStatusEnumMap[instance.status]!,
      'geofences': instance.geofences,
      'maxRiders': instance.maxRiders,
      'currentRiders': instance.currentRiders,
      'requirements': instance.requirements,
      'estimatedWeeklyEarnings': instance.estimatedWeeklyEarnings,
      'area': instance.area,
      'targetAudiences': instance.targetAudiences,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isActive': instance.isActive,
      'totalVerifications': instance.totalVerifications,
      'totalDistanceCovered': instance.totalDistanceCovered,
      'budget': instance.budget,
      'spent': instance.spent,
    };

const _$CampaignStatusEnumMap = {
  CampaignStatus.draft: 'draft',
  CampaignStatus.pending: 'pending',
  CampaignStatus.running: 'running',
  CampaignStatus.paused: 'paused',
  CampaignStatus.completed: 'completed',
  CampaignStatus.cancelled: 'cancelled',
};

Geofence _$GeofenceFromJson(Map<String, dynamic> json) => Geofence(
      id: json['id'] as String,
      name: json['name'] as String,
      centerLatitude: (json['centerLatitude'] as num).toDouble(),
      centerLongitude: (json['centerLongitude'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      shape: $enumDecodeNullable(_$GeofenceShapeEnumMap, json['shape']) ??
          GeofenceShape.circle,
      polygonPoints: (json['polygonPoints'] as List<dynamic>?)
          ?.map((e) => LatLng.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GeofenceToJson(Geofence instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'centerLatitude': instance.centerLatitude,
      'centerLongitude': instance.centerLongitude,
      'radius': instance.radius,
      'shape': _$GeofenceShapeEnumMap[instance.shape]!,
      'polygonPoints': instance.polygonPoints,
    };

const _$GeofenceShapeEnumMap = {
  GeofenceShape.circle: 'circle',
  GeofenceShape.polygon: 'polygon',
};

LatLng _$LatLngFromJson(Map<String, dynamic> json) => LatLng(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$LatLngToJson(LatLng instance) => <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

CampaignRequirements _$CampaignRequirementsFromJson(
        Map<String, dynamic> json) =>
    CampaignRequirements(
      minRating: (json['minRating'] as num?)?.toInt() ?? 0,
      minCompletedCampaigns:
          (json['minCompletedCampaigns'] as num?)?.toInt() ?? 0,
      requiresVerification: json['requiresVerification'] as bool? ?? true,
      requiredDocuments: (json['requiredDocuments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      minAge: (json['minAge'] as num?)?.toInt() ?? 18,
      requiresSmartphone: json['requiresSmartphone'] as bool? ?? true,
      allowedVehicleTypes: (json['allowedVehicleTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['tricycle'],
    );

Map<String, dynamic> _$CampaignRequirementsToJson(
        CampaignRequirements instance) =>
    <String, dynamic>{
      'minRating': instance.minRating,
      'minCompletedCampaigns': instance.minCompletedCampaigns,
      'requiresVerification': instance.requiresVerification,
      'requiredDocuments': instance.requiredDocuments,
      'minAge': instance.minAge,
      'requiresSmartphone': instance.requiresSmartphone,
      'allowedVehicleTypes': instance.allowedVehicleTypes,
    };

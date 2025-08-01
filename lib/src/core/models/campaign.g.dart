// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GeofenceAssignmentAdapter extends TypeAdapter<GeofenceAssignment> {
  @override
  final int typeId = 27;

  @override
  GeofenceAssignment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GeofenceAssignment(
      geofenceId: fields[0] as String,
      geofenceName: fields[1] as String,
      status: fields[2] as GeofenceAssignmentStatus,
      startedAt: fields[3] as DateTime?,
      endedAt: fields[4] as DateTime?,
      centerLatitude: fields[5] as double,
      centerLongitude: fields[6] as double,
      radiusMeters: fields[7] as int,
      ratePerKm: fields[8] as double?,
      ratePerHour: fields[9] as double?,
      fixedDailyRate: fields[10] as double?,
      amountEarned: fields[11] as double?,
      distanceCovered: fields[12] as double?,
      hoursActive: fields[13] as double?,
      centerLatitudeCamelCase: fields[14] as double?,
      centerLongitudeCamelCase: fields[15] as double?,
      radius: fields[16] as int?,
      displayColor: fields[17] as int?,
      displayAlpha: fields[18] as double?,
      isHighPriority: fields[19] as bool?,
      name: fields[20] as String?,
      budget: fields[21] as double?,
      spent: fields[22] as double?,
      remainingBudget: fields[23] as double?,
      maxRiders: fields[24] as int?,
      currentRiders: fields[25] as int?,
      isActiveFromBackend: fields[26] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, GeofenceAssignment obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.geofenceId)
      ..writeByte(1)
      ..write(obj.geofenceName)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.startedAt)
      ..writeByte(4)
      ..write(obj.endedAt)
      ..writeByte(5)
      ..write(obj.centerLatitude)
      ..writeByte(6)
      ..write(obj.centerLongitude)
      ..writeByte(7)
      ..write(obj.radiusMeters)
      ..writeByte(8)
      ..write(obj.ratePerKm)
      ..writeByte(9)
      ..write(obj.ratePerHour)
      ..writeByte(10)
      ..write(obj.fixedDailyRate)
      ..writeByte(11)
      ..write(obj.amountEarned)
      ..writeByte(12)
      ..write(obj.distanceCovered)
      ..writeByte(13)
      ..write(obj.hoursActive)
      ..writeByte(14)
      ..write(obj.centerLatitudeCamelCase)
      ..writeByte(15)
      ..write(obj.centerLongitudeCamelCase)
      ..writeByte(16)
      ..write(obj.radius)
      ..writeByte(17)
      ..write(obj.displayColor)
      ..writeByte(18)
      ..write(obj.displayAlpha)
      ..writeByte(19)
      ..write(obj.isHighPriority)
      ..writeByte(20)
      ..write(obj.name)
      ..writeByte(21)
      ..write(obj.budget)
      ..writeByte(22)
      ..write(obj.spent)
      ..writeByte(23)
      ..write(obj.remainingBudget)
      ..writeByte(24)
      ..write(obj.maxRiders)
      ..writeByte(25)
      ..write(obj.currentRiders)
      ..writeByte(26)
      ..write(obj.isActiveFromBackend);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeofenceAssignmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CampaignAssignmentAdapter extends TypeAdapter<CampaignAssignment> {
  @override
  final int typeId = 28;

  @override
  CampaignAssignment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CampaignAssignment(
      status: fields[0] as String,
      assignedAt: fields[1] as DateTime?,
      acceptedAt: fields[2] as DateTime?,
      verificationCount: fields[3] as int,
      complianceScore: fields[4] as double,
      amountEarned: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CampaignAssignment obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.status)
      ..writeByte(1)
      ..write(obj.assignedAt)
      ..writeByte(2)
      ..write(obj.acceptedAt)
      ..writeByte(3)
      ..write(obj.verificationCount)
      ..writeByte(4)
      ..write(obj.complianceScore)
      ..writeByte(5)
      ..write(obj.amountEarned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignAssignmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
      name: fields[1] as String?,
      description: fields[2] as String?,
      clientName: fields[3] as String?,
      agencyId: fields[4] as String,
      agencyName: fields[5] as String?,
      stickerImageUrl: fields[6] as String?,
      ratePerKm: fields[7] as double?,
      ratePerHour: fields[8] as double?,
      fixedDailyRate: fields[9] as double?,
      startDate: fields[10] as DateTime?,
      endDate: fields[11] as DateTime?,
      status: fields[12] as CampaignStatus,
      geofences: (fields[13] as List).cast<Geofence>(),
      maxRiders: fields[14] as int?,
      currentRiders: fields[15] as int?,
      requirements: fields[16] as CampaignRequirements,
      estimatedWeeklyEarnings: fields[17] as double?,
      area: fields[18] as String?,
      targetAudiences: (fields[19] as List).cast<String>(),
      metadata: (fields[20] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[21] as DateTime?,
      updatedAt: fields[22] as DateTime?,
      isActive: fields[23] as bool,
      totalVerifications: fields[24] as int?,
      totalDistanceCovered: fields[25] as double?,
      budget: fields[26] as double?,
      spent: fields[27] as double?,
      assignment: fields[28] as CampaignAssignment?,
      activeGeofences: (fields[29] as List).cast<GeofenceAssignment>(),
    );
  }

  @override
  void write(BinaryWriter writer, Campaign obj) {
    writer
      ..writeByte(30)
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
      ..write(obj.spent)
      ..writeByte(28)
      ..write(obj.assignment)
      ..writeByte(29)
      ..write(obj.activeGeofences);
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
      name: fields[1] as String?,
      centerLatitude: fields[2] as double,
      centerLongitude: fields[3] as double,
      radius: fields[4] as double?,
      shape: fields[5] as GeofenceShape,
      polygonPoints: (fields[6] as List?)?.cast<GeofencePoint>(),
      budget: fields[7] as double?,
      spent: fields[8] as double?,
      remainingBudget: fields[9] as double?,
      rateType: fields[10] as String?,
      ratePerKm: fields[11] as double?,
      ratePerHour: fields[12] as double?,
      fixedDailyRate: fields[13] as double?,
      startDate: fields[14] as DateTime,
      endDate: fields[15] as DateTime,
      maxRiders: fields[16] as int?,
      currentRiders: fields[17] as int?,
      availableSlots: fields[18] as int?,
      minRiders: fields[19] as int?,
      status: fields[20] as String,
      isActive: fields[21] as bool,
      isHighPriority: fields[22] as bool,
      priority: fields[23] as int?,
      fillPercentage: fields[24] as double?,
      budgetUtilization: fields[25] as double?,
      verificationSuccessRate: fields[26] as double?,
      averageHourlyRate: fields[27] as double?,
      areaType: fields[28] as String?,
      targetCoverageHours: fields[29] as int?,
      verificationFrequency: fields[30] as int?,
      specialInstructions: fields[31] as String?,
      description: fields[32] as String?,
      totalDistanceCovered: fields[33] as double?,
      totalVerifications: fields[34] as int?,
      successfulVerifications: fields[35] as int?,
      totalHoursActive: fields[36] as double?,
      targetDemographics: (fields[37] as Map?)?.cast<String, dynamic>(),
      pickupLocations: (fields[38] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
    );
  }

  @override
  void write(BinaryWriter writer, Geofence obj) {
    writer
      ..writeByte(39)
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
      ..write(obj.polygonPoints)
      ..writeByte(7)
      ..write(obj.budget)
      ..writeByte(8)
      ..write(obj.spent)
      ..writeByte(9)
      ..write(obj.remainingBudget)
      ..writeByte(10)
      ..write(obj.rateType)
      ..writeByte(11)
      ..write(obj.ratePerKm)
      ..writeByte(12)
      ..write(obj.ratePerHour)
      ..writeByte(13)
      ..write(obj.fixedDailyRate)
      ..writeByte(14)
      ..write(obj.startDate)
      ..writeByte(15)
      ..write(obj.endDate)
      ..writeByte(16)
      ..write(obj.maxRiders)
      ..writeByte(17)
      ..write(obj.currentRiders)
      ..writeByte(18)
      ..write(obj.availableSlots)
      ..writeByte(19)
      ..write(obj.minRiders)
      ..writeByte(20)
      ..write(obj.status)
      ..writeByte(21)
      ..write(obj.isActive)
      ..writeByte(22)
      ..write(obj.isHighPriority)
      ..writeByte(23)
      ..write(obj.priority)
      ..writeByte(24)
      ..write(obj.fillPercentage)
      ..writeByte(25)
      ..write(obj.budgetUtilization)
      ..writeByte(26)
      ..write(obj.verificationSuccessRate)
      ..writeByte(27)
      ..write(obj.averageHourlyRate)
      ..writeByte(28)
      ..write(obj.areaType)
      ..writeByte(29)
      ..write(obj.targetCoverageHours)
      ..writeByte(30)
      ..write(obj.verificationFrequency)
      ..writeByte(31)
      ..write(obj.specialInstructions)
      ..writeByte(32)
      ..write(obj.description)
      ..writeByte(33)
      ..write(obj.totalDistanceCovered)
      ..writeByte(34)
      ..write(obj.totalVerifications)
      ..writeByte(35)
      ..write(obj.successfulVerifications)
      ..writeByte(36)
      ..write(obj.totalHoursActive)
      ..writeByte(37)
      ..write(obj.targetDemographics)
      ..writeByte(38)
      ..write(obj.pickupLocations);
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

class GeofencePointAdapter extends TypeAdapter<GeofencePoint> {
  @override
  final int typeId = 5;

  @override
  GeofencePoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GeofencePoint(
      fields[0] as double?,
      fields[1] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, GeofencePoint obj) {
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
      other is GeofencePointAdapter &&
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
      minRating: fields[0] as int?,
      minCompletedCampaigns: fields[1] as int?,
      requiresVerification: fields[2] as bool,
      requiredDocuments: (fields[3] as List).cast<String>(),
      minAge: fields[4] as int?,
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

class GeofenceAssignmentStatusAdapter
    extends TypeAdapter<GeofenceAssignmentStatus> {
  @override
  final int typeId = 26;

  @override
  GeofenceAssignmentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GeofenceAssignmentStatus.assigned;
      case 1:
        return GeofenceAssignmentStatus.active;
      case 2:
        return GeofenceAssignmentStatus.paused;
      case 3:
        return GeofenceAssignmentStatus.completed;
      case 4:
        return GeofenceAssignmentStatus.cancelled;
      default:
        return GeofenceAssignmentStatus.assigned;
    }
  }

  @override
  void write(BinaryWriter writer, GeofenceAssignmentStatus obj) {
    switch (obj) {
      case GeofenceAssignmentStatus.assigned:
        writer.writeByte(0);
        break;
      case GeofenceAssignmentStatus.active:
        writer.writeByte(1);
        break;
      case GeofenceAssignmentStatus.paused:
        writer.writeByte(2);
        break;
      case GeofenceAssignmentStatus.completed:
        writer.writeByte(3);
        break;
      case GeofenceAssignmentStatus.cancelled:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeofenceAssignmentStatusAdapter &&
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

GeofenceAssignment _$GeofenceAssignmentFromJson(Map<String, dynamic> json) =>
    GeofenceAssignment(
      geofenceId: json['geofence_id'] as String,
      geofenceName: json['geofence_name'] as String,
      status: $enumDecode(_$GeofenceAssignmentStatusEnumMap, json['status']),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      endedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      centerLatitude: (json['center_latitude'] as num).toDouble(),
      centerLongitude: (json['center_longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num).toInt(),
      ratePerKm: (json['rate_per_km'] as num?)?.toDouble(),
      ratePerHour: (json['rate_per_hour'] as num?)?.toDouble(),
      fixedDailyRate: (json['fixed_daily_rate'] as num?)?.toDouble(),
      amountEarned: (json['earnings_from_geofence'] as num?)?.toDouble(),
      distanceCovered: (json['distance_covered'] as num?)?.toDouble(),
      hoursActive: (json['hours_active'] as num?)?.toDouble(),
      centerLatitudeCamelCase: (json['centerLatitude'] as num?)?.toDouble(),
      centerLongitudeCamelCase: (json['centerLongitude'] as num?)?.toDouble(),
      radius: (json['radius'] as num?)?.toInt(),
      displayColor: (json['displayColor'] as num?)?.toInt(),
      displayAlpha: (json['displayAlpha'] as num?)?.toDouble(),
      isHighPriority: json['isHighPriority'] as bool?,
      name: json['name'] as String?,
      budget: (json['budget'] as num?)?.toDouble(),
      spent: (json['spent'] as num?)?.toDouble(),
      remainingBudget: (json['remainingBudget'] as num?)?.toDouble(),
      maxRiders: (json['maxRiders'] as num?)?.toInt(),
      currentRiders: (json['currentRiders'] as num?)?.toInt(),
      isActiveFromBackend: json['isActive'] as bool?,
    );

Map<String, dynamic> _$GeofenceAssignmentToJson(GeofenceAssignment instance) =>
    <String, dynamic>{
      'geofence_id': instance.geofenceId,
      'geofence_name': instance.geofenceName,
      'status': _$GeofenceAssignmentStatusEnumMap[instance.status]!,
      'started_at': instance.startedAt?.toIso8601String(),
      'completed_at': instance.endedAt?.toIso8601String(),
      'center_latitude': instance.centerLatitude,
      'center_longitude': instance.centerLongitude,
      'radius_meters': instance.radiusMeters,
      'rate_per_km': instance.ratePerKm,
      'rate_per_hour': instance.ratePerHour,
      'fixed_daily_rate': instance.fixedDailyRate,
      'earnings_from_geofence': instance.amountEarned,
      'distance_covered': instance.distanceCovered,
      'hours_active': instance.hoursActive,
      'centerLatitude': instance.centerLatitudeCamelCase,
      'centerLongitude': instance.centerLongitudeCamelCase,
      'radius': instance.radius,
      'displayColor': instance.displayColor,
      'displayAlpha': instance.displayAlpha,
      'isHighPriority': instance.isHighPriority,
      'name': instance.name,
      'budget': instance.budget,
      'spent': instance.spent,
      'remainingBudget': instance.remainingBudget,
      'maxRiders': instance.maxRiders,
      'currentRiders': instance.currentRiders,
      'isActive': instance.isActiveFromBackend,
    };

const _$GeofenceAssignmentStatusEnumMap = {
  GeofenceAssignmentStatus.assigned: 'assigned',
  GeofenceAssignmentStatus.active: 'active',
  GeofenceAssignmentStatus.paused: 'paused',
  GeofenceAssignmentStatus.completed: 'completed',
  GeofenceAssignmentStatus.cancelled: 'cancelled',
};

CampaignAssignment _$CampaignAssignmentFromJson(Map<String, dynamic> json) =>
    CampaignAssignment(
      status: json['status'] as String,
      assignedAt: json['assigned_at'] == null
          ? null
          : DateTime.parse(json['assigned_at'] as String),
      acceptedAt: json['accepted_at'] == null
          ? null
          : DateTime.parse(json['accepted_at'] as String),
      verificationCount: (json['verification_count'] as num).toInt(),
      complianceScore: (json['compliance_score'] as num).toDouble(),
      amountEarned: (json['amount_earned'] as num).toDouble(),
    );

Map<String, dynamic> _$CampaignAssignmentToJson(CampaignAssignment instance) =>
    <String, dynamic>{
      'status': instance.status,
      'assigned_at': instance.assignedAt?.toIso8601String(),
      'accepted_at': instance.acceptedAt?.toIso8601String(),
      'verification_count': instance.verificationCount,
      'compliance_score': instance.complianceScore,
      'amount_earned': instance.amountEarned,
    };

Campaign _$CampaignFromJson(Map<String, dynamic> json) => Campaign(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      clientName: json['clientName'] as String?,
      agencyId: json['agencyId'] as String,
      agencyName: json['agencyName'] as String?,
      stickerImageUrl: json['stickerImageUrl'] as String?,
      ratePerKm: (json['ratePerKm'] as num?)?.toDouble(),
      ratePerHour: (json['ratePerHour'] as num?)?.toDouble(),
      fixedDailyRate: Campaign._stringToDouble(json['fixedDailyRate']),
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      status: $enumDecodeNullable(_$CampaignStatusEnumMap, json['status']) ??
          CampaignStatus.draft,
      geofences: (json['geofences'] as List<dynamic>?)
              ?.map((e) => Geofence.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      maxRiders: Campaign._stringToInt(json['maxRiders']),
      currentRiders: (json['currentRiders'] as num?)?.toInt(),
      requirements: CampaignRequirements.fromJson(
          json['requirements'] as Map<String, dynamic>),
      estimatedWeeklyEarnings:
          (json['estimatedWeeklyEarnings'] as num?)?.toDouble(),
      area: json['area'] as String?,
      targetAudiences: (json['targetAudiences'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? false,
      totalVerifications: (json['totalVerifications'] as num?)?.toInt(),
      totalDistanceCovered: (json['totalDistanceCovered'] as num?)?.toDouble(),
      budget: Campaign._stringToDouble(json['budget']),
      spent: Campaign._stringToDouble(json['spent']),
      assignment: json['assignment'] == null
          ? null
          : CampaignAssignment.fromJson(
              json['assignment'] as Map<String, dynamic>),
      activeGeofences: (json['active_geofences'] as List<dynamic>?)
              ?.map(
                  (e) => GeofenceAssignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
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
      'fixedDailyRate': Campaign._doubleToString(instance.fixedDailyRate),
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'status': _$CampaignStatusEnumMap[instance.status]!,
      'geofences': instance.geofences,
      'maxRiders': Campaign._intToString(instance.maxRiders),
      'currentRiders': instance.currentRiders,
      'requirements': instance.requirements,
      'estimatedWeeklyEarnings': instance.estimatedWeeklyEarnings,
      'area': instance.area,
      'targetAudiences': instance.targetAudiences,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isActive': instance.isActive,
      'totalVerifications': instance.totalVerifications,
      'totalDistanceCovered': instance.totalDistanceCovered,
      'budget': Campaign._doubleToString(instance.budget),
      'spent': Campaign._doubleToString(instance.spent),
      'assignment': instance.assignment,
      'active_geofences': instance.activeGeofences,
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
      name: json['name'] as String?,
      centerLatitude: (json['centerLatitude'] as num).toDouble(),
      centerLongitude: (json['centerLongitude'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble(),
      shape: $enumDecodeNullable(_$GeofenceShapeEnumMap, json['shape']) ??
          GeofenceShape.circle,
      polygonPoints: (json['polygonPoints'] as List<dynamic>?)
          ?.map((e) => GeofencePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      budget: (json['budget'] as num?)?.toDouble(),
      spent: (json['spent'] as num?)?.toDouble(),
      remainingBudget: (json['remainingBudget'] as num?)?.toDouble(),
      rateType: json['rateType'] as String?,
      ratePerKm: (json['ratePerKm'] as num?)?.toDouble(),
      ratePerHour: (json['ratePerHour'] as num?)?.toDouble(),
      fixedDailyRate: (json['fixedDailyRate'] as num?)?.toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      maxRiders: (json['maxRiders'] as num?)?.toInt(),
      currentRiders: (json['currentRiders'] as num?)?.toInt(),
      availableSlots: (json['availableSlots'] as num?)?.toInt(),
      minRiders: (json['minRiders'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'active',
      isActive: json['isActive'] as bool? ?? true,
      isHighPriority: json['isHighPriority'] as bool? ?? false,
      priority: (json['priority'] as num?)?.toInt(),
      fillPercentage: (json['fillPercentage'] as num?)?.toDouble(),
      budgetUtilization: (json['budgetUtilization'] as num?)?.toDouble(),
      verificationSuccessRate:
          (json['verificationSuccessRate'] as num?)?.toDouble(),
      averageHourlyRate: (json['averageHourlyRate'] as num?)?.toDouble(),
      areaType: json['areaType'] as String? ?? 'mixed',
      targetCoverageHours: (json['targetCoverageHours'] as num?)?.toInt(),
      verificationFrequency: (json['verificationFrequency'] as num?)?.toInt(),
      specialInstructions: json['specialInstructions'] as String? ?? '',
      description: json['description'] as String? ?? '',
      totalDistanceCovered: (json['totalDistanceCovered'] as num?)?.toDouble(),
      totalVerifications: (json['totalVerifications'] as num?)?.toInt(),
      successfulVerifications:
          (json['successfulVerifications'] as num?)?.toInt(),
      totalHoursActive: (json['totalHoursActive'] as num?)?.toDouble(),
      targetDemographics:
          json['targetDemographics'] as Map<String, dynamic>? ?? const {},
      pickupLocations: (json['pickupLocations'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
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
      'budget': instance.budget,
      'spent': instance.spent,
      'remainingBudget': instance.remainingBudget,
      'rateType': instance.rateType,
      'ratePerKm': instance.ratePerKm,
      'ratePerHour': instance.ratePerHour,
      'fixedDailyRate': instance.fixedDailyRate,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'maxRiders': instance.maxRiders,
      'currentRiders': instance.currentRiders,
      'availableSlots': instance.availableSlots,
      'minRiders': instance.minRiders,
      'status': instance.status,
      'isActive': instance.isActive,
      'isHighPriority': instance.isHighPriority,
      'priority': instance.priority,
      'fillPercentage': instance.fillPercentage,
      'budgetUtilization': instance.budgetUtilization,
      'verificationSuccessRate': instance.verificationSuccessRate,
      'averageHourlyRate': instance.averageHourlyRate,
      'areaType': instance.areaType,
      'targetCoverageHours': instance.targetCoverageHours,
      'verificationFrequency': instance.verificationFrequency,
      'specialInstructions': instance.specialInstructions,
      'description': instance.description,
      'totalDistanceCovered': instance.totalDistanceCovered,
      'totalVerifications': instance.totalVerifications,
      'successfulVerifications': instance.successfulVerifications,
      'totalHoursActive': instance.totalHoursActive,
      'targetDemographics': instance.targetDemographics,
      'pickupLocations': instance.pickupLocations,
    };

const _$GeofenceShapeEnumMap = {
  GeofenceShape.circle: 'circle',
  GeofenceShape.polygon: 'polygon',
};

GeofencePoint _$GeofencePointFromJson(Map<String, dynamic> json) =>
    GeofencePoint(
      (json['lat'] as num?)?.toDouble(),
      (json['lng'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$GeofencePointToJson(GeofencePoint instance) =>
    <String, dynamic>{
      'lat': instance.latitude,
      'lng': instance.longitude,
    };

CampaignRequirements _$CampaignRequirementsFromJson(
        Map<String, dynamic> json) =>
    CampaignRequirements(
      minRating: (json['min_rating'] as num?)?.toInt(),
      minCompletedCampaigns: (json['min_completed_campaigns'] as num?)?.toInt(),
      requiresVerification: json['requires_verification'] as bool? ?? true,
      requiredDocuments: (json['required_documents'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      minAge: (json['min_age'] as num?)?.toInt(),
      requiresSmartphone: json['requires_smartphone'] as bool? ?? true,
      allowedVehicleTypes: (json['allowed_vehicle_types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['tricycle'],
    );

Map<String, dynamic> _$CampaignRequirementsToJson(
        CampaignRequirements instance) =>
    <String, dynamic>{
      'min_rating': instance.minRating,
      'min_completed_campaigns': instance.minCompletedCampaigns,
      'requires_verification': instance.requiresVerification,
      'required_documents': instance.requiredDocuments,
      'min_age': instance.minAge,
      'requires_smartphone': instance.requiresSmartphone,
      'allowed_vehicle_types': instance.allowedVehicleTypes,
    };

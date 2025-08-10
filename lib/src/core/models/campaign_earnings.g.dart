// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign_earnings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CampaignEarningsAdapter extends TypeAdapter<CampaignEarnings> {
  @override
  final int typeId = 10;

  @override
  CampaignEarnings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CampaignEarnings(
      campaignId: fields[0] as String,
      campaignTitle: fields[1] as String,
      campaignImageUrl: fields[2] as String?,
      geofenceId: fields[3] as String,
      geofenceName: fields[4] as String,
      assignmentId: fields[5] as String,
      totalEarned: fields[6] as double,
      thisWeekEarned: fields[7] as double,
      thisMonthEarned: fields[8] as double,
      pendingAmount: fields[9] as double,
      paidAmount: fields[10] as double,
      totalSessions: fields[11] as int,
      totalTimeWorked: fields[12] as Duration,
      totalDistanceCovered: fields[13] as double,
      verificationsCompleted: fields[14] as int,
      assignmentStartDate: fields[15] as DateTime,
      assignmentEndDate: fields[16] as DateTime?,
      lastActiveDate: fields[17] as DateTime?,
      lastPaymentDate: fields[18] as DateTime?,
      rateType: fields[19] as String,
      ratePerKm: fields[20] as double,
      ratePerHour: fields[21] as double,
      fixedDailyRate: fields[22] as double,
      status: fields[23] as String,
      createdAt: fields[24] as DateTime,
      updatedAt: fields[25] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CampaignEarnings obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.campaignId)
      ..writeByte(1)
      ..write(obj.campaignTitle)
      ..writeByte(2)
      ..write(obj.campaignImageUrl)
      ..writeByte(3)
      ..write(obj.geofenceId)
      ..writeByte(4)
      ..write(obj.geofenceName)
      ..writeByte(5)
      ..write(obj.assignmentId)
      ..writeByte(6)
      ..write(obj.totalEarned)
      ..writeByte(7)
      ..write(obj.thisWeekEarned)
      ..writeByte(8)
      ..write(obj.thisMonthEarned)
      ..writeByte(9)
      ..write(obj.pendingAmount)
      ..writeByte(10)
      ..write(obj.paidAmount)
      ..writeByte(11)
      ..write(obj.totalSessions)
      ..writeByte(12)
      ..write(obj.totalTimeWorked)
      ..writeByte(13)
      ..write(obj.totalDistanceCovered)
      ..writeByte(14)
      ..write(obj.verificationsCompleted)
      ..writeByte(15)
      ..write(obj.assignmentStartDate)
      ..writeByte(16)
      ..write(obj.assignmentEndDate)
      ..writeByte(17)
      ..write(obj.lastActiveDate)
      ..writeByte(18)
      ..write(obj.lastPaymentDate)
      ..writeByte(19)
      ..write(obj.rateType)
      ..writeByte(20)
      ..write(obj.ratePerKm)
      ..writeByte(21)
      ..write(obj.ratePerHour)
      ..writeByte(22)
      ..write(obj.fixedDailyRate)
      ..writeByte(23)
      ..write(obj.status)
      ..writeByte(24)
      ..write(obj.createdAt)
      ..writeByte(25)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignEarningsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CampaignSummaryAdapter extends TypeAdapter<CampaignSummary> {
  @override
  final int typeId = 12;

  @override
  CampaignSummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CampaignSummary(
      campaignId: fields[0] as String,
      campaignTitle: fields[1] as String,
      campaignImageUrl: fields[2] as String?,
      totalEarned: fields[3] as double,
      pendingAmount: fields[4] as double,
      paidAmount: fields[5] as double,
      totalAssignments: fields[6] as int,
      activeAssignments: fields[7] as int,
      geofenceAssignments: (fields[8] as List).cast<CampaignEarnings>(),
      firstJoinedDate: fields[9] as DateTime,
      lastActiveDate: fields[10] as DateTime?,
      status: fields[11] as String,
      updatedAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CampaignSummary obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.campaignId)
      ..writeByte(1)
      ..write(obj.campaignTitle)
      ..writeByte(2)
      ..write(obj.campaignImageUrl)
      ..writeByte(3)
      ..write(obj.totalEarned)
      ..writeByte(4)
      ..write(obj.pendingAmount)
      ..writeByte(5)
      ..write(obj.paidAmount)
      ..writeByte(6)
      ..write(obj.totalAssignments)
      ..writeByte(7)
      ..write(obj.activeAssignments)
      ..writeByte(8)
      ..write(obj.geofenceAssignments)
      ..writeByte(9)
      ..write(obj.firstJoinedDate)
      ..writeByte(10)
      ..write(obj.lastActiveDate)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignSummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EarningsOverviewAdapter extends TypeAdapter<EarningsOverview> {
  @override
  final int typeId = 11;

  @override
  EarningsOverview read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EarningsOverview(
      totalEarnings: fields[0] as double,
      pendingEarnings: fields[1] as double,
      paidEarnings: fields[2] as double,
      thisWeekEarnings: fields[3] as double,
      thisMonthEarnings: fields[4] as double,
      lastWeekEarnings: fields[5] as double,
      lastMonthEarnings: fields[6] as double,
      activeCampaignsCount: fields[7] as int,
      totalCampaignsCount: fields[8] as int,
      totalTimeWorked: fields[9] as Duration,
      totalDistanceCovered: fields[10] as double,
      totalVerifications: fields[11] as int,
      totalSessions: fields[12] as int,
      nextPaymentDate: fields[13] as DateTime?,
      topPerformingCampaign: fields[14] as String,
      averageDailyEarnings: fields[15] as double,
      weeklyTrend: (fields[16] as List).cast<double>(),
      updatedAt: fields[17] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, EarningsOverview obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.totalEarnings)
      ..writeByte(1)
      ..write(obj.pendingEarnings)
      ..writeByte(2)
      ..write(obj.paidEarnings)
      ..writeByte(3)
      ..write(obj.thisWeekEarnings)
      ..writeByte(4)
      ..write(obj.thisMonthEarnings)
      ..writeByte(5)
      ..write(obj.lastWeekEarnings)
      ..writeByte(6)
      ..write(obj.lastMonthEarnings)
      ..writeByte(7)
      ..write(obj.activeCampaignsCount)
      ..writeByte(8)
      ..write(obj.totalCampaignsCount)
      ..writeByte(9)
      ..write(obj.totalTimeWorked)
      ..writeByte(10)
      ..write(obj.totalDistanceCovered)
      ..writeByte(11)
      ..write(obj.totalVerifications)
      ..writeByte(12)
      ..write(obj.totalSessions)
      ..writeByte(13)
      ..write(obj.nextPaymentDate)
      ..writeByte(14)
      ..write(obj.topPerformingCampaign)
      ..writeByte(15)
      ..write(obj.averageDailyEarnings)
      ..writeByte(16)
      ..write(obj.weeklyTrend)
      ..writeByte(17)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarningsOverviewAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CampaignEarnings _$CampaignEarningsFromJson(Map<String, dynamic> json) =>
    CampaignEarnings(
      campaignId: json['campaignId'] as String,
      campaignTitle: json['campaignTitle'] as String,
      campaignImageUrl: json['campaignImageUrl'] as String?,
      geofenceId: json['geofenceId'] as String,
      geofenceName: json['geofenceName'] as String,
      assignmentId: json['assignmentId'] as String,
      totalEarned: (json['totalEarned'] as num).toDouble(),
      thisWeekEarned: (json['thisWeekEarned'] as num).toDouble(),
      thisMonthEarned: (json['thisMonthEarned'] as num).toDouble(),
      pendingAmount: (json['pendingAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      totalSessions: (json['totalSessions'] as num).toInt(),
      totalTimeWorked:
          Duration(microseconds: (json['totalTimeWorked'] as num).toInt()),
      totalDistanceCovered: (json['totalDistanceCovered'] as num).toDouble(),
      verificationsCompleted: (json['verificationsCompleted'] as num).toInt(),
      assignmentStartDate:
          DateTime.parse(json['assignmentStartDate'] as String),
      assignmentEndDate: json['assignmentEndDate'] == null
          ? null
          : DateTime.parse(json['assignmentEndDate'] as String),
      lastActiveDate: json['lastActiveDate'] == null
          ? null
          : DateTime.parse(json['lastActiveDate'] as String),
      lastPaymentDate: json['lastPaymentDate'] == null
          ? null
          : DateTime.parse(json['lastPaymentDate'] as String),
      rateType: json['rateType'] as String,
      ratePerKm: (json['ratePerKm'] as num).toDouble(),
      ratePerHour: (json['ratePerHour'] as num).toDouble(),
      fixedDailyRate: (json['fixedDailyRate'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CampaignEarningsToJson(CampaignEarnings instance) =>
    <String, dynamic>{
      'campaignId': instance.campaignId,
      'campaignTitle': instance.campaignTitle,
      'campaignImageUrl': instance.campaignImageUrl,
      'geofenceId': instance.geofenceId,
      'geofenceName': instance.geofenceName,
      'assignmentId': instance.assignmentId,
      'totalEarned': instance.totalEarned,
      'thisWeekEarned': instance.thisWeekEarned,
      'thisMonthEarned': instance.thisMonthEarned,
      'pendingAmount': instance.pendingAmount,
      'paidAmount': instance.paidAmount,
      'totalSessions': instance.totalSessions,
      'totalTimeWorked': instance.totalTimeWorked.inMicroseconds,
      'totalDistanceCovered': instance.totalDistanceCovered,
      'verificationsCompleted': instance.verificationsCompleted,
      'assignmentStartDate': instance.assignmentStartDate.toIso8601String(),
      'assignmentEndDate': instance.assignmentEndDate?.toIso8601String(),
      'lastActiveDate': instance.lastActiveDate?.toIso8601String(),
      'lastPaymentDate': instance.lastPaymentDate?.toIso8601String(),
      'rateType': instance.rateType,
      'ratePerKm': instance.ratePerKm,
      'ratePerHour': instance.ratePerHour,
      'fixedDailyRate': instance.fixedDailyRate,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

CampaignSummary _$CampaignSummaryFromJson(Map<String, dynamic> json) =>
    CampaignSummary(
      campaignId: json['campaignId'] as String,
      campaignTitle: json['campaignTitle'] as String,
      campaignImageUrl: json['campaignImageUrl'] as String?,
      totalEarned: (json['totalEarned'] as num).toDouble(),
      pendingAmount: (json['pendingAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      totalAssignments: (json['totalAssignments'] as num).toInt(),
      activeAssignments: (json['activeAssignments'] as num).toInt(),
      geofenceAssignments: (json['geofenceAssignments'] as List<dynamic>)
          .map((e) => CampaignEarnings.fromJson(e as Map<String, dynamic>))
          .toList(),
      firstJoinedDate: DateTime.parse(json['firstJoinedDate'] as String),
      lastActiveDate: json['lastActiveDate'] == null
          ? null
          : DateTime.parse(json['lastActiveDate'] as String),
      status: json['status'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CampaignSummaryToJson(CampaignSummary instance) =>
    <String, dynamic>{
      'campaignId': instance.campaignId,
      'campaignTitle': instance.campaignTitle,
      'campaignImageUrl': instance.campaignImageUrl,
      'totalEarned': instance.totalEarned,
      'pendingAmount': instance.pendingAmount,
      'paidAmount': instance.paidAmount,
      'totalAssignments': instance.totalAssignments,
      'activeAssignments': instance.activeAssignments,
      'geofenceAssignments': instance.geofenceAssignments,
      'firstJoinedDate': instance.firstJoinedDate.toIso8601String(),
      'lastActiveDate': instance.lastActiveDate?.toIso8601String(),
      'status': instance.status,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

EarningsOverview _$EarningsOverviewFromJson(Map<String, dynamic> json) =>
    EarningsOverview(
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      pendingEarnings: (json['pendingEarnings'] as num).toDouble(),
      paidEarnings: (json['paidEarnings'] as num).toDouble(),
      thisWeekEarnings: (json['thisWeekEarnings'] as num).toDouble(),
      thisMonthEarnings: (json['thisMonthEarnings'] as num).toDouble(),
      lastWeekEarnings: (json['lastWeekEarnings'] as num).toDouble(),
      lastMonthEarnings: (json['lastMonthEarnings'] as num).toDouble(),
      activeCampaignsCount: (json['activeCampaignsCount'] as num).toInt(),
      totalCampaignsCount: (json['totalCampaignsCount'] as num).toInt(),
      totalTimeWorked:
          Duration(microseconds: (json['totalTimeWorked'] as num).toInt()),
      totalDistanceCovered: (json['totalDistanceCovered'] as num).toDouble(),
      totalVerifications: (json['totalVerifications'] as num).toInt(),
      totalSessions: (json['totalSessions'] as num).toInt(),
      nextPaymentDate: json['nextPaymentDate'] == null
          ? null
          : DateTime.parse(json['nextPaymentDate'] as String),
      topPerformingCampaign: json['topPerformingCampaign'] as String,
      averageDailyEarnings: (json['averageDailyEarnings'] as num).toDouble(),
      weeklyTrend: (json['weeklyTrend'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$EarningsOverviewToJson(EarningsOverview instance) =>
    <String, dynamic>{
      'totalEarnings': instance.totalEarnings,
      'pendingEarnings': instance.pendingEarnings,
      'paidEarnings': instance.paidEarnings,
      'thisWeekEarnings': instance.thisWeekEarnings,
      'thisMonthEarnings': instance.thisMonthEarnings,
      'lastWeekEarnings': instance.lastWeekEarnings,
      'lastMonthEarnings': instance.lastMonthEarnings,
      'activeCampaignsCount': instance.activeCampaignsCount,
      'totalCampaignsCount': instance.totalCampaignsCount,
      'totalTimeWorked': instance.totalTimeWorked.inMicroseconds,
      'totalDistanceCovered': instance.totalDistanceCovered,
      'totalVerifications': instance.totalVerifications,
      'totalSessions': instance.totalSessions,
      'nextPaymentDate': instance.nextPaymentDate?.toIso8601String(),
      'topPerformingCampaign': instance.topPerformingCampaign,
      'averageDailyEarnings': instance.averageDailyEarnings,
      'weeklyTrend': instance.weeklyTrend,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

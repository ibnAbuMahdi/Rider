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
      campaignId: json['campaign_id'] as String,
      campaignTitle: json['campaign_title'] as String,
      campaignImageUrl: json['campaign_image_url'] as String?,
      geofenceId: json['geofence_id'] as String,
      geofenceName: json['geofence_name'] as String,
      assignmentId: json['assignment_id'] as String,
      totalEarned: (json['total_earned'] as num).toDouble(),
      thisWeekEarned: (json['this_week_earned'] as num).toDouble(),
      thisMonthEarned: (json['this_month_earned'] as num).toDouble(),
      pendingAmount: (json['pending_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      totalSessions: (json['total_sessions'] as num).toInt(),
      totalTimeWorked: _durationFromInt(json['total_time_worked'] as num),
      totalDistanceCovered: (json['total_distance_covered'] as num).toDouble(),
      verificationsCompleted: (json['verifications_completed'] as num).toInt(),
      assignmentStartDate:
          _dateTimeFromString(json['assignment_start_date'] as String),
      assignmentEndDate:
          _optionalDateTimeFromString(json['assignment_end_date'] as String?),
      lastActiveDate:
          _optionalDateTimeFromString(json['last_active_date'] as String?),
      lastPaymentDate:
          _optionalDateTimeFromString(json['last_payment_date'] as String?),
      rateType: json['rate_type'] as String,
      ratePerKm: (json['rate_per_km'] as num).toDouble(),
      ratePerHour: (json['rate_per_hour'] as num).toDouble(),
      fixedDailyRate: (json['fixed_daily_rate'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: _dateTimeFromString(json['created_at'] as String),
      updatedAt: _dateTimeFromString(json['updated_at'] as String),
    );

Map<String, dynamic> _$CampaignEarningsToJson(CampaignEarnings instance) =>
    <String, dynamic>{
      'campaign_id': instance.campaignId,
      'campaign_title': instance.campaignTitle,
      'campaign_image_url': instance.campaignImageUrl,
      'geofence_id': instance.geofenceId,
      'geofence_name': instance.geofenceName,
      'assignment_id': instance.assignmentId,
      'total_earned': instance.totalEarned,
      'this_week_earned': instance.thisWeekEarned,
      'this_month_earned': instance.thisMonthEarned,
      'pending_amount': instance.pendingAmount,
      'paid_amount': instance.paidAmount,
      'total_sessions': instance.totalSessions,
      'total_time_worked': _durationToInt(instance.totalTimeWorked),
      'total_distance_covered': instance.totalDistanceCovered,
      'verifications_completed': instance.verificationsCompleted,
      'assignment_start_date': _dateTimeToString(instance.assignmentStartDate),
      'assignment_end_date':
          _optionalDateTimeToString(instance.assignmentEndDate),
      'last_active_date': _optionalDateTimeToString(instance.lastActiveDate),
      'last_payment_date': _optionalDateTimeToString(instance.lastPaymentDate),
      'rate_type': instance.rateType,
      'rate_per_km': instance.ratePerKm,
      'rate_per_hour': instance.ratePerHour,
      'fixed_daily_rate': instance.fixedDailyRate,
      'status': instance.status,
      'created_at': _dateTimeToString(instance.createdAt),
      'updated_at': _dateTimeToString(instance.updatedAt),
    };

CampaignSummary _$CampaignSummaryFromJson(Map<String, dynamic> json) =>
    CampaignSummary(
      campaignId: json['campaign_id'] as String,
      campaignTitle: json['campaign_title'] as String,
      campaignImageUrl: json['campaign_image_url'] as String?,
      totalEarned: (json['total_earned'] as num).toDouble(),
      pendingAmount: (json['pending_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      totalAssignments: (json['total_assignments'] as num).toInt(),
      activeAssignments: (json['active_assignments'] as num).toInt(),
      geofenceAssignments: (json['geofence_assignments'] as List<dynamic>)
          .map((e) => CampaignEarnings.fromJson(e as Map<String, dynamic>))
          .toList(),
      firstJoinedDate: _dateTimeFromString(json['first_joined_date'] as String),
      lastActiveDate:
          _optionalDateTimeFromString(json['last_active_date'] as String?),
      status: json['status'] as String,
      updatedAt: _dateTimeFromString(json['updated_at'] as String),
    );

Map<String, dynamic> _$CampaignSummaryToJson(CampaignSummary instance) =>
    <String, dynamic>{
      'campaign_id': instance.campaignId,
      'campaign_title': instance.campaignTitle,
      'campaign_image_url': instance.campaignImageUrl,
      'total_earned': instance.totalEarned,
      'pending_amount': instance.pendingAmount,
      'paid_amount': instance.paidAmount,
      'total_assignments': instance.totalAssignments,
      'active_assignments': instance.activeAssignments,
      'geofence_assignments': instance.geofenceAssignments,
      'first_joined_date': _dateTimeToString(instance.firstJoinedDate),
      'last_active_date': _optionalDateTimeToString(instance.lastActiveDate),
      'status': instance.status,
      'updated_at': _dateTimeToString(instance.updatedAt),
    };

EarningsOverview _$EarningsOverviewFromJson(Map<String, dynamic> json) =>
    EarningsOverview(
      totalEarnings: (json['total_earnings'] as num).toDouble(),
      pendingEarnings: (json['pending_earnings'] as num).toDouble(),
      paidEarnings: (json['paid_earnings'] as num).toDouble(),
      thisWeekEarnings: (json['this_week_earnings'] as num).toDouble(),
      thisMonthEarnings: (json['this_month_earnings'] as num).toDouble(),
      lastWeekEarnings: (json['last_week_earnings'] as num).toDouble(),
      lastMonthEarnings: (json['last_month_earnings'] as num).toDouble(),
      activeCampaignsCount: (json['active_campaigns_count'] as num).toInt(),
      totalCampaignsCount: (json['total_campaigns_count'] as num).toInt(),
      totalTimeWorked: _durationFromInt(json['total_time_worked'] as num),
      totalDistanceCovered: (json['total_distance_covered'] as num).toDouble(),
      totalVerifications: (json['total_verifications'] as num).toInt(),
      totalSessions: (json['total_sessions'] as num).toInt(),
      nextPaymentDate: json['next_payment_date'] == null
          ? null
          : DateTime.parse(json['next_payment_date'] as String),
      topPerformingCampaign: json['top_performing_campaign'] as String,
      averageDailyEarnings: (json['average_daily_earnings'] as num).toDouble(),
      weeklyTrend: (json['weekly_trend'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      updatedAt: _dateTimeFromString(json['updated_at'] as String),
    );

Map<String, dynamic> _$EarningsOverviewToJson(EarningsOverview instance) =>
    <String, dynamic>{
      'total_earnings': instance.totalEarnings,
      'pending_earnings': instance.pendingEarnings,
      'paid_earnings': instance.paidEarnings,
      'this_week_earnings': instance.thisWeekEarnings,
      'this_month_earnings': instance.thisMonthEarnings,
      'last_week_earnings': instance.lastWeekEarnings,
      'last_month_earnings': instance.lastMonthEarnings,
      'active_campaigns_count': instance.activeCampaignsCount,
      'total_campaigns_count': instance.totalCampaignsCount,
      'total_time_worked': _durationToInt(instance.totalTimeWorked),
      'total_distance_covered': instance.totalDistanceCovered,
      'total_verifications': instance.totalVerifications,
      'total_sessions': instance.totalSessions,
      'next_payment_date': instance.nextPaymentDate?.toIso8601String(),
      'top_performing_campaign': instance.topPerformingCampaign,
      'average_daily_earnings': instance.averageDailyEarnings,
      'weekly_trend': instance.weeklyTrend,
      'updated_at': _dateTimeToString(instance.updatedAt),
    };

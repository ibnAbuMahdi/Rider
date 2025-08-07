// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FleetStatus _$FleetStatusFromJson(Map<String, dynamic> json) => FleetStatus(
      rider: RiderFleetInfo.fromJson(json['rider'] as Map<String, dynamic>),
      fleet: json['fleet'] == null
          ? null
          : FleetOwner.fromJson(json['fleet'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FleetStatusToJson(FleetStatus instance) =>
    <String, dynamic>{
      'rider': instance.rider,
      'fleet': instance.fleet,
    };

RiderFleetInfo _$RiderFleetInfoFromJson(Map<String, dynamic> json) =>
    RiderFleetInfo(
      id: json['id'] as String,
      isFleetRider: json['is_fleet_rider'] as bool,
      isIndependentRider: json['is_independent_rider'] as bool,
      fleetCommissionRate: (json['fleet_commission_rate'] as num).toDouble(),
    );

Map<String, dynamic> _$RiderFleetInfoToJson(RiderFleetInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'is_fleet_rider': instance.isFleetRider,
      'is_independent_rider': instance.isIndependentRider,
      'fleet_commission_rate': instance.fleetCommissionRate,
    };

FleetJoinResult _$FleetJoinResultFromJson(Map<String, dynamic> json) =>
    FleetJoinResult(
      success: json['success'] as bool,
      message: json['message'] as String,
      fleet: json['fleet'] == null
          ? null
          : FleetOwner.fromJson(json['fleet'] as Map<String, dynamic>),
      rider: json['rider'] == null
          ? null
          : RiderFleetInfo.fromJson(json['rider'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FleetJoinResultToJson(FleetJoinResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'fleet': instance.fleet,
      'rider': instance.rider,
    };

FleetLeaveResult _$FleetLeaveResultFromJson(Map<String, dynamic> json) =>
    FleetLeaveResult(
      success: json['success'] as bool,
      message: json['message'] as String,
      rider: json['rider'] == null
          ? null
          : RiderFleetInfo.fromJson(json['rider'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FleetLeaveResultToJson(FleetLeaveResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'rider': instance.rider,
    };

FleetLookupResult _$FleetLookupResultFromJson(Map<String, dynamic> json) =>
    FleetLookupResult(
      success: json['success'] as bool,
      message: json['message'] as String,
      fleet: json['fleet'] == null
          ? null
          : FleetOwner.fromJson(json['fleet'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FleetLookupResultToJson(FleetLookupResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'fleet': instance.fleet,
    };

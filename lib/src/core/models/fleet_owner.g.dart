// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_owner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FleetOwner _$FleetOwnerFromJson(Map<String, dynamic> json) => FleetOwner(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      fleetCode: json['fleet_code'] as String,
      companyName: json['company_name'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      fleetSize: (json['fleet_size'] as num).toInt(),
      activeRiders: (json['active_riders'] as num).toInt(),
      commissionRate: (json['commission_rate'] as num).toDouble(),
      isExclusive: json['is_exclusive'] as bool,
      canAcceptRiders: json['can_accept_riders'] as bool,
      yearsInOperation: (json['years_in_operation'] as num).toInt(),
      businessType: json['business_type'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      lockedRiders: json['locked_riders'] as bool?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$FleetOwnerToJson(FleetOwner instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'fleet_code': instance.fleetCode,
      'company_name': instance.companyName,
      'city': instance.city,
      'state': instance.state,
      'fleet_size': instance.fleetSize,
      'active_riders': instance.activeRiders,
      'commission_rate': instance.commissionRate,
      'is_exclusive': instance.isExclusive,
      'can_accept_riders': instance.canAcceptRiders,
      'years_in_operation': instance.yearsInOperation,
      'business_type': instance.businessType,
      'phone': instance.phone,
      'email': instance.email,
      'address': instance.address,
      'locked_riders': instance.lockedRiders,
      'status': instance.status,
    };

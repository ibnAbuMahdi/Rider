import 'package:json_annotation/json_annotation.dart';
import 'fleet_owner.dart';

part 'fleet_status.g.dart';

@JsonSerializable()
class FleetStatus {
  final RiderFleetInfo rider;
  final FleetOwner? fleet;

  const FleetStatus({
    required this.rider,
    this.fleet,
  });

  factory FleetStatus.fromJson(Map<String, dynamic> json) => _$FleetStatusFromJson(json);
  Map<String, dynamic> toJson() => _$FleetStatusToJson(this);

  /// Check if rider is in a fleet
  bool get isInFleet => fleet != null;

  /// Check if rider is independent
  bool get isIndependent => !rider.isFleetRider;

  /// Get current status display string
  String get statusDisplay {
    if (isInFleet) {
      return 'Fleet Member: ${fleet!.name}';
    } else {
      return 'Independent Rider';
    }
  }

  /// Get commission rate display
  String get commissionDisplay => '${rider.fleetCommissionRate.toStringAsFixed(1)}%';
}

@JsonSerializable()
class RiderFleetInfo {
  final String id;
  
  @JsonKey(name: 'is_fleet_rider')
  final bool isFleetRider;
  
  @JsonKey(name: 'is_independent_rider')
  final bool isIndependentRider;
  
  @JsonKey(name: 'fleet_commission_rate')
  final double fleetCommissionRate;

  const RiderFleetInfo({
    required this.id,
    required this.isFleetRider,
    required this.isIndependentRider,
    required this.fleetCommissionRate,
  });

  factory RiderFleetInfo.fromJson(Map<String, dynamic> json) => _$RiderFleetInfoFromJson(json);
  Map<String, dynamic> toJson() => _$RiderFleetInfoToJson(this);
}

@JsonSerializable()
class FleetJoinResult {
  final bool success;
  final String message;
  final FleetOwner? fleet;
  final RiderFleetInfo? rider;

  const FleetJoinResult({
    required this.success,
    required this.message,
    this.fleet,
    this.rider,
  });

  factory FleetJoinResult.fromJson(Map<String, dynamic> json) => _$FleetJoinResultFromJson(json);
  Map<String, dynamic> toJson() => _$FleetJoinResultToJson(this);
}

@JsonSerializable()
class FleetLeaveResult {
  final bool success;
  final String message;
  final RiderFleetInfo? rider;

  const FleetLeaveResult({
    required this.success,
    required this.message,
    this.rider,
  });

  factory FleetLeaveResult.fromJson(Map<String, dynamic> json) => _$FleetLeaveResultFromJson(json);
  Map<String, dynamic> toJson() => _$FleetLeaveResultToJson(this);
}

@JsonSerializable()
class FleetLookupResult {
  final bool success;
  final String message;
  final FleetOwner? fleet;

  const FleetLookupResult({
    required this.success,
    required this.message,
    this.fleet,
  });

  factory FleetLookupResult.fromJson(Map<String, dynamic> json) => _$FleetLookupResultFromJson(json);
  Map<String, dynamic> toJson() => _$FleetLookupResultToJson(this);
}
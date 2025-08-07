import 'package:json_annotation/json_annotation.dart';

part 'fleet_owner.g.dart';

@JsonSerializable()
class FleetOwner {
  final int id;
  
  final String name;
  
  @JsonKey(name: 'fleet_code')
  final String fleetCode;
  
  @JsonKey(name: 'company_name')
  final String companyName;
  
  final String city;
  
  final String state;
  
  @JsonKey(name: 'fleet_size')
  final int fleetSize;
  
  @JsonKey(name: 'active_riders')
  final int activeRiders;
  
  @JsonKey(name: 'commission_rate')
  final double commissionRate;
  
  @JsonKey(name: 'is_exclusive')
  final bool isExclusive;
  
  @JsonKey(name: 'can_accept_riders')
  final bool canAcceptRiders;
  
  @JsonKey(name: 'years_in_operation')
  final int yearsInOperation;
  
  @JsonKey(name: 'business_type')
  final String businessType;
  
  final String? phone;
  
  final String? email;
  
  final String? address;
  
  @JsonKey(name: 'locked_riders')
  final bool? lockedRiders;
  
  final String? status;

  const FleetOwner({
    required this.id,
    required this.name,
    required this.fleetCode,
    required this.companyName,
    required this.city,
    required this.state,
    required this.fleetSize,
    required this.activeRiders,
    required this.commissionRate,
    required this.isExclusive,
    required this.canAcceptRiders,
    required this.yearsInOperation,
    required this.businessType,
    this.phone,
    this.email,
    this.address,
    this.lockedRiders,
    this.status,
  });

  factory FleetOwner.fromJson(Map<String, dynamic> json) => _$FleetOwnerFromJson(json);
  Map<String, dynamic> toJson() => _$FleetOwnerToJson(this);

  /// Check if fleet is currently accepting new riders
  bool get isAcceptingRiders => canAcceptRiders && status == 'active';

  /// Get available slots for new riders
  int get availableSlots => fleetSize > activeRiders ? fleetSize - activeRiders : 0;

  /// Get fleet type display string
  String get fleetTypeDisplay {
    if (isExclusive && lockedRiders == true) {
      return 'Exclusive (Locked)';
    } else if (isExclusive) {
      return 'Exclusive';
    } else {
      return 'Open Fleet';
    }
  }

  /// Get commission rate as percentage string
  String get commissionRateDisplay => '${commissionRate.toStringAsFixed(1)}%';

  /// Get location display string
  String get locationDisplay => '$city, $state';

  /// Check if fleet has available capacity
  bool get hasCapacity => fleetSize == 0 || activeRiders < fleetSize;

  /// Get fleet status color indicator
  String get statusColor {
    if (!isAcceptingRiders) return 'red';
    if (availableSlots < 5) return 'orange';
    return 'green';
  }
}
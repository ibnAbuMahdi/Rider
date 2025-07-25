import 'dart:math' as math;
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'campaign.g.dart';

@HiveType(typeId: 20)
enum CampaignStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  pending,
  @HiveField(2)
  running,
  @HiveField(3)
  paused,
  @HiveField(4)
  completed,
  @HiveField(5)
  cancelled;
  
  String get displayName {
    switch (this) {
      case CampaignStatus.draft:
        return 'Draft';
      case CampaignStatus.pending:
        return 'Pending Approval';
      case CampaignStatus.running:
        return 'Active';
      case CampaignStatus.paused:
        return 'Paused';
      case CampaignStatus.completed:
        return 'Completed';
      case CampaignStatus.cancelled:
        return 'Cancelled';
    }
  }
}

@HiveType(typeId: 1)
@JsonSerializable()
class Campaign {
  @HiveField(0)
  final String? id;
  
  @HiveField(1)
  final String? name;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final String? clientName;
  
  @HiveField(4)
  final String? agencyId;
  
  @HiveField(5)
  final String? agencyName;
  
  @HiveField(6)
  final String? stickerImageUrl;
  
  @HiveField(7)
  final double? ratePerKm;
  
  @HiveField(8)
  final double? ratePerHour;
  
  @HiveField(9)
  @JsonKey(fromJson: _stringToDouble, toJson: _doubleToString) 
  final double? fixedDailyRate;
  
  @HiveField(10)
  final DateTime? startDate;
  
  @HiveField(11)
  final DateTime? endDate;
  
  @HiveField(12)
  final CampaignStatus status;
  
  @HiveField(13)
  final List<Geofence> geofences;
  
  @HiveField(14)
  @JsonKey(fromJson: _stringToInt, toJson: _intToString) 
  final int? maxRiders;
  
  @HiveField(15)
  final int? currentRiders;
  
  @HiveField(16)
  final CampaignRequirements requirements;
  
  @HiveField(17)
  final double? estimatedWeeklyEarnings;
  
  @HiveField(18)
  final String? area;
  
  @HiveField(19)
  final List<String> targetAudiences;
  
  @HiveField(20)
  final Map<String, dynamic>? metadata;
  
  @HiveField(21)
  final DateTime? createdAt;
  
  @HiveField(22)
  final DateTime? updatedAt;
  
  @HiveField(23)
  final bool isActive;
  
  @HiveField(24)
  final int? totalVerifications;
  
  @HiveField(25)
  final double? totalDistanceCovered;
  
  @HiveField(26)
  @JsonKey(fromJson: _stringToDouble, toJson: _doubleToString) 
  final double? budget;
  
  @HiveField(27)
  @JsonKey(fromJson: _stringToDouble, toJson: _doubleToString) 
  final double? spent;

  const Campaign({
    this.id,
    this.name,
    this.description,
    this.clientName,
    this.agencyId,
    this.agencyName,
    this.stickerImageUrl,
    this.ratePerKm,
    this.ratePerHour,
    this.fixedDailyRate,
    this.startDate,
    this.endDate,
    this.status = CampaignStatus.draft,
    this.geofences = const [],
    this.maxRiders,
    this.currentRiders,
    required this.requirements,
    this.estimatedWeeklyEarnings,
    this.area,
    this.targetAudiences = const [],
    this.metadata,
    this.createdAt,
    this.updatedAt,
    this.isActive = false,
    this.totalVerifications,
    this.totalDistanceCovered,
    this.budget,
    this.spent,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) => _$CampaignFromJson(json);
  Map<String, dynamic> toJson() => _$CampaignToJson(this);

// Helper functions for JSON conversion
  static double? _stringToDouble(dynamic value) {
    if (value == null) return null; // Return null if null
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value); // Return null if parse fails
    return null; // Return null for other types
  }

  static String? _doubleToString(double? value) => value?.toStringAsFixed(2); // Convert double to string with 2 decimal places

  static int? _stringToInt(dynamic value) {
    if (value == null) return null; // Return null if null
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value); // Return null if parse fails
    return null; // Return null for other types
  }

  static String? _intToString(int? value) => value?.toString();

  Campaign copyWith({
    String? id,
    String? name,
    String? description,
    String? clientName,
    String? agencyId,
    String? agencyName,
    String? stickerImageUrl,
    double? ratePerKm,
    double? ratePerHour,
    double? fixedDailyRate,
    DateTime? startDate,
    DateTime? endDate,
    CampaignStatus? status,
    List<Geofence>? geofences,
    int? maxRiders,
    int? currentRiders,
    CampaignRequirements? requirements,
    double? estimatedWeeklyEarnings,
    String? area,
    List<String>? targetAudiences,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? totalVerifications,
    double? totalDistanceCovered,
    double? budget,
    double? spent,
  }) {
    return Campaign(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      clientName: clientName ?? this.clientName,
      agencyId: agencyId ?? this.agencyId,
      agencyName: agencyName ?? this.agencyName,
      stickerImageUrl: stickerImageUrl ?? this.stickerImageUrl,
      ratePerKm: ratePerKm ?? this.ratePerKm,
      ratePerHour: ratePerHour ?? this.ratePerHour,
      fixedDailyRate: fixedDailyRate ?? this.fixedDailyRate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      geofences: geofences ?? this.geofences,
      maxRiders: maxRiders ?? this.maxRiders,
      currentRiders: currentRiders ?? this.currentRiders,
      requirements: requirements ?? this.requirements,
      estimatedWeeklyEarnings: estimatedWeeklyEarnings ?? this.estimatedWeeklyEarnings,
      area: area ?? this.area,
      targetAudiences: targetAudiences ?? this.targetAudiences,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      totalVerifications: totalVerifications ?? this.totalVerifications,
      totalDistanceCovered: totalDistanceCovered ?? this.totalDistanceCovered,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
    );
  }

  // Getters
  bool get hasAvailableSlots => (currentRiders ?? 0) < (maxRiders ?? 0);
  
  int get availableSlots => (maxRiders ?? 0) - (currentRiders ?? 0);
  
  bool get isRunning => status == CampaignStatus.running && isActive;
  
  bool get canJoin {
    final now = DateTime.now();
    return hasAvailableSlots && 
           isRunning && 
           (startDate == null || now.isAfter(startDate!)) && 
           (endDate == null || now.isBefore(endDate!));
  }
  
  bool get isExpired {
    final now = DateTime.now();
    return endDate != null && now.isAfter(endDate!);
  }
  
  bool get isUpcoming {
    final now = DateTime.now();
    return startDate != null && now.isBefore(startDate!);
  }
  
  double get progress {
    final budgetVal = budget ?? 0.0;
    final spentVal = spent ?? 0.0;
    if (budgetVal <= 0) return 0.0;
    return (spentVal / budgetVal).clamp(0.0, 1.0);
  }
  
  Duration get timeRemaining {
    final now = DateTime.now();
    if (endDate == null || now.isAfter(endDate!)) return Duration.zero;
    return endDate!.difference(now);
  }
  
  Duration get timeToStart {
    final now = DateTime.now();
    if (startDate == null || now.isAfter(startDate!)) return Duration.zero;
    return startDate!.difference(now);
  }
  
  double get fillPercentage {
    final max = maxRiders ?? 0;
    final current = currentRiders ?? 0;
    if (max <= 0) return 0.0;
    return (current / max * 100).clamp(0.0, 100.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Campaign && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id?.hashCode ?? 0;

  @override
  String toString() {
    return 'Campaign{id: $id, name: $name, status: $status, currentRiders: $currentRiders/$maxRiders}';
  }
}

@HiveType(typeId: 3)
@JsonSerializable()
class Geofence {
  @HiveField(0)
  final String? id;
  
  @HiveField(1)
  final String? name;
  
  @HiveField(2)
  final double centerLatitude;

  @HiveField(3)
  final double centerLongitude;
  
  @HiveField(4)
  final double? radius; // in meters
  
  @HiveField(5)
  final GeofenceShape shape;
  
  @HiveField(6)
  final List<GeofencePoint>? polygonPoints;
  
  // New fields for individual geofence settings
  @HiveField(7)
  final double? budget;
  
  @HiveField(8)
  final double? spent;
  
  @HiveField(9)
  final double? remainingBudget;
  
  @HiveField(10)
  final String? rateType; // 'per_km', 'per_hour', 'fixed_daily', 'hybrid'
  
  @HiveField(11)
  final double? ratePerKm;
  
  @HiveField(12)
  final double? ratePerHour;
  
  @HiveField(13)
  final double? fixedDailyRate;
  
  @HiveField(14)
  final DateTime startDate;
  
  @HiveField(15)
  final DateTime endDate;
  
  @HiveField(16)
  final int? maxRiders;
  
  @HiveField(17)
  final int? currentRiders;
  
  @HiveField(18)
  final int? availableSlots;
  
  @HiveField(19)
  final int? minRiders;
  
  @HiveField(20)
  final String status; // 'active', 'paused', 'completed', 'cancelled'
  
  @HiveField(21)
  final bool isActive;
  
  @HiveField(22)
  final bool isHighPriority;
  
  @HiveField(23)
  final int? priority;
  
  @HiveField(24)
  final double? fillPercentage;
  
  @HiveField(25)
  final double? budgetUtilization;
  
  @HiveField(26)
  final double? verificationSuccessRate;
  
  @HiveField(27)
  final double? averageHourlyRate;
  
  @HiveField(28)
  final String? areaType;
  
  @HiveField(29)
  final int? targetCoverageHours;
  
  @HiveField(30)
  final int? verificationFrequency;
  
  @HiveField(31)
  final String? specialInstructions;
  
  // Additional backend fields for full compatibility
  @HiveField(32)
  final String? description;
  
  @HiveField(33)
  final double? totalDistanceCovered;
  
  @HiveField(34)
  final int? totalVerifications;
  
  @HiveField(35)
  final int? successfulVerifications;
  
  @HiveField(36)
  final double? totalHoursActive;
  
  @HiveField(37)
  final Map<String, dynamic>? targetDemographics;

  const Geofence({
    this.id,
    this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    this.radius,
    this.shape = GeofenceShape.circle,
    this.polygonPoints,
    
    // Financial fields
    this.budget,
    this.spent,
    this.remainingBudget,
    
    // Rate fields
    this.rateType,
    this.ratePerKm,
    this.ratePerHour,
    this.fixedDailyRate,
    
    // Duration fields
    required this.startDate,
    required this.endDate,
    
    // Rider limit fields
    this.maxRiders,
    this.currentRiders,
    this.availableSlots,
    this.minRiders,
    
    // Status fields
    this.status = 'active',
    this.isActive = true,
    this.isHighPriority = false,
    this.priority,
    
    // Performance fields
    this.fillPercentage,
    this.budgetUtilization,
    this.verificationSuccessRate,
    this.averageHourlyRate,
    
    // Additional info
    this.areaType = 'mixed',
    this.targetCoverageHours,
    this.verificationFrequency,
    this.specialInstructions = '',
    
    // Additional backend compatibility fields
    this.description = '',
    this.totalDistanceCovered,
    this.totalVerifications,
    this.successfulVerifications,
    this.totalHoursActive,
    this.targetDemographics = const {},
  });

  factory Geofence.fromJson(Map<String, dynamic> json) => _$GeofenceFromJson(json);
  Map<String, dynamic> toJson() => _$GeofenceToJson(this);

  bool containsPoint(double latitude, double longitude) {
    if (shape == GeofenceShape.circle && radius != null) {
      return _distanceInMeters(centerLatitude, centerLongitude, latitude, longitude) <= radius!;
    } else if (shape == GeofenceShape.polygon && polygonPoints != null) {
      return _pointInPolygon(GeofencePoint(latitude, longitude), polygonPoints!);
    }
    return false;
  }

  double _distanceInMeters(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double dLat = (lat2 - lat1) * (math.pi / 180);
    final double dLon = (lon2 - lon1) * (math.pi / 180);
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  bool _pointInPolygon(GeofencePoint point, List<GeofencePoint> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    
    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].latitude ?? 0.0;
      final yi = polygon[i].longitude ?? 0.0;
      final xj = polygon[j].latitude ?? 0.0;
      final yj = polygon[j].longitude ?? 0.0;
      
      final pointLat = point.latitude ?? 0.0;
      final pointLng = point.longitude ?? 0.0;
      if (((yi > pointLng) != (yj > pointLng)) &&
          (pointLat < (xj - xi) * (pointLng - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }
    
    return inside;
  }
  
  // New methods for per-geofence functionality
  
  /// Calculate earnings for given distance and time in this geofence
  double calculateEarnings(double distanceKm, double hoursActive) {
    switch (rateType ?? 'per_km') {
      case 'per_km':
        return (ratePerKm ?? 0.0) * distanceKm;
      case 'per_hour':
        return (ratePerHour ?? 0.0) * hoursActive;
      case 'fixed_daily':
        return fixedDailyRate ?? 0.0;
      case 'hybrid':
        return ((ratePerKm ?? 0.0) * distanceKm) + ((ratePerHour ?? 0.0) * hoursActive);
      default:
        return (ratePerKm ?? 0.0) * distanceKm;
    }
  }
  
  /// Check if this geofence is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && 
           status == 'active' && 
           now.isAfter(startDate) && 
           now.isBefore(endDate);
  }
  
  /// Check if geofence has available slots for riders
  bool get hasAvailableSlots => (availableSlots ?? 0) > 0 && (currentRiders ?? 0) < (maxRiders ?? 0);
  
  /// Check if geofence budget is not exhausted
  bool get hasBudgetRemaining => (remainingBudget ?? 0.0) > 0;
  
  /// Check if rider can be assigned to this geofence
  bool get canAcceptRiders => 
      isCurrentlyActive && hasAvailableSlots && hasBudgetRemaining;
  
  /// Get estimated daily earnings for this geofence
  double get estimatedDailyEarnings {
    switch (rateType ?? 'per_km') {
      case 'per_km':
        // Assume average 50km per day for tricycles
        return (ratePerKm ?? 0.0) * 50;
      case 'per_hour':
        return (ratePerHour ?? 0.0) * (targetCoverageHours ?? 8);
      case 'fixed_daily':
        return fixedDailyRate ?? 0.0;
      case 'hybrid':
        // Combine both: 50km + target hours
        return ((ratePerKm ?? 0.0) * 50) + ((ratePerHour ?? 0.0) * (targetCoverageHours ?? 8));
      default:
        return (ratePerKm ?? 0.0) * 50;
    }
  }
  
  /// Get estimated weekly earnings for this geofence
  double get estimatedWeeklyEarnings => estimatedDailyEarnings * 7;
  
  /// Get time remaining until geofence ends
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }
  
  /// Get time until geofence starts
  Duration get timeToStart {
    final now = DateTime.now();
    if (now.isAfter(startDate)) return Duration.zero;
    return startDate.difference(now);
  }
  
 
  /// Check if geofence is expired
  bool get isExpired {
    final now = DateTime.now();
    return now.isAfter(endDate);
  }
  
  /// Check if geofence is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    return now.isBefore(startDate);
  }
  
  /// Get progress percentage of budget utilization
  double get budgetProgress {
    final budgetVal = budget ?? 0.0;
    final spentVal = spent ?? 0.0;
    if (budgetVal <= 0) return 0.0;
    return (spentVal / budgetVal * 100).clamp(0.0, 100.0);
  }
  
  /// Get display color for this geofence based on priority and status
  int get displayColor {
    if (!isActive) return 0xFF9E9E9E; // Grey for inactive
    if (isHighPriority) return 0xFFFF5722; // Deep Orange for high priority
    if ((fillPercentage ?? 0.0) > 80) return 0xFFFF9800; // Orange for nearly full
    return 0xFF4CAF50; // Green for normal active geofences
  }
  
  /// Get alpha transparency based on availability
  double get displayAlpha {
    if (!canAcceptRiders) return 0.5; // Semi-transparent if unavailable
    return 1.0; // Fully opaque if available
  }
  
  /// Get actual verification success rate from backend data
  double get actualVerificationSuccessRate {
    final total = totalVerifications ?? 0;
    final successful = successfulVerifications ?? 0;
    if (total == 0) return 100.0;
    return (successful / total * 100).clamp(0.0, 100.0);
  }
  
  /// Get actual average hourly rate from backend data
  double get actualAverageHourlyRate {
    final hours = totalHoursActive ?? 0.0;
    if (hours <= 0) return averageHourlyRate ?? 0.0;
    // Calculate from actual earnings if we had that data
    return averageHourlyRate ?? 0.0; // Fallback to provided rate
  }
  
  /// Check if geofence has performance data
  bool get hasPerformanceData {
    return (totalDistanceCovered ?? 0.0) > 0 || 
           (totalVerifications ?? 0) > 0 || 
           (totalHoursActive ?? 0.0) > 0;
  }
  
  /// Get performance summary
  Map<String, dynamic> get performanceSummary {
    return {
      'total_distance_km': (totalDistanceCovered ?? 0.0) / 1000.0,
      'total_verifications': totalVerifications,
      'successful_verifications': successfulVerifications,
      'verification_success_rate': actualVerificationSuccessRate,
      'total_hours_active': totalHoursActive,
      'has_performance_data': hasPerformanceData,
    };
  }
}

@HiveType(typeId: 4)
enum GeofenceShape {
  @HiveField(0)
  circle,
  
  @HiveField(1)
  polygon;
}

@HiveType(typeId: 5)
@JsonSerializable()
class GeofencePoint {
  @HiveField(0)
  @JsonKey(name: 'lat')
  final double? latitude;
  
  @HiveField(1)
  @JsonKey(name: 'lng')
  final double? longitude;

  const GeofencePoint(this.latitude, this.longitude);

  factory GeofencePoint.fromJson(Map<String, dynamic> json) => _$GeofencePointFromJson(json);
  Map<String, dynamic> toJson() => _$GeofencePointToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeofencePoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => (latitude?.hashCode ?? 0) ^ (longitude?.hashCode ?? 0);

  @override
  String toString() => 'GeofencePoint($latitude, $longitude)';
}

@HiveType(typeId: 6)
@JsonSerializable(fieldRename: FieldRename.snake)
class CampaignRequirements {
  @HiveField(0)
  final int? minRating;
  
  @HiveField(1)
  final int? minCompletedCampaigns;
  
  @HiveField(2)
  final bool requiresVerification;
  
  @HiveField(3)
  final List<String> requiredDocuments;
  
  @HiveField(4)
  final int? minAge;
  
  @HiveField(5)
  final bool requiresSmartphone;
  
  @HiveField(6)
  final List<String> allowedVehicleTypes;

  const CampaignRequirements({
    this.minRating,
    this.minCompletedCampaigns,
    this.requiresVerification = true,
    this.requiredDocuments = const [],
    this.minAge,
    this.requiresSmartphone = true,
    this.allowedVehicleTypes = const ['tricycle'],
  });

  factory CampaignRequirements.fromJson(Map<String, dynamic> json) => 
      _$CampaignRequirementsFromJson(json);
  Map<String, dynamic> toJson() => _$CampaignRequirementsToJson(this);
}
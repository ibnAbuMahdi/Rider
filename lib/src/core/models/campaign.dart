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

@HiveType(typeId: 26)
enum GeofenceAssignmentStatus {
  @HiveField(0)
  assigned,
  @HiveField(1)
  active,
  @HiveField(2)
  paused,
  @HiveField(3)
  completed,
  @HiveField(4)
  cancelled;
  
  String get displayName {
    switch (this) {
      case GeofenceAssignmentStatus.assigned:
        return 'Assigned';
      case GeofenceAssignmentStatus.active:
        return 'Active';
      case GeofenceAssignmentStatus.paused:
        return 'Paused';
      case GeofenceAssignmentStatus.completed:
        return 'Completed';
      case GeofenceAssignmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

@HiveType(typeId: 27)
@JsonSerializable()
class GeofenceAssignment {
  @HiveField(0)
  @JsonKey(name: 'id')
  final String id;  // Assignment ID for tracking
  
  @HiveField(27)  // Use unused field number after 26
  @JsonKey(name: 'geofence_id')
  final String geofenceId;
  
  @HiveField(1)
  @JsonKey(name: 'geofence_name')
  final String geofenceName;
  
  @HiveField(2)
  final GeofenceAssignmentStatus status;
  
  @HiveField(3)
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  
  @HiveField(4)
  @JsonKey(name: 'completed_at')
  final DateTime? endedAt;
  
  @HiveField(5)
  @JsonKey(name: 'center_latitude')
  final double centerLatitude;
  
  @HiveField(6)
  @JsonKey(name: 'center_longitude')
  final double centerLongitude;
  
  @HiveField(7)
  @JsonKey(name: 'radius_meters')
  final int radiusMeters;
  
  @HiveField(8)
  @JsonKey(name: 'rate_per_km')
  final double? ratePerKm;
  
  @HiveField(9)
  @JsonKey(name: 'rate_per_hour')
  final double? ratePerHour;
  
  @HiveField(10)
  @JsonKey(name: 'fixed_daily_rate')
  final double? fixedDailyRate;
  
  @HiveField(11)
  @JsonKey(name: 'earnings_from_geofence')
  final double? amountEarned;
  
  @HiveField(12)
  @JsonKey(name: 'distance_covered')
  final double? distanceCovered;
  
  @HiveField(13)
  @JsonKey(name: 'hours_active')
  final double? hoursActive;

  // New fields for map display (from enhanced backend serializer)
  @HiveField(14)
  @JsonKey(name: 'centerLatitude')
  final double? centerLatitudeCamelCase;
  
  @HiveField(15)
  @JsonKey(name: 'centerLongitude')
  final double? centerLongitudeCamelCase;
  
  @HiveField(16)
  @JsonKey(name: 'radius')
  final int? radius;
  
  @HiveField(17)
  @JsonKey(name: 'displayColor')
  final int? displayColor;
  
  @HiveField(18)
  @JsonKey(name: 'displayAlpha')
  final double? displayAlpha;
  
  @HiveField(19)
  @JsonKey(name: 'isHighPriority')
  final bool? isHighPriority;
  
  @HiveField(20)
  @JsonKey(name: 'name')
  final String? name;
  
  @HiveField(21)
  @JsonKey(name: 'budget')
  final double? budget;
  
  @HiveField(22)
  @JsonKey(name: 'spent')
  final double? spent;
  
  @HiveField(23)
  @JsonKey(name: 'remainingBudget')
  final double? remainingBudget;
  
  @HiveField(24)
  @JsonKey(name: 'maxRiders')
  final int? maxRiders;
  
  @HiveField(25)
  @JsonKey(name: 'currentRiders')
  final int? currentRiders;
  
  @HiveField(26)
  @JsonKey(name: 'isActive')
  final bool? isActiveFromBackend;

  const GeofenceAssignment({
    required this.id,
    required this.geofenceId,
    required this.geofenceName,
    required this.status,
    this.startedAt,
    this.endedAt,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
    this.ratePerKm,
    this.ratePerHour,
    this.fixedDailyRate,
    this.amountEarned,
    this.distanceCovered,
    this.hoursActive,
    // New display fields
    this.centerLatitudeCamelCase,
    this.centerLongitudeCamelCase,
    this.radius,
    this.displayColor,
    this.displayAlpha,
    this.isHighPriority,
    this.name,
    this.budget,
    this.spent,
    this.remainingBudget,
    this.maxRiders,
    this.currentRiders,
    this.isActiveFromBackend,
  });

  factory GeofenceAssignment.fromJson(Map<String, dynamic> json) => _$GeofenceAssignmentFromJson(json);
  Map<String, dynamic> toJson() => _$GeofenceAssignmentToJson(this);
  
  // Helper to create a Geofence-like object for compatibility
  GeofenceData? get geofence => GeofenceData(
    id: geofenceId,
    name: geofenceName,
    rateType: _determineRateType(),
    ratePerKm: ratePerKm,
    ratePerHour: ratePerHour,
    fixedDailyRate: fixedDailyRate,
  );
  
  String _determineRateType() {
    if (ratePerHour != null && ratePerHour! > 0) {
      if (ratePerKm != null && ratePerKm! > 0) {
        return 'hybrid';
      }
      return 'per_hour';
    } else if (ratePerKm != null && ratePerKm! > 0) {
      return 'per_km';
    } else if (fixedDailyRate != null && fixedDailyRate! > 0) {
      return 'fixed_daily';
    }
    return 'per_km';  // fallback
  }

  GeofenceAssignment copyWith({
    String? id,
    String? geofenceId,
    String? geofenceName,
    GeofenceAssignmentStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    double? centerLatitude,
    double? centerLongitude,
    int? radiusMeters,
    double? ratePerKm,
    double? ratePerHour,
    double? fixedDailyRate,
    double? amountEarned,
    double? distanceCovered,
    double? hoursActive,
    double? centerLatitudeCamelCase,
    double? centerLongitudeCamelCase,
    int? radius,
    int? displayColor,
    double? displayAlpha,
    bool? isHighPriority,
    String? name,
    double? budget,
    double? spent,
    double? remainingBudget,
    int? maxRiders,
    int? currentRiders,
    bool? isActiveFromBackend,
  }) {
    return GeofenceAssignment(
      id: id ?? this.id,
      geofenceId: geofenceId ?? this.geofenceId,
      geofenceName: geofenceName ?? this.geofenceName,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      ratePerKm: ratePerKm ?? this.ratePerKm,
      ratePerHour: ratePerHour ?? this.ratePerHour,
      fixedDailyRate: fixedDailyRate ?? this.fixedDailyRate,
      amountEarned: amountEarned ?? this.amountEarned,
      distanceCovered: distanceCovered ?? this.distanceCovered,
      hoursActive: hoursActive ?? this.hoursActive,
      centerLatitudeCamelCase: centerLatitudeCamelCase ?? this.centerLatitudeCamelCase,
      centerLongitudeCamelCase: centerLongitudeCamelCase ?? this.centerLongitudeCamelCase,
      radius: radius ?? this.radius,
      displayColor: displayColor ?? this.displayColor,
      displayAlpha: displayAlpha ?? this.displayAlpha,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      name: name ?? this.name,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      remainingBudget: remainingBudget ?? this.remainingBudget,
      maxRiders: maxRiders ?? this.maxRiders,
      currentRiders: currentRiders ?? this.currentRiders,
      isActiveFromBackend: isActiveFromBackend ?? this.isActiveFromBackend,
    );
  }

  bool get isActive => status == GeofenceAssignmentStatus.active;
  bool get isAssigned => status == GeofenceAssignmentStatus.assigned;
}

// Helper class for geofence data compatibility
class GeofenceData {
  final String? id;
  final String name;
  final String rateType;
  final double? ratePerKm;
  final double? ratePerHour;
  final double? fixedDailyRate;
  
  const GeofenceData({
    this.id,
    required this.name,
    required this.rateType,
    this.ratePerKm,
    this.ratePerHour,
    this.fixedDailyRate,
  });
}

@HiveType(typeId: 28)
@JsonSerializable()
class CampaignAssignment {
  @HiveField(0)
  final String status;
  
  @HiveField(1)
  @JsonKey(name: 'assigned_at')
  final DateTime? assignedAt;
  
  @HiveField(2)
  @JsonKey(name: 'accepted_at')
  final DateTime? acceptedAt;
  
  @HiveField(3)
  @JsonKey(name: 'verification_count')
  final int verificationCount;
  
  @HiveField(4)
  @JsonKey(name: 'compliance_score')
  final double complianceScore;
  
  @HiveField(5)
  @JsonKey(name: 'amount_earned')
  final double amountEarned;

  const CampaignAssignment({
    required this.status,
    this.assignedAt,
    this.acceptedAt,
    required this.verificationCount,
    required this.complianceScore,
    required this.amountEarned,
  });

  factory CampaignAssignment.fromJson(Map<String, dynamic> json) => _$CampaignAssignmentFromJson(json);
  Map<String, dynamic> toJson() => _$CampaignAssignmentToJson(this);
}

@HiveType(typeId: 1)
@JsonSerializable()
class Campaign {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String? name;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final String? clientName;
  
  @HiveField(4)
  final String agencyId;
  
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
  
  @HiveField(28)
  final CampaignAssignment? assignment;
  
  @HiveField(29)
  @JsonKey(name: 'active_geofences')
  final List<GeofenceAssignment> activeGeofences;

  const Campaign({
    required this.id,
    this.name,
    this.description,
    this.clientName,
    required this.agencyId,
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
    this.assignment,
    this.activeGeofences = const [],
  });

  factory Campaign.fromJson(Map<String, dynamic> json) => _$CampaignFromJson(json);
  Map<String, dynamic> toJson() => _$CampaignToJson(this);

  /// Specialized factory for my-campaigns API response
  factory Campaign.fromMyCampaignsJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      agencyId: json['agency_id'] as String? ?? '',
      agencyName: json['agency_name'] as String? ?? '',
      stickerImageUrl: json['sticker_image_url'] as String?,
      ratePerKm: _stringToDouble(json['rate_per_km']),
      ratePerHour: _stringToDouble(json['rate_per_hour']),
      fixedDailyRate: _stringToDouble(json['platform_rate']),
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      status: _parseStatus(json['status'] as String?),
      maxRiders: _stringToInt(json['max_riders']),
      currentRiders: _stringToInt(json['current_riders']),
      requirements: const CampaignRequirements(),
      estimatedWeeklyEarnings: _stringToDouble(json['estimated_weekly_earnings']),
      area: json['area'] as String?,
      targetAudiences: (json['target_audiences'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      isActive: json['is_active'] as bool? ?? false,
      totalVerifications: _stringToInt(json['total_verifications']),
      totalDistanceCovered: _stringToDouble(json['total_distance_covered']),
      budget: _stringToDouble(json['budget']),
      spent: _stringToDouble(json['spent']),
      assignment: json['assignment'] != null 
          ? CampaignAssignment.fromJson(json['assignment'] as Map<String, dynamic>)
          : null,
      activeGeofences: (json['active_geofences'] as List<dynamic>?)
          ?.map((g) => GeofenceAssignment.fromJson(g as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  static CampaignStatus _parseStatus(String? status) {
    switch (status) {
      case 'draft': return CampaignStatus.draft;
      case 'pending': return CampaignStatus.pending;
      case 'active': return CampaignStatus.running;
      case 'paused': return CampaignStatus.paused;
      case 'completed': return CampaignStatus.completed;
      case 'cancelled': return CampaignStatus.cancelled;
      default: return CampaignStatus.draft;
    }
  }

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
    CampaignAssignment? assignment,
    List<GeofenceAssignment>? activeGeofences,
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
      assignment: assignment ?? this.assignment,
      activeGeofences: activeGeofences ?? this.activeGeofences,
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
  
  // Geofence assignment getters
  bool get hasActiveGeofenceAssignments => activeGeofences.any((g) => g.isActive);
  
  List<GeofenceAssignment> get currentActiveGeofences => 
      activeGeofences.where((g) => g.isActive).toList();
  
  GeofenceAssignment? get primaryActiveGeofence => 
      currentActiveGeofences.isNotEmpty ? currentActiveGeofences.first : null;
      
  bool get isAssignedToGeofences => activeGeofences.isNotEmpty;
  
  double get totalEarnedFromGeofences => 
      activeGeofences.fold(0.0, (sum, g) => sum + (g.amountEarned ?? 0.0));
  
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
  int get hashCode => id.hashCode ?? 0;

  @override
  String toString() {
    return 'Campaign{id: $id, name: $name, status: $status, currentRiders: $currentRiders/$maxRiders}';
  }
}

@HiveType(typeId: 3)
@JsonSerializable()
class Geofence {
  @HiveField(0)
  final String id;
  
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

  // Pickup Locations fields (multiple)
  @HiveField(38)
  final List<Map<String, dynamic>>? pickupLocations;

  const Geofence({
    required this.id,
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
    
    // Pickup locations
    this.pickupLocations,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) => _$GeofenceFromJson(json);
  Map<String, dynamic> toJson() => _$GeofenceToJson(this);

  bool containsPoint(double latitude, double longitude, {double accuracyBuffer = 0.0}) {
    if (shape == GeofenceShape.circle && radius != null) {
      final distance = _distanceInMeters(centerLatitude, centerLongitude, latitude, longitude);
      final effectiveRadius = radius! + accuracyBuffer;
      return distance <= effectiveRadius;
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
  
  /// Check if this geofence has pickup locations
  bool get hasPickupLocations => pickupLocations != null && pickupLocations!.isNotEmpty;
  
  /// Get number of pickup locations
  int get pickupLocationCount => pickupLocations?.length ?? 0;
  
  /// Get all active pickup locations
  List<Map<String, dynamic>> get activePickupLocations {
    if (!hasPickupLocations) return [];
    return pickupLocations!.where((location) => location['is_active'] == true).toList();
  }
  
  /// Get primary pickup location (first active one)
  Map<String, dynamic>? get primaryPickupLocation {
    final active = activePickupLocations;
    return active.isNotEmpty ? active.first : null;
  }
  
  /// Get pickup location addresses
  List<String> get pickupAddresses {
    if (!hasPickupLocations) return [];
    return pickupLocations!
        .where((location) => location['address'] != null)
        .map((location) => location['address'] as String)
        .toList();
  }
  
  /// Get primary pickup address
  String? get primaryPickupAddress => primaryPickupLocation?['address'];
  
  /// Get primary pickup contact name
  String? get primaryPickupContactName => primaryPickupLocation?['contact_name'];
  
  /// Get primary pickup contact phone
  String? get primaryPickupContactPhone => primaryPickupLocation?['contact_phone'];
  
  /// Get primary pickup instructions
  String? get primaryPickupInstructions => primaryPickupLocation?['pickup_instructions'];
  
  /// Get primary pickup landmark
  String? get primaryPickupLandmark => primaryPickupLocation?['landmark'];
  
  /// Check if primary pickup location is active
  bool get isPrimaryPickupLocationActive => primaryPickupLocation?['is_active'] == true;
  
  /// Get today's pickup hours for primary location
  String get primaryPickupHoursToday {
    if (!hasPickupLocations) return 'No pickup locations';
    final hours = primaryPickupLocation?['today_hours'];
    return hours ?? 'Contact for hours';
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
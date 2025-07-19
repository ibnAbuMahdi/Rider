import 'dart:math';
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
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String? clientName;
  
  @HiveField(4)
  final String agencyId;
  
  @HiveField(5)
  final String agencyName;
  
  @HiveField(6)
  final String stickerImageUrl;
  
  @HiveField(7)
  final double ratePerKm;
  
  @HiveField(8)
  final double ratePerHour;
  
  @HiveField(9)
  final double fixedDailyRate;
  
  @HiveField(10)
  final DateTime startDate;
  
  @HiveField(11)
  final DateTime endDate;
  
  @HiveField(12)
  final CampaignStatus status;
  
  @HiveField(13)
  final List<Geofence> geofences;
  
  @HiveField(14)
  final int maxRiders;
  
  @HiveField(15)
  final int currentRiders;
  
  @HiveField(16)
  final CampaignRequirements requirements;
  
  @HiveField(17)
  final double estimatedWeeklyEarnings;
  
  @HiveField(18)
  final String area;
  
  @HiveField(19)
  final List<String> targetAudiences;
  
  @HiveField(20)
  final Map<String, dynamic>? metadata;
  
  @HiveField(21)
  final DateTime createdAt;
  
  @HiveField(22)
  final DateTime? updatedAt;
  
  @HiveField(23)
  final bool isActive;
  
  @HiveField(24)
  final int totalVerifications;
  
  @HiveField(25)
  final double totalDistanceCovered;
  
  @HiveField(26)
  final double budget;
  
  @HiveField(27)
  final double spent;

  const Campaign({
    required this.id,
    required this.name,
    required this.description,
    this.clientName,
    required this.agencyId,
    required this.agencyName,
    required this.stickerImageUrl,
    this.ratePerKm = 0.0,
    this.ratePerHour = 0.0,
    this.fixedDailyRate = 0.0,
    required this.startDate,
    required this.endDate,
    this.status = CampaignStatus.draft,
    this.geofences = const [],
    this.maxRiders = 100,
    this.currentRiders = 0,
    required this.requirements,
    this.estimatedWeeklyEarnings = 0.0,
    required this.area,
    this.targetAudiences = const [],
    this.metadata,
    required this.createdAt,
    this.updatedAt,
    this.isActive = false,
    this.totalVerifications = 0,
    this.totalDistanceCovered = 0.0,
    this.budget = 0.0,
    this.spent = 0.0,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) => _$CampaignFromJson(json);
  Map<String, dynamic> toJson() => _$CampaignToJson(this);

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
  bool get hasAvailableSlots => currentRiders < maxRiders;
  
  int get availableSlots => maxRiders - currentRiders;
  
  bool get isRunning => status == CampaignStatus.running && isActive;
  
  bool get canJoin {
    final now = DateTime.now();
    return hasAvailableSlots && 
           isRunning && 
           now.isAfter(startDate) && 
           now.isBefore(endDate);
  }
  
  bool get isExpired {
    final now = DateTime.now();
    return now.isAfter(endDate);
  }
  
  bool get isUpcoming {
    final now = DateTime.now();
    return now.isBefore(startDate);
  }
  
  double get progress {
    if (budget <= 0) return 0.0;
    return (spent / budget).clamp(0.0, 1.0);
  }
  
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }
  
  Duration get timeToStart {
    final now = DateTime.now();
    if (now.isAfter(startDate)) return Duration.zero;
    return startDate.difference(now);
  }
  
  double get fillPercentage {
    if (maxRiders <= 0) return 0.0;
    return (currentRiders / maxRiders * 100).clamp(0.0, 100.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Campaign && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

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
  final String name;
  
  @HiveField(2)
  final double centerLatitude;
  
  @HiveField(3)
  final double centerLongitude;
  
  @HiveField(4)
  final double radius; // in meters
  
  @HiveField(5)
  final GeofenceShape shape;
  
  @HiveField(6)
  final List<LatLng>? polygonPoints;

  const Geofence({
    required this.id,
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radius,
    this.shape = GeofenceShape.circle,
    this.polygonPoints,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) => _$GeofenceFromJson(json);
  Map<String, dynamic> toJson() => _$GeofenceToJson(this);

  bool containsPoint(double latitude, double longitude) {
    if (shape == GeofenceShape.circle) {
      return _distanceInMeters(centerLatitude, centerLongitude, latitude, longitude) <= radius;
    } else if (shape == GeofenceShape.polygon && polygonPoints != null) {
      return _pointInPolygon(LatLng(latitude, longitude), polygonPoints!);
    }
    return false;
  }

  double _distanceInMeters(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLon = (lon2 - lon1) * (pi / 180);
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    
    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].latitude;
      final yi = polygon[i].longitude;
      final xj = polygon[j].latitude;
      final yj = polygon[j].longitude;
      
      if (((yi > point.longitude) != (yj > point.longitude)) &&
          (point.latitude < (xj - xi) * (point.longitude - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }
    
    return inside;
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
class LatLng {
  @HiveField(0)
  final double latitude;
  
  @HiveField(1)
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  factory LatLng.fromJson(Map<String, dynamic> json) => _$LatLngFromJson(json);
  Map<String, dynamic> toJson() => _$LatLngToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

@HiveType(typeId: 6)
@JsonSerializable()
class CampaignRequirements {
  @HiveField(0)
  final int minRating;
  
  @HiveField(1)
  final int minCompletedCampaigns;
  
  @HiveField(2)
  final bool requiresVerification;
  
  @HiveField(3)
  final List<String> requiredDocuments;
  
  @HiveField(4)
  final int minAge;
  
  @HiveField(5)
  final bool requiresSmartphone;
  
  @HiveField(6)
  final List<String> allowedVehicleTypes;

  const CampaignRequirements({
    this.minRating = 0,
    this.minCompletedCampaigns = 0,
    this.requiresVerification = true,
    this.requiredDocuments = const [],
    this.minAge = 18,
    this.requiresSmartphone = true,
    this.allowedVehicleTypes = const ['tricycle'],
  });

  factory CampaignRequirements.fromJson(Map<String, dynamic> json) => 
      _$CampaignRequirementsFromJson(json);
  Map<String, dynamic> toJson() => _$CampaignRequirementsToJson(this);
}
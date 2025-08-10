import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'verification_request.g.dart';

@HiveType(typeId: 7)
@JsonSerializable()
class VerificationRequest {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String riderId;
  
  @HiveField(2)
  final String campaignId;
  
  @HiveField(3)
  final String? campaignName;
  
  @HiveField(4)
  final String? imageUrl;
  
  @HiveField(5)
  final String? localImagePath;
  
  @HiveField(6)
  final Map<String, dynamic>? imageMetadata;
  
  @HiveField(7)
  final double latitude;
  
  @HiveField(8)
  final double longitude;
  
  @HiveField(9)
  final double accuracy;
  
  @HiveField(10)
  final DateTime timestamp;
  
  @HiveField(11)
  final DateTime deadline;
  
  @HiveField(12)
  final VerificationStatus status;
  
  @HiveField(13)
  final double? confidenceScore;
  
  @HiveField(14)
  final Map<String, dynamic>? aiAnalysis;
  
  @HiveField(15)
  final DateTime createdAt;
  
  @HiveField(16)
  final DateTime? processedAt;
  
  @HiveField(17)
  final String? failureReason;
  
  @HiveField(18)
  final bool isManualReview;
  
  @HiveField(19)
  final bool isSynced;
  
  @HiveField(20)
  final int retryCount;

  const VerificationRequest({
    required this.id,
    required this.riderId,
    required this.campaignId,
    this.campaignName,
    this.imageUrl,
    this.localImagePath,
    this.imageMetadata,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.deadline,
    this.status = VerificationStatus.pending,
    this.confidenceScore,
    this.aiAnalysis,
    required this.createdAt,
    this.processedAt,
    this.failureReason,
    this.isManualReview = false,
    this.isSynced = false,
    this.retryCount = 0,
  });

  factory VerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$VerificationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$VerificationRequestToJson(this);

  VerificationRequest copyWith({
    String? id,
    String? riderId,
    String? campaignId,
    String? campaignName,
    String? imageUrl,
    String? localImagePath,
    Map<String, dynamic>? imageMetadata,
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
    DateTime? deadline,
    VerificationStatus? status,
    double? confidenceScore,
    Map<String, dynamic>? aiAnalysis,
    DateTime? createdAt,
    DateTime? processedAt,
    String? failureReason,
    bool? isManualReview,
    bool? isSynced,
    int? retryCount,
  }) {
    return VerificationRequest(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      campaignId: campaignId ?? this.campaignId,
      campaignName: campaignName ?? this.campaignName,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      imageMetadata: imageMetadata ?? this.imageMetadata,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      failureReason: failureReason ?? this.failureReason,
      isManualReview: isManualReview ?? this.isManualReview,
      isSynced: isSynced ?? this.isSynced,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  // Getters
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(deadline)) return Duration.zero;
    return deadline.difference(now);
  }

  bool get isExpired => DateTime.now().isAfter(deadline);

  bool get isPending => status == VerificationStatus.pending;
  
  bool get isProcessing => status == VerificationStatus.processing;
  
  bool get isPassed => status == VerificationStatus.passed;
  
  bool get isFailed => status == VerificationStatus.failed;

  bool get needsRetry => isFailed && retryCount < 3 && !isExpired;

  bool get hasImage => imageUrl != null || localImagePath != null;

  // Helper getters for timeout and remaining time calculations
  int get timeoutInMinutes {
    final timeoutDuration = deadline.difference(createdAt);
    return timeoutDuration.inMinutes;
  }
  
  int get remainingTimeInMinutes {
    final remaining = timeRemaining;
    return remaining.inMinutes;
  }

  String get statusDisplayText {
    switch (status) {
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.processing:
        return 'Processing...';
      case VerificationStatus.passed:
        return 'Passed ✓';
      case VerificationStatus.failed:
        return 'Failed ✗';
      case VerificationStatus.manualReview:
        return 'Under Review';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificationRequest &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VerificationRequest{id: $id, campaignId: $campaignId, status: $status}';
  }
}

@HiveType(typeId: 8)
enum VerificationStatus {
  @HiveField(0)
  pending,
  
  @HiveField(1)
  processing,
  
  @HiveField(2)
  passed,
  
  @HiveField(3)
  failed,
  
  @HiveField(4)
  manualReview;
}
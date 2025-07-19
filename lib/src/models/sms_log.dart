import 'package:hive/hive.dart';

part 'sms_log.g.dart';

@HiveType(typeId: 10)
class SMSLog extends HiveObject {
  @HiveField(0)
  final String phone;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final String data;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  bool synced;

  SMSLog({
    required this.phone,
    required this.type,
    required this.data,
    required this.timestamp,
    this.synced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced,
    };
  }

  factory SMSLog.fromJson(Map<String, dynamic> json) {
    return SMSLog(
      phone: json['phone'],
      type: json['type'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      synced: json['synced'] ?? false,
    );
  }
}
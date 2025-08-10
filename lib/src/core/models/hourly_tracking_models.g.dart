// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hourly_tracking_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HourlyTrackingWindowAdapter extends TypeAdapter<HourlyTrackingWindow> {
  @override
  final int typeId = 15;

  @override
  HourlyTrackingWindow read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HourlyTrackingWindow(
      id: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime,
      geofenceId: fields[3] as String,
      campaignId: fields[4] as String,
      samples: (fields[5] as List).cast<LocationSample>(),
      status: fields[6] as WindowStatus,
      failureEvents: (fields[7] as List).cast<FailureEvent>(),
    );
  }

  @override
  void write(BinaryWriter writer, HourlyTrackingWindow obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.geofenceId)
      ..writeByte(4)
      ..write(obj.campaignId)
      ..writeByte(5)
      ..write(obj.samples)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.failureEvents);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HourlyTrackingWindowAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocationSampleAdapter extends TypeAdapter<LocationSample> {
  @override
  final int typeId = 17;

  @override
  LocationSample read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationSample(
      id: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      accuracy: fields[3] as double,
      timestamp: fields[4] as DateTime,
      isWithinGeofence: fields[5] as bool,
      speed: fields[6] as double?,
      heading: fields[7] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, LocationSample obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.accuracy)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.isWithinGeofence)
      ..writeByte(6)
      ..write(obj.speed)
      ..writeByte(7)
      ..write(obj.heading);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationSampleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FailureEventAdapter extends TypeAdapter<FailureEvent> {
  @override
  final int typeId = 18;

  @override
  FailureEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FailureEvent(
      timestamp: fields[0] as DateTime,
      reason: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FailureEvent obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.reason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FailureEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WindowStatusAdapter extends TypeAdapter<WindowStatus> {
  @override
  final int typeId = 16;

  @override
  WindowStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WindowStatus.active;
      case 1:
        return WindowStatus.completed;
      case 2:
        return WindowStatus.invalid;
      case 3:
        return WindowStatus.offline;
      case 4:
        return WindowStatus.processed;
      default:
        return WindowStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, WindowStatus obj) {
    switch (obj) {
      case WindowStatus.active:
        writer.writeByte(0);
        break;
      case WindowStatus.completed:
        writer.writeByte(1);
        break;
      case WindowStatus.invalid:
        writer.writeByte(2);
        break;
      case WindowStatus.offline:
        writer.writeByte(3);
        break;
      case WindowStatus.processed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WindowStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HourlyTrackingWindow _$HourlyTrackingWindowFromJson(
        Map<String, dynamic> json) =>
    HourlyTrackingWindow(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      geofenceId: json['geofenceId'] as String,
      campaignId: json['campaignId'] as String,
      samples: (json['samples'] as List<dynamic>)
          .map((e) => LocationSample.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: $enumDecode(_$WindowStatusEnumMap, json['status']),
      failureEvents: (json['failureEvents'] as List<dynamic>)
          .map((e) => FailureEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HourlyTrackingWindowToJson(
        HourlyTrackingWindow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'geofenceId': instance.geofenceId,
      'campaignId': instance.campaignId,
      'samples': instance.samples,
      'status': _$WindowStatusEnumMap[instance.status]!,
      'failureEvents': instance.failureEvents,
    };

const _$WindowStatusEnumMap = {
  WindowStatus.active: 'active',
  WindowStatus.completed: 'completed',
  WindowStatus.invalid: 'invalid',
  WindowStatus.offline: 'offline',
  WindowStatus.processed: 'processed',
};

LocationSample _$LocationSampleFromJson(Map<String, dynamic> json) =>
    LocationSample(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isWithinGeofence: json['isWithinGeofence'] as bool,
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$LocationSampleToJson(LocationSample instance) =>
    <String, dynamic>{
      'id': instance.id,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'accuracy': instance.accuracy,
      'timestamp': instance.timestamp.toIso8601String(),
      'isWithinGeofence': instance.isWithinGeofence,
      'speed': instance.speed,
      'heading': instance.heading,
    };

FailureEvent _$FailureEventFromJson(Map<String, dynamic> json) => FailureEvent(
      timestamp: DateTime.parse(json['timestamp'] as String),
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$FailureEventToJson(FailureEvent instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'reason': instance.reason,
    };

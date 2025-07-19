// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SMSLogAdapter extends TypeAdapter<SMSLog> {
  @override
  final int typeId = 10;

  @override
  SMSLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SMSLog(
      phone: fields[0] as String,
      type: fields[1] as String,
      data: fields[2] as String,
      timestamp: fields[3] as DateTime,
      synced: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SMSLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.phone)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.data)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SMSLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

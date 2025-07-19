// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earning.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EarningAdapter extends TypeAdapter<Earning> {
  @override
  final int typeId = 6;

  @override
  Earning read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Earning(
      id: fields[0] as String,
      riderId: fields[1] as String,
      campaignId: fields[2] as String,
      campaignTitle: fields[3] as String,
      amount: fields[4] as double,
      currency: fields[5] as String,
      earningType: fields[6] as String,
      periodStart: fields[7] as DateTime,
      periodEnd: fields[8] as DateTime,
      status: fields[9] as String,
      metadata: (fields[10] as Map).cast<String, dynamic>(),
      createdAt: fields[11] as DateTime,
      paidAt: fields[12] as DateTime?,
      paymentMethod: fields[13] as String?,
      paymentReference: fields[14] as String?,
      notes: fields[15] as String?,
      hoursWorked: fields[16] as double?,
      verificationsCompleted: fields[17] as int?,
      distanceCovered: fields[18] as double?,
      isSynced: fields[19] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Earning obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.riderId)
      ..writeByte(2)
      ..write(obj.campaignId)
      ..writeByte(3)
      ..write(obj.campaignTitle)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.earningType)
      ..writeByte(7)
      ..write(obj.periodStart)
      ..writeByte(8)
      ..write(obj.periodEnd)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.metadata)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.paidAt)
      ..writeByte(13)
      ..write(obj.paymentMethod)
      ..writeByte(14)
      ..write(obj.paymentReference)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(16)
      ..write(obj.hoursWorked)
      ..writeByte(17)
      ..write(obj.verificationsCompleted)
      ..writeByte(18)
      ..write(obj.distanceCovered)
      ..writeByte(19)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarningAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

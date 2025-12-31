// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_snapshot_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailySnapshotModelAdapter extends TypeAdapter<DailySnapshotModel> {
  @override
  final int typeId = 2;

  @override
  DailySnapshotModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailySnapshotModel(
      date: fields[0] as String,
      completedHabits: fields[1] as int,
      totalHabits: fields[2] as int,
      flameLevel: fields[3] as double,
      totalStreak: fields[4] as int,
      snapshotTime: fields[5] as DateTime,
      habitStreaks: (fields[6] as Map?)?.cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, DailySnapshotModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.completedHabits)
      ..writeByte(2)
      ..write(obj.totalHabits)
      ..writeByte(3)
      ..write(obj.flameLevel)
      ..writeByte(4)
      ..write(obj.totalStreak)
      ..writeByte(5)
      ..write(obj.snapshotTime)
      ..writeByte(6)
      ..write(obj.habitStreaks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySnapshotModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

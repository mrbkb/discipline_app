// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 1;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      firebaseUid: fields[0] as String?,
      nickname: fields[1] as String,
      isHardMode: fields[2] as bool,
      reminderTime: fields[3] as String,
      lateReminderTime: fields[4] as String,
      notificationsEnabled: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      hasBackedUp: fields[7] as bool,
      lastSyncAt: fields[8] as DateTime?,
      email: fields[9] as String?,
      onboardingCompleted: fields[10] as bool,
      isAnonymous: fields[11] as bool,
      totalHabitsCreated: fields[12] as int,
      totalDaysActive: fields[13] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.firebaseUid)
      ..writeByte(1)
      ..write(obj.nickname)
      ..writeByte(2)
      ..write(obj.isHardMode)
      ..writeByte(3)
      ..write(obj.reminderTime)
      ..writeByte(4)
      ..write(obj.lateReminderTime)
      ..writeByte(5)
      ..write(obj.notificationsEnabled)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.hasBackedUp)
      ..writeByte(8)
      ..write(obj.lastSyncAt)
      ..writeByte(9)
      ..write(obj.email)
      ..writeByte(10)
      ..write(obj.onboardingCompleted)
      ..writeByte(11)
      ..write(obj.isAnonymous)
      ..writeByte(12)
      ..write(obj.totalHabitsCreated)
      ..writeByte(13)
      ..write(obj.totalDaysActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

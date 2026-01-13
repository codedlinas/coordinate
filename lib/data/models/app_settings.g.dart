// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    // NOTE: Null-safe reads for backward compatibility with old Hive data.
    // When adding new fields, always use (fields[N] as Type?) ?? defaultValue
    return AppSettings(
      accuracy: fields[0] as LocationAccuracy? ?? LocationAccuracy.medium,
      notificationsEnabled: (fields[1] as bool?) ?? true,
      countryChangeNotifications: (fields[2] as bool?) ?? true,
      weeklyDigestNotifications: (fields[3] as bool?) ?? false,
      trackingIntervalMinutes: (fields[4] as int?) ?? 15,
      trackingEnabled: (fields[5] as bool?) ?? false,
      lastTrackingTime: fields[6] as DateTime?,
      travelRemindersEnabled: (fields[7] as bool?) ?? false,
      travelReminderHour: (fields[8] as int?) ?? 8,
      travelReminderMinute: (fields[9] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.accuracy)
      ..writeByte(1)
      ..write(obj.notificationsEnabled)
      ..writeByte(2)
      ..write(obj.countryChangeNotifications)
      ..writeByte(3)
      ..write(obj.weeklyDigestNotifications)
      ..writeByte(4)
      ..write(obj.trackingIntervalMinutes)
      ..writeByte(5)
      ..write(obj.trackingEnabled)
      ..writeByte(6)
      ..write(obj.lastTrackingTime)
      ..writeByte(7)
      ..write(obj.travelRemindersEnabled)
      ..writeByte(8)
      ..write(obj.travelReminderHour)
      ..writeByte(9)
      ..write(obj.travelReminderMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocationAccuracyAdapter extends TypeAdapter<LocationAccuracy> {
  @override
  final int typeId = 1;

  @override
  LocationAccuracy read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LocationAccuracy.low;
      case 1:
        return LocationAccuracy.medium;
      case 2:
        return LocationAccuracy.high;
      default:
        return LocationAccuracy.low;
    }
  }

  @override
  void write(BinaryWriter writer, LocationAccuracy obj) {
    switch (obj) {
      case LocationAccuracy.low:
        writer.writeByte(0);
        break;
      case LocationAccuracy.medium:
        writer.writeByte(1);
        break;
      case LocationAccuracy.high:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationAccuracyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

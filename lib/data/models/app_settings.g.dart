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
    return AppSettings(
      accuracy: fields[0] as LocationAccuracy,
      notificationsEnabled: fields[1] as bool,
      countryChangeNotifications: fields[2] as bool,
      weeklyDigestNotifications: fields[3] as bool,
      trackingIntervalMinutes: fields[4] as int,
      trackingEnabled: fields[5] as bool,
      lastTrackingTime: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.lastTrackingTime);
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





// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_visit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CountryVisitAdapter extends TypeAdapter<CountryVisit> {
  @override
  final int typeId = 0;

  @override
  CountryVisit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CountryVisit(
      id: fields[0] as String,
      countryCode: fields[1] as String,
      countryName: fields[2] as String,
      entryTime: fields[3] as DateTime,
      exitTime: fields[4] as DateTime?,
      entryLatitude: fields[5] as double,
      entryLongitude: fields[6] as double,
      city: fields[7] as String?,
      region: fields[8] as String?,
      syncId: fields[9] as String?,
      updatedAt: fields[10] as DateTime?,
      deviceId: fields[11] as String?,
      isManualEdit: fields[12] == null ? false : fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CountryVisit obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.countryCode)
      ..writeByte(2)
      ..write(obj.countryName)
      ..writeByte(3)
      ..write(obj.entryTime)
      ..writeByte(4)
      ..write(obj.exitTime)
      ..writeByte(5)
      ..write(obj.entryLatitude)
      ..writeByte(6)
      ..write(obj.entryLongitude)
      ..writeByte(7)
      ..write(obj.city)
      ..writeByte(8)
      ..write(obj.region)
      ..writeByte(9)
      ..write(obj.syncId)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.deviceId)
      ..writeByte(12)
      ..write(obj.isManualEdit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryVisitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}





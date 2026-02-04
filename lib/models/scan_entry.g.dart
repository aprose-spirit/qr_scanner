// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanEntryAdapter extends TypeAdapter<ScanEntry> {
  @override
  final int typeId = 1;

  @override
  ScanEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanEntry(
      timestampIso: fields[0] as String,
      raw: fields[1] as String,
      name: fields[2] as String?,
      id: fields[3] as String?,
      position: fields[4] as String?,
      company: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScanEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.timestampIso)
      ..writeByte(1)
      ..write(obj.raw)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.id)
      ..writeByte(4)
      ..write(obj.position)
      ..writeByte(5)
      ..write(obj.company);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

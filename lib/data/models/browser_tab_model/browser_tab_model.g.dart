// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browser_tab_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BrowserTabModelAdapter extends TypeAdapter<BrowserTabModel> {
  @override
  final int typeId = 0;

  @override
  BrowserTabModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BrowserTabModel(
      id: fields[0] as String,
      url: fields[1] as String,
      title: fields[2] as String,
      createdAt: fields[3] as DateTime,
      faviconUrl: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BrowserTabModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.faviconUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrowserTabModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

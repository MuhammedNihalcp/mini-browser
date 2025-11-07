// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_summary_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PageSummaryModelAdapter extends TypeAdapter<PageSummaryModel> {
  @override
  final int typeId = 1;

  @override
  PageSummaryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PageSummaryModel(
      url: fields[0] as String,
      summary: fields[1] as String,
      cachedAt: fields[2] as DateTime,
      language: fields[3] as String?,
      keywords: (fields[4] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PageSummaryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.summary)
      ..writeByte(2)
      ..write(obj.cachedAt)
      ..writeByte(3)
      ..write(obj.language)
      ..writeByte(4)
      ..write(obj.keywords);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageSummaryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

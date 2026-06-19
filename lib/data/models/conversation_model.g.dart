part of 'conversation_model.dart';

class ConversationModelAdapter extends TypeAdapter<ConversationModel> {
  @override
  final int typeId = 0;

  @override
  ConversationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationModel(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
      messageCount: fields[4] as int,
      lastMessagePreview: fields[5] as String?,
      isPinned: fields[6] as bool?,
      isUnread: fields[7] as bool?,
      tags: fields[8] != null ? (fields[8] as List?)?.cast<String>() : null,
    );
  }

  @override
  void write(BinaryWriter writer, ConversationModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.messageCount)
      ..writeByte(5)
      ..write(obj.lastMessagePreview)
      ..writeByte(6)
      ..write(obj.isPinned)
      ..writeByte(7)
      ..write(obj.isUnread)
      ..writeByte(8)
      ..write(obj.tags);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

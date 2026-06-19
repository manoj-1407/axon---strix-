part of 'message_model.dart';

class MessageModelAdapter extends TypeAdapter<MessageModel> {
  @override
  final int typeId = 1;

  @override
  MessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageModel(
      id: fields[0] as String,
      conversationId: fields[1] as String,
      role: fields[2] as String,
      content: fields[3] as String,
      timestamp: fields[4] as DateTime,
      status: fields[5] as String,
      errorMessage: fields[6] as String?,
      tokenCount: fields[7] as int?,
      attachmentPaths: fields[8] != null ? (fields[8] as List?)?.cast<String>() : null,
      isEdited: fields[9] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.conversationId)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.errorMessage)
      ..writeByte(7)
      ..write(obj.tokenCount)
      ..writeByte(8)
      ..write(obj.attachmentPaths)
      ..writeByte(9)
      ..write(obj.isEdited);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

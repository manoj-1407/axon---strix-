part of 'ai_provider_model.dart';

class AiProviderModelAdapter extends TypeAdapter<AiProviderModel> {
  @override
  final int typeId = 2;

  @override
  AiProviderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AiProviderModel(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      baseUrl: fields[3] as String,
      apiKey: fields[4] as String,
      model: fields[5] as String,
      isActive: fields[6] as bool,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AiProviderModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.baseUrl)
      ..writeByte(4)
      ..write(obj.apiKey)
      ..writeByte(5)
      ..write(obj.model)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiProviderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venda.dart';

class VendaAdapter extends TypeAdapter<Venda> {
  @override
  final int typeId = 1;

  @override
  Venda read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Venda(
      produtoNome: fields[0] as String,
      categoria: fields[1] as String,
      precoCompra: fields[2] as double,
      precoVenda: fields[3] as double,
      quantidade: fields[4] as int,
      data: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Venda obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.produtoNome)
      ..writeByte(1)
      ..write(obj.categoria)
      ..writeByte(2)
      ..write(obj.precoCompra)
      ..writeByte(3)
      ..write(obj.precoVenda)
      ..writeByte(4)
      ..write(obj.quantidade)
      ..writeByte(5)
      ..write(obj.data);
  }
}

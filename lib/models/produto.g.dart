// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'produto.dart';

class ProdutoAdapter extends TypeAdapter<Produto> {
  @override
  final int typeId = 0;

  @override
  Produto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++)
        reader.readByte(): reader.read(),
    };
    return Produto(
      nome: fields[0] as String,
      categoria: fields[1] as String,
      precoCompra: fields[2] as double,
      precoVenda: fields[3] as double,
      estoque: fields[4] as int,
      vendidos: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Produto obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.nome)
      ..writeByte(1)
      ..write(obj.categoria)
      ..writeByte(2)
      ..write(obj.precoCompra)
      ..writeByte(3)
      ..write(obj.precoVenda)
      ..writeByte(4)
      ..write(obj.estoque)
      ..writeByte(5)
      ..write(obj.vendidos);
  }
}

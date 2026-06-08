import 'package:hive/hive.dart';

part 'venda.g.dart';

@HiveType(typeId: 1)
class Venda {
  @HiveField(0)
  String produtoNome;

  @HiveField(1)
  String categoria;

  @HiveField(2)
  double precoCompra;

  @HiveField(3)
  double precoVenda;

  @HiveField(4)
  int quantidade;

  @HiveField(5)
  DateTime data;

  Venda({
    required this.produtoNome,
    required this.categoria,
    required this.precoCompra,
    required this.precoVenda,
    required this.quantidade,
    required this.data,
  });

  double get receita => precoVenda * quantidade;
  double get despesa => precoCompra * quantidade;
  double get lucro => (precoVenda - precoCompra) * quantidade;
}

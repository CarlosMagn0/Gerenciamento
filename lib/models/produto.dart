import 'package:hive/hive.dart';

part 'produto.g.dart';

@HiveType(typeId: 0)
class Produto {
  @HiveField(0)
  String nome;

  @HiveField(1)
  String categoria;

  @HiveField(2)
  double precoCompra;

  @HiveField(3)
  double precoVenda;

  @HiveField(4)
  int estoque;

  @HiveField(5)
  int vendidos;

  Produto({
    required this.nome,
    required this.categoria,
    required this.precoCompra,
    required this.precoVenda,
    this.estoque = 0,
    this.vendidos = 0,
  });

  double get lucroUnitario => precoVenda - precoCompra;
  double get lucroTotal => lucroUnitario * vendidos;

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'categoria': categoria,
      'precoCompra': precoCompra,
      'precoVenda': precoVenda,
      'estoque': estoque,
      'vendidos': vendidos,
    };
  }

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      nome: json['nome'],
      categoria: json['categoria'],
      precoCompra: (json['precoCompra'] as num).toDouble(),
      precoVenda: (json['precoVenda'] as num).toDouble(),
      estoque: json['estoque'] ?? 0,
      vendidos: json['vendidos'] ?? 0,
    );
  }
}
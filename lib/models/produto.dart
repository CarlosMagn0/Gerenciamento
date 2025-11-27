class Produto {
  String nome;
  String categoria;
  double precoCompra;
  double precoVenda;
  int estoque;
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
  double get lucroTotal   => lucroUnitario * vendidos;
}

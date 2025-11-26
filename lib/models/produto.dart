class Produto {
  String nome;
  double precoCompra;
  double precoVenda;
  int estoque;
  int vendidos;

  Produto({
    required this.nome,
    required this.precoCompra,
    required this.precoVenda,
    this.estoque = 0,
    this.vendidos = 0,
  });

  double get lucroUnitario => precoVenda - precoCompra;
  double get lucroTotal => lucroUnitario * vendidos;

  // Backwards-compatible aliases (if other code used `compra`/`venda`)
  double get compra => precoCompra;
  double get venda => precoVenda;
}
